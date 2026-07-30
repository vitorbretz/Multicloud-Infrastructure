# Multicloud Infrastructure - Weather App

Infraestrutura multicloud profissional deployando uma Weather App simultaneamente em **AWS S3** e **Azure Storage** usando **Terraform** com arquitetura de failover via Route53.

## 📋 Visão Geral

Arquitetura enterprise multicloud demonstrando padrões de resiliência, redundância e alta disponibilidade. A aplicação CloudCast Weather é servida através de:

- **Primary**: AWS S3 via CloudFront CDN
- **Failover**: Azure Storage Static Website
- **DNS**: Route53 com health checks automáticos

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────┐
│     Route53 DNS (cloud.flog.br)         │
│         Failover Routing                 │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───────────┐       ┌───────────┐
│ PRIMARY   │       │SECONDARY  │
│ AWS       │       │ Azure     │
│CloudFront │       │ Storage   │
└─────┬─────┘       └─────┬─────┘
      │                   │
  S3 Bucket        Static Website
  Health OK?       Health Backup
      │                   │
    └─────────┬───────────┘
          Weather App
       (HTML/CSS/JS + Assets)
```

## 📁 Estrutura do Projeto

```
.
├── provider.tf                    # Provider configurations (AWS + Azure)
├── versions.tf                    # Terraform and provider versions
├── variables.tf                   # Input variables with complex objects
├── terraform.tfvars              # Variable values (gitignored)
├── terraform.tfvars.example      # Example variable values
├── locals.tf                     # Local values and computed data
├── data.tf                       # Data sources
├── outputs.tf                    # Output values
│
├── s3-bucket.tf                  # AWS S3 bucket
├── s3-bucket-website.tf          # S3 website configuration
├── s3-bucket-policy.tf           # S3 bucket policies
├── s3-objects.tf                 # S3 object uploads
│
├── azure-resource-group.tf       # Azure Resource Group
├── azure-storage-account.tf      # Azure Storage Account
├── azure-storage-website.tf      # Azure static website
├── azure-storage-blobs.tf        # Azure blob uploads
│
├── route53-zone.tf               # Route53 hosted zone
├── route53-health-checks.tf      # Health check monitors
├── route53-records.tf            # DNS records with failover
│
├── website/                      # Static website files
│   ├── index.html
│   ├── styles.css
│   ├── script.js
│   └── assets/
│
└── README.md                     # This file
```

## 🚀 Quick Start

### Pré-requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- Credenciais AWS (Access Key & Secret Key)
- Credenciais Azure (Client ID, Secret, Subscription ID, Tenant ID)
- Git

### 1. Clone e Configure

```bash
git clone <repository-url>
cd Multicloud-Infrastructure
```

### 2. Configure Credenciais

Copie o arquivo de exemplo e adicione suas credenciais:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` com suas credenciais reais:

```hcl
aws_credentials = {
  access_key = "your-aws-access-key"
  secret_key = "your-aws-secret-key"
}

azure_credentials = {
  client_id       = "your-azure-client-id"
  client_secret   = "your-azure-client-secret"
  subscription_id = "your-azure-subscription-id"
  tenant_id       = "your-azure-tenant-id"
}
```

### 3. Deploy

```bash
# Inicializar Terraform
terraform init

# Validar configuração
terraform validate

# Preview das mudanças
terraform plan

# Aplicar infraestrutura
terraform apply

# Destruir (cuidado!)
terraform destroy
```

## 🌐 Componentes

### AWS Resources

| Recurso | Nome | Propósito |
|---------|------|-----------|
| S3 Bucket | `multicloud-weather-app-vitor-2026` | Static website hosting |
| S3 Website Config | - | Index/Error document routing |
| S3 Bucket Policy | - | Public read + CloudFront logs |
| S3 Objects | `index.html`, `styles.css`, `script.js`, `assets/*` | Website files |
| Route53 Zone | `cloud.flog.br` | DNS management |
| Route53 Health Check | Primary | CloudFront health monitor |
| Route53 Record | A Record | Primary failover endpoint |

### Azure Resources

| Recurso | Nome | Propósito |
|---------|------|-----------|
| Resource Group | `rg-static-website` | Resource organization |
| Storage Account | `myaccounttostorageweb` | Static website storage |
| Static Website | - | Index/Error document routing |
| Storage Blobs | `index.html`, `styles.css`, `script.js`, `assets/*` | Website files |
| Route53 Health Check | Secondary | Azure health monitor |
| Route53 Record | CNAME | Secondary failover endpoint |

## 🔧 Configuração Avançada

### Variáveis Principais

```hcl
# Project identification
project_name = "multicloud-weather-app"
environment  = "prod"
owner        = "vitor"

# AWS configuration
aws_region = "us-east-1"

aws_s3_website = {
  bucket_name = "multicloud-weather-app-vitor-2026"
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }
  cache_control = {
    html   = "public, max-age=300"
    css    = "public, max-age=3600"
    js     = "public, max-age=3600"
    assets = "public, max-age=86400"
  }
}

# DNS configuration
dns_config = {
  domain_name        = "cloud.flog.br"
  cloudfront_domain  = "d32ri76eiboi37.cloudfront.net"
  cloudfront_zone_id = "Z2FDTNDATAQYW2"
  health_checks = {
    request_interval  = 30
    failure_threshold = 3
  }
}
```

### Cache Control Strategy

| Tipo | Cache-Control | Razão |
|------|---------------|-------|
| HTML | `public, max-age=300` | 5 min - permite atualizações frequentes |
| CSS | `public, max-age=3600` | 1 hora - estilos mudam moderadamente |
| JS | `public, max-age=3600` | 1 hora - scripts mudam moderadamente |
| Assets | `public, max-age=86400` | 1 dia - imagens raramente mudam |

## 🌍 URLs de Acesso

Após deploy, acesse através de:

| Endpoint | URL | Tipo |
|----------|-----|------|
| **AWS Direct** | `http://multicloud-weather-app-vitor-2026.s3-website-us-east-1.amazonaws.com` | S3 Website |
| **AWS CloudFront** | `https://d32ri76eiboi37.cloudfront.net` | CDN |
| **Custom Domain (Primary)** | `https://cloud.flog.br` | Route53 A Record → CloudFront |
| **Azure Direct** | `https://myaccounttostorageweb.z13.web.core.windows.net` | Static Website |
| **Custom Domain (Failover)** | `https://www.cloud.flog.br` | Route53 CNAME → Azure |

## 🔒 Segurança

### Credentials Management

**⚠️ NUNCA commite credenciais!**

```gitignore
# Sempre no .gitignore
terraform.tfvars
*credentials*.tfvars
*.tfstate*
.terraform/
```

### Boas Práticas

- ✅ Use AWS Secrets Manager ou Azure Key Vault em produção
- ✅ Rotacione credenciais regularmente
- ✅ Use IAM roles ao invés de access keys quando possível
- ✅ Habilite MFA nas contas
- ✅ Implemente least privilege access

### Bucket Policies

**AWS S3:**
- Public read para objetos (`s3:GetObject`)
- CloudFront pode escrever logs
- Lifecycle protection ativado

**Azure Storage:**
- Public blob access habilitado
- CORS configurado para APIs meteorológicas
- Static website endpoint público

## 📊 Outputs

Após `terraform apply`, você pode consultar os outputs:

```bash
# Ver todos os outputs
terraform output

# Ver URL específica
terraform output aws_s3_website_endpoint

# Ver todas URLs em JSON
terraform output -json website_urls
```

### Principais Outputs

- `aws_s3_bucket_id` - ID do bucket S3
- `azure_storage_account_name` - Nome da storage account
- `route53_zone_name_servers` - Nameservers para configurar no domínio
- `website_urls` - Todas URLs de acesso

## 🔄 Failover Strategy

### Como Funciona

1. **Health Checks**: Route53 monitora AWS CloudFront e Azure Storage a cada 30s
2. **Primary Route**: Tráfego vai para CloudFront (AWS) por padrão
3. **Failure Detection**: Se 3 checks consecutivos falharem (90s), failover ativa
4. **Secondary Route**: Tráfego automaticamente roteado para Azure
5. **Recovery**: Quando AWS volta, tráfego retorna automaticamente

### Testando Failover

```bash
# Simular falha AWS (CUIDADO em produção!)
aws s3 rm s3://multicloud-weather-app-vitor-2026/index.html

# Aguardar ~2 minutos
# DNS automaticamente roteia para Azure

# Restaurar AWS
terraform apply -replace=aws_s3_object.html
```

## 🛠️ Manutenção

### Atualizando Website

```bash
# 1. Modificar arquivos em website/
vi website/index.html

# 2. Aplicar mudanças
terraform apply

# 3. Invalidar cache CloudFront
aws cloudfront create-invalidation \
  --distribution-id E2TCYEUU1C9JVN \
  --paths "/*"
```

### Verificar Estado

```bash
# Ver recursos gerenciados
terraform state list

# Ver detalhes de um recurso
terraform state show aws_s3_bucket.this

# Ver configuração atual
terraform show
```

### Troubleshooting

**Erro: S3 Access Denied**
```bash
# Verificar bucket policy
terraform state show aws_s3_bucket_policy.this

# Verificar public access block
terraform state show aws_s3_bucket_public_access_block.this
```

**Erro: Azure 404**
```bash
# Verificar static website habilitado
terraform state show azurerm_storage_account_static_website.this

# Verificar blobs no container $web
az storage blob list --account-name myaccounttostorageweb --container-name '$web'
```

**DNS não resolve**
```bash
# Verificar nameservers
terraform output route53_zone_name_servers

# Testar resolução
dig cloud.flog.br @8.8.8.8

# Verificar health checks
aws route53 get-health-check-status --health-check-id <ID>
```

## 📈 Próximos Passos

- [ ] Adicionar CloudFront distribution gerenciada via Terraform
- [ ] Implementar Azure CDN
- [ ] Adicionar CI/CD pipeline (GitHub Actions)
- [ ] Implementar monitoring e alertas
- [ ] Adicionar certificado SSL/TLS via ACM e Azure
- [ ] Implementar backend state remoto (S3 + DynamoDB)
- [ ] Adicionar módulos Terraform reutilizáveis
- [ ] Implementar testes com Terratest
- [ ] Adicionar documentação de disaster recovery

## 📚 Convenções Terraform

Este projeto segue rigorosamente as [Terraform Best Practices](https://www.terraform-best-practices.com/):

- ✅ Arquivos separados por recurso/serviço
- ✅ Nomenclatura padronizada (`service-resource-type.tf`)
- ✅ Objetos complexos para configurações relacionadas
- ✅ Use `_` em nomes de recursos, `-` em arquivos
- ✅ Outputs descritivos com padrão `{name}_{type}_{attribute}`
- ✅ Tags consistentes em todos os recursos
- ✅ Documentação inline e README completo

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma feature branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Add: nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📝 Licença

Este projeto é fornecido como exemplo educacional.

---

**Autor**: Vitor  
**Data**: 2026-07-30  
**Versão**: 2.0.0 (Refatorado com melhores práticas)
