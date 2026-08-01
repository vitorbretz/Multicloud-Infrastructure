# Guia Técnico de Validação de Failover - Arquitetura Multicloud

## 📋 Documento de Evidência Técnica

**Projeto**: Failover Multicloud AWS → Azure  
**Arquitetura**: Route 53 DNS Failover + CloudFront + Azure Front Door  
**Objetivo**: Validação completa da arquitetura de alta disponibilidade  
**Data**: $(date '+%Y-%m-%d %H:%M:%S')  

---

## 🏗️ Arquitetura Testada

### Fluxo de Tráfego Normal (PRIMARY)
```
Usuário → Route 53 → CloudFront → S3 Bucket → Resposta HTTP 200
```

### Fluxo de Tráfego Failover (SECONDARY)
```
Usuário → Route 53 → Azure Front Door → Azure Storage → Resposta HTTP 200
```

### Configuração de DNS Failover
- **PRIMARY**: `cloud.flog.br` → CloudFront Distribution (Alias Record A)
- **SECONDARY**: `cloud.flog.br` → Azure Front Door IP (A Record)
- **Health Check Interval**: 30 segundos
- **Failure Threshold**: 3 verificações consecutivas (90 segundos)

---

## 🧪 PROCEDIMENTO DE TESTE COMPLETO

### ETAPA 1: Validação do Ambiente AWS Saudável

**Objetivo**: Comprovar que o ambiente PRIMARY está operacional antes do teste.

#### 1.1. Verificação HTTP 200
```bash
# Comando de verificação
curl -I https://cloud.flog.br

# Resultado esperado:
# HTTP/2 200
# server: AmazonS3
# x-cache: Hit from cloudfront
# x-amz-cf-pop: [POP_ID]
```

#### 1.2. Verificação DNS
```bash
# Verificar resolução DNS
dig cloud.flog.br +short

# Resultado esperado: IPs do CloudFront
# Exemplo: 99.86.18.52, 54.230.114.93, etc.
```

#### 1.3. Verificação Headers CloudFront
```bash
# Verificar origem da resposta
curl -s -I https://cloud.flog.br | grep -E "server|x-cache|x-amz-cf"

# Headers esperados:
# server: AmazonS3
# x-cache: Hit from cloudfront (ou Miss from cloudfront)
# x-amz-cf-pop: [CODIGO_POP]
# x-amz-cf-id: [REQUEST_ID]
```

#### 1.4. Verificação Health Check
```bash
# Verificar status do health check
aws route53 get-health-check-status --health-check-id [PRIMARY_HEALTH_CHECK_ID]

# Status esperado: "Success: HTTP Status Code 200, OK"
```

**✅ CRITÉRIO DE APROVAÇÃO ETAPA 1**: Todos os comandos devem retornar status saudável.

---

### ETAPA 2: Provocar Falha Real na Origem AWS

**Objetivo**: Gerar falha real que impeça CloudFront de buscar objetos do S3.

#### 2.1. Estratégia de Falha Escolhida: Alteração de S3 Bucket Policy

**Justificativa técnica**:
- ✅ **Falha real**: Bloqueia acesso do CloudFront ao S3
- ✅ **Reversível**: Pode ser desfeita facilmente
- ✅ **Não destrutiva**: Não remove dados ou recursos
- ✅ **Simula cenário real**: Problemas de permissão são comuns

**Método aplicado**:
```bash
# Alterar policy do S3 para DENY GetObject
terraform apply -target=aws_s3_bucket_policy.this -auto-approve

# Policy alterada para:
# "Effect": "Deny"
# "Action": "s3:GetObject"
# "Principal": "*"
```

**Alternativas avaliadas e rejeitadas**:
- Deletar objetos: ❌ Destrutivo
- Bloquear acesso público: ❌ Pode não afetar CloudFront
- Alterar DNS: ❌ Não testa real falha na origem

---

### ETAPA 3: Invalidação Completa do Cache CloudFront

**Objetivo**: Forçar CloudFront a buscar novos objetos do S3 (que agora está bloqueado).

```bash
# Invalidar todo o cache
aws cloudfront create-invalidation \
  --distribution-id [DISTRIBUTION_ID] \
  --paths "/*"

# Aguardar confirmação
aws cloudfront get-invalidation \
  --distribution-id [DISTRIBUTION_ID] \
  --id [INVALIDATION_ID]
```

**✅ CRITÉRIO**: Invalidação deve ter status "Completed" antes de continuar.

---

### ETAPA 4: Monitoramento Contínuo Durante Failover

**Objetivo**: Registrar evidências de toda a transição PRIMARY → SECONDARY.

#### 4.1. Script de Monitoramento Automático
```bash
#!/bin/bash
LOG_FILE="failover_evidence_$(date +%Y%m%d_%H%M%S).log"

echo "=== INICIANDO MONITORAMENTO DE FAILOVER ===" | tee -a $LOG_FILE
echo "Data/Hora: $(date)" | tee -a $LOG_FILE

# Loop de monitoramento por 10 minutos
for i in {1..20}; do
    echo "" | tee -a $LOG_FILE
    echo "--- VERIFICAÇÃO $i - $(date) ---" | tee -a $LOG_FILE
    
    # Health Check Status
    echo "Health Check PRIMARY:" | tee -a $LOG_FILE
    aws route53 get-health-check-status --health-check-id [PRIMARY_ID] \
        --query 'HealthCheckObservations[0].StatusReport.Status' \
        --output text | tee -a $LOG_FILE
    
    # DNS Resolution
    echo "DNS Resolution:" | tee -a $LOG_FILE
    dig +short cloud.flog.br | tee -a $LOG_FILE
    
    # HTTP Status
    echo "HTTP Status:" | tee -a $LOG_FILE
    curl -s -o /dev/null -w "cloud.flog.br: %{http_code}\n" https://cloud.flog.br | tee -a $LOG_FILE
    
    # Headers (identificar origem)
    echo "Response Headers:" | tee -a $LOG_FILE
    curl -s -I https://cloud.flog.br | grep -E "server|x-cache|x-azure|x-amz" | tee -a $LOG_FILE
    
    sleep 30
done
```

#### 4.2. Evidências Obrigatórias a Registrar
- **Timestamp** de cada verificação
- **Health Check Status**: Success → Failure → Success
- **DNS Resolution**: CloudFront IPs → Azure Front Door IP → CloudFront IPs
- **HTTP Status Code**: 200 → 403/502 → 200 → 200
- **Response Headers**: CloudFront → Azure Front Door → CloudFront

---

### ETAPA 5: Confirmação PRIMARY Unhealthy

**Objetivo**: Evidenciar que Route 53 detectou a falha no PRIMARY.

```bash
# Verificar status detalhado do health check
aws route53 get-health-check-status --health-check-id [PRIMARY_HEALTH_CHECK_ID]

# Resultado esperado:
# Status: "Failure: HTTP Status Code 403, Forbidden"
# CheckedTime: [TIMESTAMP_RECENTE]
```

**✅ CRITÉRIO**: Health check deve reportar "Failure" com HTTP 403 ou 502.

---

### ETAPA 6: Confirmação DNS Resolve para Azure

**Objetivo**: Comprovar que Route 53 ativou o registro SECONDARY.

```bash
# Verificar resolução DNS atual
dig cloud.flog.br +short

# Resultado esperado: IP do Azure Front Door
# Exemplo: 150.171.110.39

# Verificar com múltiplos resolvers
dig @8.8.8.8 cloud.flog.br +short
dig @1.1.1.1 cloud.flog.br +short
dig @9.9.9.9 cloud.flog.br +short
```

**✅ CRITÉRIO**: Todos os resolvers devem retornar IP do Azure Front Door.

---

### ETAPA 7: Validação Azure Front Door Operacional

**Objetivo**: Comprovar que SECONDARY responde corretamente com HTTPS válido.

#### 7.1. Verificação HTTP 200
```bash
# Testar resposta do Azure Front Door
curl -I https://cloud.flog.br

# Resultado esperado:
# HTTP/2 200
# x-azure-ref: [REQUEST_ID]
# x-fd-int-roxy-purgeid: [CACHE_ID]
```

#### 7.2. Validação Certificado SSL
```bash
# Verificar certificado SSL
echo | openssl s_client -servername cloud.flog.br -connect cloud.flog.br:443 2>/dev/null | openssl x509 -noout -dates

# Resultado esperado:
# notBefore=[DATA]
# notAfter=[DATA_FUTURA]
```

#### 7.3. Verificação Conteúdo
```bash
# Verificar se conteúdo está sendo servido corretamente
curl -s https://cloud.flog.br | head -5

# Resultado esperado: HTML válido da aplicação
```

**✅ CRITÉRIO**: HTTP 200 + SSL válido + conteúdo correto servido pelo Azure.

---

### ETAPA 8: Restauração da Origem AWS

**Objetivo**: Restaurar ambiente AWS para estado operacional.

```bash
# Restaurar S3 bucket policy original
terraform apply -target=aws_s3_bucket_policy.this -auto-approve

# Verificar restauração
curl -I https://d32ri76eiboi37.cloudfront.net

# Resultado esperado: HTTP 200
```

**✅ CRITÉRIO**: CloudFront deve voltar a responder HTTP 200.

---

### ETAPA 9: Confirmação Failback Automático

**Objetivo**: Evidenciar retorno automático para PRIMARY após restauração.

#### 9.1. Monitoramento do Failback
```bash
# Aguardar detecção de recuperação (até 90 segundos)
for i in {1..6}; do
    echo "Verificação $i - $(date)"
    
    # Health Check
    aws route53 get-health-check-status --health-check-id [PRIMARY_ID] \
        --query 'HealthCheckObservations[0].StatusReport.Status'
    
    # DNS
    dig +short cloud.flog.br
    
    # HTTP + Headers
    curl -s -I https://cloud.flog.br | grep -E "HTTP|server|x-cache|x-azure"
    
    echo "---"
    sleep 30
done
```

#### 9.2. Confirmação Final
```bash
# Verificar estado final
echo "=== ESTADO FINAL ==="
echo "Health Check PRIMARY:"
aws route53 get-health-check-status --health-check-id [PRIMARY_ID]

echo "DNS Resolution:"
dig +short cloud.flog.br

echo "HTTP Response:"
curl -I https://cloud.flog.br
```

**✅ CRITÉRIO**: DNS deve resolver para CloudFront e HTTP deve ser 200 com headers CloudFront.

---

## 📊 EVIDÊNCIAS TÉCNICAS OBRIGATÓRIAS

### Fluxo Completo a Documentar:

1. **PRIMARY** (Inicial): `cloud.flog.br` → CloudFront → HTTP 200
2. **FAILURE**: CloudFront → HTTP 403/502 (S3 bloqueado)
3. **SECONDARY** (Failover): `cloud.flog.br` → Azure Front Door → HTTP 200
4. **RECOVERY**: CloudFront → HTTP 200 (S3 restaurado)
5. **PRIMARY** (Final): `cloud.flog.br` → CloudFront → HTTP 200

### Logs de Evidência:
- Timestamps de cada transição
- Health check status changes
- DNS resolution changes
- HTTP status code progression
- Response headers identifying origin

---

## ✅ CRITÉRIOS DE APROVAÇÃO DO TESTE

### Requisitos Funcionais:
- [ ] Ambiente AWS saudável confirmado (HTTP 200)
- [ ] Falha real provocada e detectada (HTTP 403/502)
- [ ] Route53 marcou PRIMARY como Unhealthy
- [ ] DNS failover para Azure Front Door executado
- [ ] Azure responde HTTP 200 com SSL válido
- [ ] Restauração AWS executada com sucesso
- [ ] Failback automático para PRIMARY confirmado

### Requisitos de Performance:
- [ ] Detecção de falha ≤ 90 segundos
- [ ] Failover DNS ≤ 300 segundos (TTL)
- [ ] Failback automático ≤ 90 segundos

### Requisitos de Evidência:
- [ ] Log completo com timestamps
- [ ] Headers comprovando origem das respostas
- [ ] Health check status transitions registradas
- [ ] DNS resolution changes documentadas

---

## 🎯 RESULTADO ESPERADO

**SUCESSO**: Arquitetura multicloud com failover automático entre AWS CloudFront e Azure Front Door operacional, com recuperação automática e SSL funcional em ambos os ambientes.

**EVIDÊNCIAS**: Documentação completa provando transição PRIMARY → SECONDARY → PRIMARY com tempos de failover dentro dos SLAs estabelecidos.

---

## 📚 Comandos de Referência

### IDs dos Recursos (Atualizar com valores reais)
```bash
# Health Check IDs
export PRIMARY_HEALTH_CHECK="2cd5b593-e270-4b14-9839-43c0b4b6d0c3"
export SECONDARY_HEALTH_CHECK="34b4de7f-bb4e-49ca-b13c-38357bf928b1"

# Route53 Zone
export HOSTED_ZONE_ID="Z0047040XW8P8MS7S80T"

# CloudFront Distribution
export DISTRIBUTION_ID="E2TCYEUU1C9JVN"
```

### Terraform Resources
```bash
# S3 Bucket Policy
terraform apply -target=aws_s3_bucket_policy.this

# CloudFront Invalidation
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
```

**Este documento serve como evidência técnica completa da arquitetura multicloud com failover automático.**
