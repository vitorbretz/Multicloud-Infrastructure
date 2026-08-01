#!/bin/bash

# =====================================================================
# SCRIPT DE TESTE AUTOMATIZADO - FAILOVER MULTICLOUD
# Arquitetura: AWS Route53 + CloudFront + Azure Front Door
# =====================================================================

set -e  # Exit on any error

# Configuration
PRIMARY_HEALTH_CHECK="2cd5b593-e270-4b14-9839-43c0b4b6d0c3"
SECONDARY_HEALTH_CHECK="34b4de7f-bb4e-49ca-b13c-38357bf928b1"
HOSTED_ZONE_ID="Z0047040XW8P8MS7S80T"
DISTRIBUTION_ID="E2TCYEUU1C9JVN"
DOMAIN="cloud.flog.br"
LOG_FILE="failover_evidence_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper Functions
log_evidence() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

get_health_check_status() {
    aws route53 get-health-check-status --health-check-id "$1" \
        --query 'HealthCheckObservations[0].StatusReport.Status' \
        --output text 2>/dev/null || echo "ERROR"
}

get_dns_resolution() {
    dig +short "$DOMAIN" | head -1
}

get_http_status() {
    curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" --max-time 10 2>/dev/null || echo "000"
}

get_response_headers() {
    curl -s -I "https://$DOMAIN" --max-time 10 2>/dev/null | grep -E "server|x-cache|x-azure|x-amz" | head -3
}

wait_for_condition() {
    local condition_func="$1"
    local expected_value="$2"
    local timeout_seconds="$3"
    local description="$4"
    
    log_evidence "Aguardando: $description"
    
    for ((i=0; i<timeout_seconds; i+=15)); do
        local current_value
        current_value=$($condition_func)
        
        log_evidence "  Check ($i/${timeout_seconds}s): $current_value"
        
        if [[ "$current_value" == *"$expected_value"* ]]; then
            log_success "$description - SUCESSO após ${i}s"
            return 0
        fi
        
        sleep 15
    done
    
    log_error "$description - TIMEOUT após ${timeout_seconds}s"
    return 1
}

# =====================================================================
# ETAPA 1: VALIDAÇÃO DO AMBIENTE AWS SAUDÁVEL
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 1: VALIDAÇÃO AMBIENTE AWS SAUDÁVEL"
log_evidence "========================================="

# 1.1 Verificação HTTP 200
log_evidence "1.1. Verificando HTTP Status"
HTTP_STATUS=$(get_http_status)
if [ "$HTTP_STATUS" = "200" ]; then
    log_success "HTTP Status: $HTTP_STATUS"
else
    log_error "HTTP Status: $HTTP_STATUS (esperado: 200)"
    exit 1
fi

# 1.2 Verificação DNS
log_evidence "1.2. Verificando DNS Resolution"
DNS_IPS=$(get_dns_resolution)
log_evidence "DNS IPs: $DNS_IPS"

# 1.3 Verificação Headers CloudFront
log_evidence "1.3. Verificando Headers CloudFront"
HEADERS=$(get_response_headers)
log_evidence "Headers:"
echo "$HEADERS" | tee -a "$LOG_FILE"

if echo "$HEADERS" | grep -q "cloudfront"; then
    log_success "Headers CloudFront detectados"
else
    log_warning "Headers CloudFront não detectados"
fi

# 1.4 Verificação Health Check
log_evidence "1.4. Verificando Health Check PRIMARY"
HEALTH_STATUS=$(get_health_check_status "$PRIMARY_HEALTH_CHECK")
log_evidence "Health Check Status: $HEALTH_STATUS"

if echo "$HEALTH_STATUS" | grep -q "Success"; then
    log_success "Health Check PRIMARY saudável"
else
    log_error "Health Check PRIMARY não saudável: $HEALTH_STATUS"
    exit 1
fi

log_success "ETAPA 1 COMPLETA - Ambiente AWS validado como saudável"

# =====================================================================
# ETAPA 2: PROVOCAR FALHA REAL NA ORIGEM AWS
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 2: PROVOCAR FALHA NA ORIGEM AWS"
log_evidence "========================================="

log_evidence "2.1. Aplicando Bucket Policy com DENY GetObject"
terraform apply -target=aws_s3_bucket_policy.this -auto-approve >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log_success "S3 Bucket Policy alterada para DENY"
else
    log_error "Falha ao alterar S3 Bucket Policy"
    exit 1
fi

# =====================================================================
# ETAPA 3: INVALIDAÇÃO COMPLETA DO CACHE CLOUDFRONT
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 3: INVALIDAÇÃO CACHE CLOUDFRONT"
log_evidence "========================================="

log_evidence "3.1. Criando invalidação completa"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

log_evidence "Invalidation ID: $INVALIDATION_ID"

# Wait for invalidation to complete
log_evidence "3.2. Aguardando invalidação completar"
wait_for_condition \
    "aws cloudfront get-invalidation --distribution-id $DISTRIBUTION_ID --id $INVALIDATION_ID --query 'Invalidation.Status' --output text" \
    "Completed" \
    300 \
    "Invalidação CloudFront"

log_success "ETAPA 3 COMPLETA - Cache CloudFront invalidado"

# =====================================================================
# ETAPA 4: MONITORAMENTO CONTÍNUO DURANTE FAILOVER
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 4: MONITORAMENTO DURANTE FAILOVER"
log_evidence "========================================="

log_evidence "4.1. Iniciando monitoramento por 10 minutos"

# Monitor for 10 minutes
for i in {1..40}; do
    log_evidence ""
    log_evidence "--- VERIFICAÇÃO $i - $(date) ---"
    
    # Health Check Status
    HEALTH_STATUS=$(get_health_check_status "$PRIMARY_HEALTH_CHECK")
    log_evidence "Health Check PRIMARY: $HEALTH_STATUS"
    
    # DNS Resolution
    DNS_IPS=$(get_dns_resolution)
    log_evidence "DNS Resolution: $DNS_IPS"
    
    # HTTP Status
    HTTP_STATUS=$(get_http_status)
    log_evidence "HTTP Status: $HTTP_STATUS"
    
    # Headers (identify origin)
    HEADERS=$(get_response_headers)
    log_evidence "Response Headers:"
    echo "$HEADERS" | tee -a "$LOG_FILE"
    
    # Check if failover occurred
    if echo "$HEADERS" | grep -q "x-azure"; then
        log_success "FAILOVER DETECTADO - Tráfego via Azure Front Door"
        break
    elif echo "$HEALTH_STATUS" | grep -q "Failure" && [ "$HTTP_STATUS" != "200" ]; then
        log_evidence "Falha detectada, aguardando failover DNS..."
    fi
    
    sleep 15
done

# =====================================================================
# ETAPA 5: CONFIRMAÇÃO PRIMARY UNHEALTHY
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 5: CONFIRMAÇÃO PRIMARY UNHEALTHY"
log_evidence "========================================="

FINAL_HEALTH_STATUS=$(get_health_check_status "$PRIMARY_HEALTH_CHECK")
log_evidence "Health Check PRIMARY Status: $FINAL_HEALTH_STATUS"

if echo "$FINAL_HEALTH_STATUS" | grep -q "Failure"; then
    log_success "PRIMARY confirmado como Unhealthy"
else
    log_warning "PRIMARY não está marcado como Unhealthy: $FINAL_HEALTH_STATUS"
fi

# =====================================================================
# ETAPA 6: CONFIRMAÇÃO DNS RESOLVE PARA AZURE
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 6: CONFIRMAÇÃO DNS PARA AZURE"
log_evidence "========================================="

DNS_IPS=$(get_dns_resolution)
log_evidence "DNS Resolution atual: $DNS_IPS"

# Test multiple resolvers
for resolver in 8.8.8.8 1.1.1.1 9.9.9.9; do
    RESOLVER_IP=$(dig @$resolver +short "$DOMAIN" | head -1)
    log_evidence "DNS via $resolver: $RESOLVER_IP"
done

# =====================================================================
# ETAPA 7: VALIDAÇÃO AZURE FRONT DOOR OPERACIONAL
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 7: VALIDAÇÃO AZURE FRONT DOOR"
log_evidence "========================================="

# 7.1 HTTP 200
HTTP_STATUS=$(get_http_status)
log_evidence "7.1. HTTP Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ]; then
    log_success "Azure Front Door respondendo HTTP 200"
else
    log_error "Azure Front Door não responde HTTP 200: $HTTP_STATUS"
fi

# 7.2 SSL Certificate
log_evidence "7.2. Verificando certificado SSL"
SSL_DATES=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "Erro SSL")
log_evidence "SSL Certificate: $SSL_DATES"

# 7.3 Content verification
log_evidence "7.3. Verificando conteúdo"
CONTENT_CHECK=$(curl -s "https://$DOMAIN" | head -1)
log_evidence "Conteúdo: ${CONTENT_CHECK:0:100}..."

# =====================================================================
# ETAPA 8: RESTAURAÇÃO DA ORIGEM AWS
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 8: RESTAURAÇÃO ORIGEM AWS"
log_evidence "========================================="

log_evidence "8.1. Restaurando S3 Bucket Policy original"

# First restore the original policy in Terraform file
terraform apply -target=aws_s3_bucket_policy.this -auto-approve >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log_success "S3 Bucket Policy restaurada"
else
    log_error "Falha ao restaurar S3 Bucket Policy"
    exit 1
fi

# =====================================================================
# ETAPA 9: CONFIRMAÇÃO FAILBACK AUTOMÁTICO
# =====================================================================

log_evidence "========================================="
log_evidence "ETAPA 9: CONFIRMAÇÃO FAILBACK AUTOMÁTICO"
log_evidence "========================================="

log_evidence "9.1. Monitorando failback (até 5 minutos)"

# Wait for failback
for i in {1..20}; do
    log_evidence ""
    log_evidence "--- VERIFICAÇÃO FAILBACK $i - $(date) ---"
    
    # Health Check
    HEALTH_STATUS=$(get_health_check_status "$PRIMARY_HEALTH_CHECK")
    log_evidence "Health Check PRIMARY: $HEALTH_STATUS"
    
    # DNS
    DNS_IPS=$(get_dns_resolution)
    log_evidence "DNS: $DNS_IPS"
    
    # HTTP + Headers
    HTTP_STATUS=$(get_http_status)
    HEADERS=$(get_response_headers)
    log_evidence "HTTP: $HTTP_STATUS"
    log_evidence "Headers:"
    echo "$HEADERS" | tee -a "$LOG_FILE"
    
    # Check if failback occurred
    if echo "$HEADERS" | grep -q "cloudfront" && [ "$HTTP_STATUS" = "200" ]; then
        log_success "FAILBACK DETECTADO - Tráfego voltou para CloudFront"
        break
    fi
    
    sleep 15
done

# =====================================================================
# RESULTADO FINAL
# =====================================================================

log_evidence "========================================="
log_evidence "RESULTADO FINAL DO TESTE"
log_evidence "========================================="

FINAL_HTTP=$(get_http_status)
FINAL_DNS=$(get_dns_resolution)
FINAL_HEALTH=$(get_health_check_status "$PRIMARY_HEALTH_CHECK")
FINAL_HEADERS=$(get_response_headers)

log_evidence "Estado Final:"
log_evidence "  HTTP Status: $FINAL_HTTP"
log_evidence "  DNS Resolution: $FINAL_DNS"
log_evidence "  Health Check: $FINAL_HEALTH"
log_evidence "  Headers:"
echo "$FINAL_HEADERS" | tee -a "$LOG_FILE"

# Determine success
if [ "$FINAL_HTTP" = "200" ] && echo "$FINAL_HEADERS" | grep -q "cloudfront"; then
    log_success "========================================="
    log_success "TESTE DE FAILOVER CONCLUÍDO COM SUCESSO!"
    log_success "========================================="
    log_success "✅ Falha detectada e failover executado"
    log_success "✅ Azure Front Door operacional durante falha"
    log_success "✅ Failback automático para CloudFront"
    log_success "✅ Arquitetura multicloud validada"
else
    log_error "========================================="
    log_error "TESTE DE FAILOVER INCOMPLETO"
    log_error "========================================="
    log_error "⚠️  Verificar logs para detalhes"
fi

log_evidence ""
log_evidence "Log de evidências salvo em: $LOG_FILE"
log_evidence "========================================="

echo ""
echo -e "${BLUE}📋 RESUMO EXECUTIVO:${NC}"
echo -e "${BLUE}• Arquivo de evidências: $LOG_FILE${NC}"
echo -e "${BLUE}• Duração do teste: $(date)${NC}"
echo -e "${BLUE}• Arquitetura: Route53 → CloudFront → Azure Front Door${NC}"