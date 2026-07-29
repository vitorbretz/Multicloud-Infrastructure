# Multicloud Infrastructure - Weather App

Infraestrutura multicloud deployando uma Weather App simultaneamente em **AWS S3** e **Azure Storage** usando **Terraform** para garantir redundância e alta disponibilidade.

## 📋 Visão Geral

Weather App estática hospedada em dois provedores cloud, demonstrando padrões de resiliência enterprise. A aplicação fornece informações meteorológicas em tempo real através de uma interface web responsiva.

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────┐
│        Terraform State Management        │
└─────────────────┬───────────────────────┘
        ┌─────────┴─────────┐
    ┌───────────┐       ┌───────────┐
    │    AWS    │       │   Azure   │
    │ us-east-1 │       │  East US  │
    └─────┬─────┘       └─────┬─────┘
          │                   │
    S3 + Website      Storage + $web
    Public Access     Static Hosting
          │                   │
        └─────────┬───────────┘
            Weather App
         (HTML/CSS/JS + Assets)
```

## 🌐 Componentes

### AWS
- **S3 Bucket**: `multicloud-weather-app-vitor-2026`
  - Static website hosting habilitado
  - Public read access para objetos
  - Lifecycle protection ativado
- **Bucket Policy**: Leitura pública + CloudFront logs

### Azure
- **Resource Group**: `rg-static-website` (East US)
- **Storage Account**: `myaccounttostorageweb` (StorageV2, LRS)
- **Static Website**: Container `$web` com index.html

### Weather App
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Features**:
  - Geolocation API para clima local
  - Busca por cidade
  - Interface com abas
  - Design responsivo (Merriweather Sans)
  - Loading indicators

## 📁 Estrutura do Projeto

```
Multicloud-Infrastructure/
├── main.tf                    # Definição de recursos AWS e Azure
├── variables.tf               # Variáveis de entrada (credenciais)
├── aws_credentials.tfvars    # Credenciais AWS (⚠️ .gitignore)
├── azure_credentials.tfvars  # Credenciais Azure (⚠️ .gitignore)
├── terraform.tfstate         # Estado atual da infraestrutura
├── terraform.tfstate.backup  # Backup anterior do estado
├── README.md                 # Este arquivo
└── website/
    ├── index.html            # Página principal
    ├── styles.css            # Estilos CSS
    ├── script.js             # Lógica JavaScript
    └── assets/
        ├── location.png      # Ícone de localização
        ├── search.png        # Ícone de busca
        └── loading.gif       # Animação de carregamento
```

---

## 🚀 Quick Start

### Pré-requisitos
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- Credenciais AWS e Azure
- Git

### 1. Clone e Configure

```bash
git clone <repository-url>
cd Multicloud-Infrastructure
```

### 2. Credenciais

Crie `aws_credentials.tfvars`:
```hcl
aws_access_key = "your-access-key"
aws_secret_key = "your-secret-key"
```

Crie `azure_credentials.tfvars`:
```hcl
azure_client_id       = "your-client-id"
azure_client_secret   = "your-client-secret"
azure_subscription_id = "your-subscription-id"
azure_tenant_id       = "your-tenant-id"
```

### 3. Deploy

```bash
# Inicializar
terraform init

# Validar
terraform validate

# Preview
terraform plan -var-file="aws_credentials.tfvars" -var-file="azure_credentials.tfvars"

# Deploy
terraform apply -var-file="aws_credentials.tfvars" -var-file="azure_credentials.tfvars"

# Destruir (cuidado!)
terraform destroy -var-file="aws_credentials.tfvars" -var-file="azure_credentials.tfvars"
```

## 🔒 Segurança

**Importante**: Adicione ao `.gitignore`:
```
aws_credentials.tfvars
azure_credentials.tfvars
terraform.tfstate*
.terraform/
```

- S3: Apenas leitura pública para objetos (`s3:GetObject`)
- Proteção contra destruição acidental ativada
- Use variáveis de ambiente ou secret managers em produção

## 🌍 URLs de Acesso

**AWS S3**: `http://multicloud-weather-app-vitor-2026.s3-website-us-east-1.amazonaws.com`  
**Azure Storage**: `https://myaccounttostorageweb.z13.web.core.windows.net/`

## 📈 Próximos Passos

- [ ] CloudFront CDN (AWS) e Azure CDN
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Monitoramento (CloudWatch + Azure Monitor)
- [ ] Domínio customizado + SSL/TLS
- [ ] Backend serverless (Lambda + Azure Functions)
- [ ] Remote state backend (S3 + DynamoDB ou Azure Storage)

## 🐛 Troubleshooting

**S3 Access Denied**: Verifique bucket policy e public access settings (`block_public_acls = false`)

**Arquivo não encontrado**: Execute terraform do diretório raiz; confirme estrutura `website/`

**Azure não acessível**: Verifique static website habilitado e arquivos no container `$web`

## 📚 Referências

- [AWS S3 Static Website](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Azure Static Website](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Autor**: Vitor | **Data**: 2026-07-22
