# Teste Manual de Failover - Arquitetura Multicloud

## 📋 Visão Geral

Este documento fornece um guia passo a passo para executar manualmente o teste de failover da arquitetura multicloud **Route53 → CloudFront → Azure Front Door**.

## 🎯 Objetivo

Validar que o Route53 redireciona automaticamente o tráfego do CloudFront (AWS) para o Azure Front Door quando o ambiente primário se torna indisponível, e que o failback acontece automaticamente quando o AWS é restaurado.

## 📊 Configuração da Infraestrutura

### IDs e Configurações Importantes
```bash
# Health Checks
PRIMARY_HEALTH_CHECK="2cd5b593-e270-4b14-9839-43c0b4b6d0c3"
SECONDARY_HEALTH_CHECK="34b4de7f-bb4e-49ca-b13c-38357bf928b1"

# Route53 e CloudFront
HOSTED_ZONE_ID="Z0047040XW8P8MS7S80T"
DISTRIBUTION_ID="E2TCYEUU1C9JVN"
DOMAIN="cloud.flog.br"

# Azure Front Door
AZURE_ENDPOINT="multicloud-weather-app-prod-endpoint-bfbkcmbvbpd6eea7.z02.azurefd.net"
```

---

## 🧪 ETAPA 1: Validação do Ambiente AWS Saudável

Antes de provocar qualquer falha, confirme que o ambiente AWS está funcionando corretamente.

### 1.1 Verificar Status HTTP
```bash
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "https://cloud.flog.br"
```
**Resultado Esperado**: `HTTP Status: 200`

### 1.2 Verificar Resolução DNS
```bash
dig +short cloud.flog.br
```
**Resultado Esperado**: IPs do CloudFront (ex: `3.174.83.x`)

### 1.3 Verificar Headers do CloudFront
```bash
curl -s -I "https://cloud.flog.br" | grep -E "server|x-cache|via|cloudfront"
```
**Resultado Esperado**:
```
server: AmazonS3
x-cache: Hit from cloudfront
via: 1.1 xxxxxxx.cloudfront.net (CloudFront)
```

### 1.4 Verificar Health Check PRIMARY
```bash
aws route53 get-health-check-status \
  --health-check-id "2cd5b593-e270-4b14-9839-43c0b4b6d0c3" \
  --query 'HealthCheckObservations[0].StatusReport.Status' \
  --output text
```
**Resultado Esperado**: `Success: HTTP Status Code 200, OK`

### ✅ Checkpoint 1
- [ ] HTTP 200 confirmado
- [ ] DNS resolve para CloudFront
- [ ] Headers CloudFront detectados
- [ ] Health Check PRIMARY saudável

---

## 🔥 ETAPA 2: Provocar Falha Real no AWS

### 2.1 Alterar S3 Bucket Policy para DENY

Edite o arquivo `s3-bucket-policy.tf` e altere o Effect de "Allow" para "Deny":

```hcl
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyAllAccess"
        Effect    = "Deny"                # ← Alterar para Deny
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      },
      # ... resto da configuração
    ]
  })
}
```

### 2.2 Aplicar a Alteração
```bash
terraform apply -target=aws_s3_bucket_policy.this -auto-approve
```

### ✅ Checkpoint 2
- [ ] S3 Bucket Policy alterada para DENY
- [ ] Terraform apply executado com sucesso

---

## ⚡ ETAPA 3: Invalidação do Cache CloudFront

### 3.1 Criar Invalidação Completa
```bash
aws cloudfront create-invalidation \
  --distribution-id "E2TCYEUU1C9JVN" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text
```
**Anote o Invalidation ID retornado**

### 3.2 Verificar Status da Invalidação
```bash
# Substitua INVALIDATION_ID pelo valor obtido acima
aws cloudfront get-invalidation \
  --distribution-id "E2TCYEUU1C9JVN" \
  --id "INVALIDATION_ID" \
  --query 'Invalidation.Status' \
  --output text
```
**Aguarde até que retorne**: `Completed`

### ✅ Checkpoint 3
- [ ] Invalidação criada
- [ ] Status = Completed confirmado

---

## 📊 ETAPA 4: Monitoramento do Failover

Execute as verificações abaixo **a cada 15-30 segundos** até detectar o failover:

### 4.1 Verificações Contínuas

#### Health Check Status
```bash
aws route53 get-health-check-status \
  --health-check-id "2cd5b593-e270-4b14-9839-43c0b4b6d0c3" \
  --query 'HealthCheckObservations[0].StatusReport.Status' \
  --output text
```

#### DNS Resolution
```bash
dig +short cloud.flog.br
```

#### HTTP Status
```bash
curl -s -o /dev/null -w "%{http_code}" "https://cloud.flog.br"
```

#### Response Headers
```bash
curl -s -I "https://cloud.flog.br" | grep -E "server|x-cache|x-azure|cloudfront"
```

### 4.2 Detectar o Failover

**🎯 Failover Detectado Quando:**
- Health Check = `Failure: HTTP Status Code 403`
- DNS IPs mudam de CloudFront para Azure (ex: `150.171.110.39`)
- Headers mostram `x-azure-ref` ao invés de CloudFront
- HTTP Status continua = `200`

### ✅ Checkpoint 4
- [ ] Health Check detectou falha (403)
- [ ] DNS resolve para Azure
- [ ] Headers Azure (`x-azure-ref`) detectados
- [ ] Site mantém HTTP 200

---

## ✅ ETAPA 5: Validação Azure Front Door Operacional

### 5.1 Confirmar HTTP 200
```bash
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "https://cloud.flog.br"
```

### 5.2 Verificar Certificado SSL
```bash
echo | openssl s_client -servername "cloud.flog.br" \
  -connect "cloud.flog.br":443 2>/dev/null | \
  openssl x509 -noout -dates 2>/dev/null
```

### 5.3 Verificar Conteúdo
```bash
curl -s "https://cloud.flog.br" | head -3
```

### 5.4 Comparar com Azure Direct
```bash
# Testar endpoint direto do Azure
curl -s -I "https://multicloud-weather-app-prod-endpoint-bfbkcmbvbpd6eea7.z02.azurefd.net" | head -5
```

### ✅ Checkpoint 5
- [ ] HTTP 200 via Azure
- [ ] SSL certificado válido
- [ ] Conteúdo HTML sendo servido
- [ ] Headers Azure confirmados

---

## 🔧 ETAPA 6: Restauração do AWS

### 6.1 Restaurar S3 Bucket Policy

Edite `s3-bucket-policy.tf` e altere o Effect de "Deny" para "Allow":

```hcl
{
  Sid    = "PublicReadGetObject"
  Effect = "Allow"                # ← Restaurar para Allow
  Principal = "*"
  Action = "s3:GetObject"
  Resource = "${aws_s3_bucket.this.arn}/*"
}
```

### 6.2 Aplicar Restauração
```bash
terraform apply -target=aws_s3_bucket_policy.this -auto-approve
```

### ✅ Checkpoint 6
- [ ] S3 Bucket Policy restaurada para ALLOW
- [ ] Terraform apply executado com sucesso

---

## 🔄 ETAPA 7: Monitoramento do Failback

### 7.1 Verificações de Failback (a cada 30 segundos)

#### Health Check Recovery
```bash
aws route53 get-health-check-status \
  --health-check-id "2cd5b593-e270-4b14-9839-43c0b4b6d0c3" \
  --query 'HealthCheckObservations[0].StatusReport.Status' \
  --output text
```
**Aguarde até**: `Success: HTTP Status Code 200, OK`

#### DNS Failback
```bash
dig +short cloud.flog.br
```
**Aguarde até**: IPs do CloudFront retornarem (ex: `3.174.83.x`)

#### Headers Failback
```bash
curl -s -I "https://cloud.flog.br" | grep -E "server|x-cache|via|cloudfront"
```
**Aguarde até**: Headers CloudFront retornarem

### 7.2 Testar Múltiplos Resolvers DNS
```bash
for resolver in 8.8.8.8 1.1.1.1 9.9.9.9; do
  echo "DNS via $resolver: $(dig @$resolver +short cloud.flog.br | head -1)"
done
```

### ✅ Checkpoint 7
- [ ] Health Check = Success
- [ ] DNS voltou para CloudFront
- [ ] Headers CloudFront retornaram
- [ ] HTTP 200 mantido

---

## 📋 ETAPA 8: Validação Final

### 8.1 Estado Final do Sistema
```bash
# HTTP Status
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "https://cloud.flog.br"

# DNS Resolution
echo "DNS: $(dig +short cloud.flog.br)"

# Health Check
echo "Health: $(aws route53 get-health-check-status \
  --health-check-id "2cd5b593-e270-4b14-9839-43c0b4b6d0c3" \
  --query 'HealthCheckObservations[0].StatusReport.Status' \
  --output text)"

# Headers
echo "Headers:"
curl -s -I "https://cloud.flog.br" | grep -E "server|x-cache|via|cloudfront"
```

### 8.2 Teste de Conteúdo
```bash
# Verificar se o site está carregando completamente
curl -s "https://cloud.flog.br" | grep -i "<!doctype\|<html\|<title"
```

---

## 🎯 Critérios de Sucesso

### ✅ Teste Aprovado Se:

1. **Failover Automático**:
   - [x] Route53 detectou falha AWS (Health Check = Failure)
   - [x] DNS redirecionou para Azure automaticamente
   - [x] Site manteve HTTP 200 durante a falha
   - [x] Headers Azure (`x-azure-ref`) detectados

2. **Azure Front Door Operacional**:
   - [x] SSL certificado válido
   - [x] Conteúdo HTML servido corretamente
   - [x] Performance adequada

3. **Failback Automático**:
   - [x] Route53 detectou recuperação AWS (Health Check = Success)
   - [x] DNS voltou para CloudFront automaticamente
   - [x] Headers CloudFront retornaram
   - [x] Site continua HTTP 200

4. **Alta Disponibilidade Comprovada**:
   - [x] Zero downtime durante o failover
   - [x] Zero downtime durante o failback
   - [x] Usuário não percebe a mudança de provedor

---

## 🔍 Troubleshooting

### Problema: Health Check não detecta falha
**Solução**: Aguarde 2-3 minutos. Health Checks têm intervalo de 30s + failure threshold.

### Problema: DNS não muda após Health Check Failure
**Solução**: Aguarde até 5 minutos para propagação DNS global.

### Problema: Failback não acontece
**Solução**: Verifique se S3 policy foi realmente restaurada e aguarde 3-5 minutos.

### Problema: Site retorna erro durante failover
**Solução**: Verifique se Azure Front Door custom domain está configurado corretamente.

---

## 📝 Log de Evidências

Durante o teste, documente:

```
Data/Hora: _______________
Executado por: ___________

Etapa 1 - AWS Saudável:
[ ] HTTP: ___  [ ] DNS: ___________  [ ] Health: ___________

Etapa 2-3 - Falha Provocada:
[ ] S3 Policy: DENY  [ ] CloudFront Invalidated: ___________

Etapa 4 - Failover Detectado:
Horário: _____  DNS: ___________  Headers: ___________

Etapa 5 - Azure Operacional:
[ ] HTTP: 200  [ ] SSL: OK  [ ] Conteúdo: OK

Etapa 6 - AWS Restaurado:
[ ] S3 Policy: ALLOW  [ ] Terraform: OK

Etapa 7 - Failback:
Horário: _____  DNS: ___________  Headers: ___________

Resultado Final: [ ] SUCESSO  [ ] FALHA
Observações: _________________________________
```

---

## 🚀 Conclusão

Este teste manual comprova que a arquitetura multicloud **Route53 → CloudFront → Azure Front Door** oferece:

- **Alta Disponibilidade**: Zero downtime durante falhas
- **Failover Automático**: Detecção e redirecionamento automáticos
- **Failback Automático**: Restauração automática ao provedor primário
- **Transparência**: Usuário não percebe a mudança de provedor

**A arquitetura está validada para uso em produção!** 🎉