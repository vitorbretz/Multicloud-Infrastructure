# Guia de Failover Route53 - Multicloud Weather App

## 📋 Visão Geral

Este documento descreve a configuração de failover automático entre AWS CloudFront (primário) e Azure Storage (secundário) para alta disponibilidade do site.

## ✅ Configuração Atual (Conforme Tutorial)

### PRIMARY (cloud.flog.br)
- **Target**: CloudFront Distribution (`d32ri76eiboi37.cloudfront.net`)
- **Health Check ID**: `2cd5b593-e270-4b14-9839-43c0b4b6d0c3`
- **Tipo**: Alias Record (A)
- **Status**: ✅ Saudável

### SECONDARY (www.cloud.flog.br)
- **Target**: Azure Storage (`myaccounttostorageweb.z13.web.core.windows.net`)
- **Health Check ID**: `34b4de7f-bb4e-49ca-b13c-38357bf928b1`
- **Tipo**: CNAME Record
- **TTL**: 300 segundos
- **Status**: ✅ Saudável

## 🔄 Como Funciona o Failover

1. **Monitoramento Contínuo**: Route53 verifica a saúde do CloudFront a cada 30 segundos
2. **Detecção de Falha**: Se 3 verificações consecutivas falharem (90 segundos), o health check muda para UNHEALTHY
3. **Ativação do Failover**: Route53 automaticamente começa a responder `www.cloud.flog.br` para requisições que falharem no PRIMARY
4. **Recuperação Automática**: Quando o CloudFront voltar, Route53 automaticamente retorna para ele

### Tempo de Failover
- **Detecção de falha**: ~90 segundos (3 checks x 30s)
- **Propagação DNS**: ~300 segundos (TTL do registro)
- **Tempo total estimado**: 2-3 minutos

## 🧪 Testando o Failover

### ⚠️ IMPORTANTE: Nota do Tutorial

**O aviso "Not Secure" ao acessar www.cloud.flog.br durante o failover é NORMAL e ESPERADO.**

**Por quê?**
- Azure Blob Storage static websites **NÃO suportam HTTPS** com domínios customizados por padrão
- O mecanismo de disaster recovery está funcionando corretamente mesmo com o aviso HTTP
- O site permanece funcional durante o failover, apesar do aviso "Not Secure"

**Para Produção:**
- Seria necessário configurar Azure CDN para habilitar HTTPS
- Isso está além do escopo deste tutorial

---

### Teste de Failover (Conforme Tutorial)

#### Passo 1: Restringir Acesso ao S3 Bucket

```bash
# Bloquear acesso público ao S3
aws s3api put-public-access-block \
  --bucket multicloud-weather-app-vitor-2026 \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### Passo 2: Invalidar Cache do CloudFront

```bash
# Limpar cache do CloudFront
aws cloudfront create-invalidation \
  --distribution-id E2TCYEUU1C9JVN \
  --paths "/*"
```

#### Passo 3: Aguardar Detecção de Falha

```
⏱️  Health checks detectam falha em ~90 segundos:
   - 3 verificações × 30 segundos = 90 segundos
   - Mais ~60 segundos para propagação DNS
   - Total: 2-3 minutos
```

#### Passo 4: Verificar Failover para Azure

```bash
# Testar PRIMARY (deve retornar 403 Forbidden)
curl -I https://cloud.flog.br/

# Verificar DNS do SECONDARY
dig www.cloud.flog.br +short
# Deve retornar: myaccounttostorageweb.z13.web.core.windows.net

# Testar SECONDARY via domínio nativo do Azure
curl -I https://myaccounttostorageweb.z13.web.core.windows.net/
# Deve retornar: 200 OK
```

#### Passo 5: Observações Durante o Failover

**✅ Comportamento Esperado:**
- `cloud.flog.br` → Retorna erro 403 (S3 bloqueado)
- `www.cloud.flog.br` → Resolve para Azure Storage
- Site funciona via domínio nativo do Azure
- **Aviso "Not Secure"**: NORMAL - Azure não suporta HTTPS com CNAME customizado

**⚠️ Limitação do Azure:**
Ao tentar acessar `https://www.cloud.flog.br/` você verá:
- Erro de certificado SSL (esperado)
- Ou aviso "Not Secure" no navegador

**Solução de Contorno:**
- Acessar via domínio nativo: `https://myaccounttostorageweb.z13.web.core.windows.net/`
- Ou aceitar o aviso de segurança (apenas para testes)

#### Passo 6: Restaurar Acesso Normal

```bash
# Restaurar acesso público ao S3
aws s3api delete-public-access-block \
  --bucket multicloud-weather-app-vitor-2026

# Aguardar 2-3 minutos para health check detectar recuperação

# Verificar PRIMARY voltou
curl -I https://cloud.flog.br/
# Deve retornar: 200 OK
```

---

### Teste Completo (Script Automatizado)

```bash
#!/bin/bash

echo "=== TESTE DE FAILOVER ==="
echo ""

# 1. Verificar estado inicial
echo "1. Estado inicial:"
curl -s -o /dev/null -w "PRIMARY (cloud.flog.br): %{http_code}\n" https://cloud.flog.br/
echo ""

# 2. Bloquear S3
echo "2. Bloqueando S3..."
aws s3api put-public-access-block \
  --bucket multicloud-weather-app-vitor-2026 \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo ""

# 3. Invalidar CloudFront
echo "3. Invalidando CloudFront..."
aws cloudfront create-invalidation --distribution-id E2TCYEUU1C9JVN --paths "/*"
echo ""

# 4. Aguardar
echo "4. Aguardando 120 segundos para failover..."
sleep 120
echo ""

# 5. Testar failover
echo "5. Testando failover:"
curl -s -o /dev/null -w "PRIMARY (cloud.flog.br): %{http_code}\n" https://cloud.flog.br/
curl -s -o /dev/null -w "SECONDARY (Azure nativo): %{http_code}\n" https://myaccounttostorageweb.z13.web.core.windows.net/
echo ""

# 6. Restaurar
echo "6. Restaurando S3..."
aws s3api delete-public-access-block --bucket multicloud-weather-app-vitor-2026
echo ""

# 7. Aguardar recuperação
echo "7. Aguardando 120 segundos para recuperação..."
sleep 120
echo ""

# 8. Verificar recuperação
echo "8. Verificando recuperação:"
curl -s -o /dev/null -w "PRIMARY (cloud.flog.br): %{http_code}\n" https://cloud.flog.br/
echo ""

echo "✅ Teste concluído!"
```

---

## 📊 Comandos de Monitoramento

### Verificar Configuração de Failover
```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id Z0047040XW8P8MS7S80T \
  --query "ResourceRecordSets[?SetIdentifier=='primary' || SetIdentifier=='secondary']"
```

### Verificar Health Checks
```bash
# Status do Primary
aws route53 get-health-check \
  --health-check-id 2cd5b593-e270-4b14-9839-43c0b4b6d0c3

# Status do Secondary
aws route53 get-health-check \
  --health-check-id 34b4de7f-bb4e-49ca-b13c-38357bf928b1
```

### Identificar Origem da Resposta
```bash
# Verificar headers da resposta do PRIMARY
curl -s -I https://cloud.flog.br/ | grep -E "Server|x-cache|x-amz"

# Se responder CloudFront, você verá:
# - server: AmazonS3
# - x-cache: Hit from cloudfront
# - x-amz-cf-pop: GRU3-P9

# Verificar SECONDARY (Azure)
curl -s -I https://myaccounttostorageweb.z13.web.core.windows.net/ | grep -E "Server|x-ms"
```

---

## ⚠️ Limitações Conhecidas

### Azure Storage + Domínio Customizado
- **HTTPS**: Azure Storage não suporta HTTPS com domínios customizados sem Azure CDN
- **Aviso "Not Secure"**: Normal e esperado durante failover para Azure
- **Recomendação**: Para produção real, considere adicionar Azure CDN para suporte HTTPS completo

### DNS Cache
- Alguns clientes podem cachear o DNS por mais tempo que o TTL configurado
- Navegadores e sistemas operacionais têm seus próprios caches de DNS
- O failover completo pode levar até 5 minutos em alguns casos

---

## 🔧 Configuração Terraform

Os arquivos relevantes são:

- `route53-records.tf` - Registros PRIMARY e SECONDARY
- `route53-health-checks.tf` - Configuração dos health checks
- `variables.tf` - Parâmetros configuráveis

### Ajustar Parâmetros de Failover

Edite em `terraform.tfvars`:

```hcl
dns_config = {
  health_checks = {
    request_interval  = 30  # Intervalo entre verificações (30 ou 10 segundos)
    failure_threshold = 3   # Número de falhas antes de considerar unhealthy
  }
}
```

---

## 📚 Referências

- [AWS Route53 Health Checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html)
- [Azure Storage Static Websites](https://learn.microsoft.com/azure/storage/blobs/storage-blob-static-website)
- [CloudFront Distributions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview.html)

---

## 🎯 Resultado Esperado

Quando funcionando corretamente:

1. **Cenário Normal**: Usuários acessam `https://cloud.flog.br` → CloudFront → S3 (AWS)
2. **Cenário de Falha**: CloudFront falha → Route53 detecta → Usuários redirecionados para `www.cloud.flog.br` (Azure)
3. **Recuperação**: CloudFront volta → Route53 detecta → Usuários voltam para `cloud.flog.br`

✅ **Failover configurado e operacional conforme tutorial!**
✅ **Teste realizado com sucesso!**
✅ **Aviso "Not Secure" no Azure é comportamento esperado**
