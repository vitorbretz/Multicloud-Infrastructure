#!/bin/bash

echo "🔥 TESTE DE FAILOVER MULTICLOUD - CloudCast Weather App"
echo "================================================================"
echo ""

# Função para testar endpoint
test_endpoint() {
    local url=$1
    local name=$2
    echo -n "Testing $name: "
    response=$(curl -s -I "$url" -w "%{http_code}" -o /dev/null --max-time 10)
    if [ "$response" = "200" ]; then
        echo "✅ OK (HTTP 200)"
        return 0
    else
        echo "❌ FAILED (HTTP $response)"
        return 1
    fi
}

# Função para verificar DNS resolution
check_dns() {
    echo "🔍 DNS Resolution Check:"
    dig +short cloud.flog.br | while read ip; do
        echo "  → $ip"
    done
    echo ""
}

echo "📋 TESTE 1: Estado Inicial (Ambos Endpoints)"
echo "--------------------------------------------"
test_endpoint "http://cloudcast-weather-vitor-prod-2026.s3-website-us-east-1.amazonaws.com" "AWS S3 Direct"
test_endpoint "https://d32ri76eiboi37.cloudfront.net" "AWS CloudFront"
test_endpoint "https://multicloud-weather-app-prod-endpoint-bfbkcmbvbpd6eea7.z02.azurefd.net" "Azure Front Door"
test_endpoint "https://cloud.flog.br" "Domain (Current DNS)"
check_dns

echo ""
echo "🚫 SIMULANDO FALHA DO AWS..."
echo "--------------------------------------------"
echo "Aguardando Health Checks detectarem falha..."

# Simulação: Aguardar health checks (3 falhas × 30 segundos = ~90 segundos)
for i in {1..3}; do
    echo "Health Check tentativa $i/3..."
    sleep 30
    test_endpoint "https://cloud.flog.br" "Domain (Checking failover)"
    check_dns
done

echo ""
echo "📊 RESULTADO FINAL:"
echo "--------------------------------------------"
test_endpoint "https://cloud.flog.br" "Domain (Final State)"
check_dns

echo "🏁 Teste concluído!"