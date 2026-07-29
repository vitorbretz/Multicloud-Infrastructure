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
- Credenciais AWS (Access Key & Secret Key)
- Credenciais Azure (Client ID, Secret, Subscription ID, Tenant ID)
- Git

### 1. Clone o Repositório
```bash
git clone <repository-url>
cd Multicloud-Infrastructure
```

### 2. Configure as Credenciais

#### AWS Credentials (`aws_credentials.tfvars`)
```hcl
aws_access_key = "your-aws-access-key"
aws_secret_key = "your-aws-secret-key"
```

#### Azure Credentials (`azure_credentials.tfvars`)
```hcl
azure_client_id       = "your-azure-client-id"
azure_client_secret   = "your-azure-client-secret"
azure_subscription_id = "your-azure-subscription-id"
azure_tenant_id       = "your-azure-tenant-id"
```

### 3. Terraform Workflow

```bash
# Inicializa Terraform (primeiro setup)
terraform init

# Valida a configuração
terraform validate

# Plano de execução (o que será criado)
terraform plan -var-file="aws_credentials.tfvars" -var-file="azure_credentials.tfvars"

# Aplicar a infraestrutura
terraform apply -var-file="aws_credentials.tfvars" -var-file="azure_credentials.tfvars"

# Remover a infraestrutura (CUIDADO!)
terraform destroy -var-file="aws_credentials.tfvars" -var-file="azure_credentials.tfvars"
```

---

## 📊 Variáveis Terraform

| Variável | Origem | Descrição |
|----------|--------|-----------|
| `aws_access_key` | AWS Credentials | Access Key da conta AWS |
| `aws_secret_key` | AWS Credentials | Secret Key da conta AWS |
| `azure_client_id` | Azure Credentials | Client ID da aplicação Azure |
| `azure_client_secret` | Azure Credentials | Client Secret da aplicação Azure |
| `azure_subscription_id` | Azure Credentials | ID da subscription Azure |
| `azure_tenant_id` | Azure Credentials | Tenant ID do Azure AD |

---

## 🔒 Segurança

### ⚠️ Credenciais
- **Nunca** commite arquivos `*_credentials.tfvars` no repositório
- Adicione aos `.gitignore`:
  ```
  aws_credentials.tfvars
  azure_credentials.tfvars
  terraform.tfstate
  terraform.tfstate.backup
  ```
- Use variáveis de ambiente ou AWS/Azure CLI para credenciais

### Política de Acesso S3 (AWS)
- Apenas leitura pública (`s3:GetObject`)
- CloudFront pode escrever logs
- Bucket lifecycle protection ativado

---

## 🌍 URLs de Acesso

Após o deployment com sucesso:

### AWS S3 Website
```
http://multicloud-weather-app-vitor-2026.s3-website-us-east-1.amazonaws.com
```

### Azure Static Website
```
https://myaccounttostorageweb.z13.web.core.windows.net/
```

---

## 🔄 Deployment Multicloud

Esta arquitetura permite:

✅ **Redundância**: Mesma app em dois provedores  
✅ **Resiliência**: Falha de um não afeta o outro  
✅ **Escalabilidade**: Expandir em qualquer cloud  
✅ **Failover**: Mudar DNS/CDN se um falhar  
✅ **Testing**: Validar em múltiplas plataformas  

---

## 📈 Próximos Passos

- [ ] Adicionar CloudFront CDN em frente ao S3
- [ ] Implementar Azure CDN
- [ ] Adicionar CI/CD pipeline (GitHub Actions)
- [ ] Implementar monitoramento (CloudWatch + Azure Monitor)
- [ ] Adicionar domínio customizado com Route53 + Azure DNS
- [ ] Configurar SSL/TLS certificates
- [ ] Integrar API meteorológica
- [ ] Adicionar backend serverless (Lambda + Azure Functions)

---

## 📝 Logs e Estado

- **terraform.tfstate**: Estado atual gerenciado pelo Terraform
- **terraform.tfstate.backup**: Backup automático anterior
- Considere usar remote state (S3 backend para AWS ou Azure Storage para Azure)

---

## 🐛 Troubleshooting

### Erro: "Access Denied" no S3
- Verifique se a bucket policy está corretamente aplicada
- Confirme que `block_public_acls = false` e `restrict_public_buckets = false`

### Erro: Arquivo não encontrado ao upload
- Certifique-se que os arquivos estão em `website/` relativo ao diretório Terraform
- Execute Terraform do diretório raiz do projeto

### Erro: Azure Static Website not accessible
- Confirme que a storage account static website está habilitada
- Verifique se os arquivos estão no container `$web`

---

## 📚 Referências

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Azure Static Website Hosting](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## 📄 Licença

Este projeto é fornecido como exemplo educacional.

---

## 👤 Autor

Vitor - Multicloud Infrastructure Demo  
Data: 2026-07-22
