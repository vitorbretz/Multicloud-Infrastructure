# Multicloud Weather App Infrastructure

## 🏗️ Overview

This project implements a highly available, multicloud weather application using AWS and Azure with intelligent DNS failover. The architecture ensures 99.9%+ uptime by distributing the application across two major cloud providers.

## 🎯 Architecture

### Core Components

- **Primary**: AWS CloudFront + S3 static website  
- **Secondary**: Azure Front Door + Azure Storage static website
- **DNS**: Route53 with health check-based failover
- **Domain Support**: Full apex domain (`cloud.flog.br`) and www subdomain support

### Failover Logic

```
cloud.flog.br (PRIMARY) → AWS CloudFront → S3
                    ↓ (if AWS fails)
cloud.flog.br (SECONDARY) → Azure Front Door → Azure Storage
```

## 📁 Project Structure

```
.
├── terraform/                    # Infrastructure as Code
│   ├── aws/                     # AWS resources
│   │   ├── route53-zone.tf      # DNS zone
│   │   ├── route53-records.tf   # DNS records with failover
│   │   ├── route53-health-checks.tf # Health monitoring
│   │   ├── s3-bucket.tf         # S3 bucket
│   │   ├── s3-bucket-policy.tf  # S3 permissions
│   │   ├── s3-bucket-website.tf # S3 static website config
│   │   └── s3-objects.tf        # Website file uploads
│   ├── azure/                   # Azure resources
│   │   ├── azure-resource-group.tf # Resource group
│   │   ├── azure-storage-account.tf # Storage account
│   │   ├── azure-storage-website.tf # Static website config
│   │   ├── azure-storage-blobs.tf   # Website file uploads
│   │   └── azure-front-door.tf     # Front Door for apex domain support
│   └── shared/                  # Shared configuration
│       ├── provider.tf          # Provider configurations
│       ├── versions.tf          # Terraform version constraints
│       ├── variables.tf         # Input variables
│       ├── outputs.tf           # Output values
│       ├── locals.tf            # Local values
│       └── data.tf              # Data sources
├── website/                     # Static website files
│   ├── index.html              # Main page
│   ├── styles.css              # Styling
│   ├── script.js               # JavaScript
│   └── assets/                 # Images and icons
├── .kiro/                      # Development workflows
│   ├── adr-implement/          # Architecture Decision Records
│   │   └── new.aruitecture.md  # Azure Front Door implementation ADR
│   └── specs/                  # Feature specifications
│       └── apex-domain-failover/ # Apex domain failover spec
├── FAILOVER-GUIDE.md          # Operational failover guide
├── IMPLEMENTATION-SUMMARY.md  # Implementation summary
└── README.md                  # This file
```

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Azure CLI configured
- Domain registered and ready for delegation

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Configure Domain Delegation

Update your domain registrar to use the Route53 name servers:

```bash
terraform output route53_zone_name_servers
```

### 4. Verify Deployment

```bash
# Check all URLs are working
terraform output website_urls

# Test failover (advanced)
# See FAILOVER-GUIDE.md for details
```

## 🔧 Configuration

### Key Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Project identifier | `"multicloud-weather-app"` |
| `dns_config.domain_name` | Your domain | `"cloud.flog.br"` |
| `aws_credentials` | AWS access keys | See terraform.tfvars.example |
| `azure_credentials` | Azure service principal | See terraform.tfvars.example |

### Apex Domain Support

This project implements full apex domain support through:

- **AWS**: CloudFront distribution with Route53 alias records
- **Azure**: Front Door service for apex domain compatibility
- **DNS Failover**: Intelligent switching between providers

## 📊 Monitoring & Operations

### Health Checks

- **AWS Primary**: Monitors CloudFront distribution
- **Azure Secondary**: Monitors Front Door endpoint  
- **Frequency**: 30-second intervals
- **Failure Threshold**: 3 consecutive failures

### Costs (Estimated)

- **AWS**: ~$50-100/month (CloudFront + S3 + Route53)
- **Azure**: ~$30-80/month (Front Door + Storage)
- **Total**: ~$80-180/month (varies with traffic)

### Performance

- **Global CDN**: Sub-200ms response times worldwide
- **Availability**: 99.9%+ uptime with failover
- **Cache**: Optimized cache headers for static content

## 🛠️ Development

### Local Development

```bash
# Serve website locally
cd website
python -m http.server 8000
```

### Testing Changes

```bash
# Validate Terraform
terraform validate

# Plan changes
terraform plan

# Apply specific resource
terraform apply -target=resource.name
```

### Architecture Decisions

See `.kiro/adr-implement/new.aruitecture.md` for detailed architecture decisions and implementation rationale.

## 🔄 Failover Operations

Detailed failover procedures are documented in `FAILOVER-GUIDE.md`. Key points:

- **Automatic**: Health check-based switching
- **Manual**: Emergency DNS updates available  
- **Recovery**: Automatic failback when primary recovers
- **Monitoring**: Real-time health status

## 🤝 Contributing

1. Follow the existing Terraform module structure
2. Update documentation for any architecture changes
3. Test changes in a separate environment first
4. Ensure health checks remain functional

## 📈 Roadmap

- [ ] CloudFlare integration for enhanced performance
- [ ] Automated certificate management
- [ ] Enhanced monitoring and alerting
- [ ] Multi-region expansion
- [ ] Performance analytics dashboard

## 🔒 Security

- **HTTPS**: Enforced across all endpoints
- **WAF**: Basic protection on Azure Front Door
- **Access Control**: Least-privilege IAM policies
- **Secrets**: Managed through Terraform sensitive variables

## 📞 Support

For issues and questions:

1. Check `FAILOVER-GUIDE.md` for operational issues
2. Review Terraform logs for infrastructure problems  
3. Consult `.kiro/specs/` for feature documentation

---

**Architecture**: Multi-cloud, High-Availability, DNS Failover  
**Technologies**: Terraform, AWS, Azure, Route53, Front Door  
**Deployment**: Infrastructure as Code  
**Monitoring**: Health Check-based Failover