# Deployment Setup

This project uses Kamal for deployment with separate staging and production environments.

## GitHub Secrets Setup

You need to configure the following secrets in your GitHub repository:

### General Secrets
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_HUB_PASSWORD` - Your Docker Hub password/token

### Staging Secrets
- `STAGING_SSH_PRIVATE_KEY` - SSH private key for staging server (content of ~/.ssh/skillrx_web_staging.pem)
- `STAGING_DATABASE_URL` - Staging database connection string
- `STAGING_SECRET_KEY_BASE` - Rails secret key base for staging
- `STAGING_RAILS_MASTER_KEY` - Rails master key for staging credentials

### Production Secrets  
- `PRODUCTION_SSH_PRIVATE_KEY` - SSH private key for production server
- `PRODUCTION_DATABASE_URL` - Production database connection string
- `PRODUCTION_SECRET_KEY_BASE` - Rails secret key base for production
- `PRODUCTION_RAILS_MASTER_KEY` - Rails master key for production credentials

## Deployment Workflows

### Staging Deployment
- **Trigger**: Push to `develop` branch or manual trigger
- **File**: `.github/workflows/deploy-staging.yml`
- **Command**: `kamal app boot --destination staging --version <git-sha>`
- **Server**: Current staging server (3.239.195.31)

### Production Deployment
- **Trigger**: Push to `main` branch or manual trigger
- **File**: `.github/workflows/deploy-production.yml`
- **Command**: `kamal app boot --destination production --version <git-sha>`
- **Server**: Production server (update IP in config/deploy.production.yml)
- **Protection**: Requires manual approval via GitHub environment protection

## Manual Deployment

You can also deploy manually from your local machine:

```bash
# Deploy to staging
kamal app boot --destination staging --version latest

# Deploy to production  
kamal app boot --destination production --version latest
```

## Configuration Files

- `config/deploy.staging.yml` - Staging environment configuration
- `config/deploy.production.yml` - Production environment configuration
- `.kamal/secrets.staging` - Staging secrets template
- `.kamal/secrets.production` - Production secrets template

## Setup Checklist

1. ✅ Set up all GitHub secrets listed above
2. ✅ Update production server IP in `config/deploy.production.yml`
3. ✅ Update production domain in `config/deploy.production.yml`
4. ✅ Ensure production server has Docker installed
5. ✅ Test staging deployment first
6. ✅ Set up GitHub environment protection for production
7. ✅ Update SSH key paths if needed