# SkillRx Deployment Guide

## Kamal Commands

### Deployment
```bash
# Deploy to staging
KAMAL_DESTINATION=staging bin/kamal deploy

# Deploy to production
KAMAL_DESTINATION=production bin/kamal deploy
```

### Container Management
```bash
# Check container status
KAMAL_DESTINATION=staging bin/kamal app containers

# View logs
KAMAL_DESTINATION=staging bin/kamal app logs

# Execute commands in container
KAMAL_DESTINATION=staging bin/kamal app exec --reuse "command here"
```

### Environment Variables Tracking

#### 1. Docker Hub Authentication
- **Variable**: `KAMAL_REGISTRY_PASSWORD`
- **Set in**: Local environment before deployment
- **Used by**: Kamal for Docker Hub login
- **Referenced in**: 
  - `config/deploy.yml` → registry.password
  - `config/deploy.staging.yml` → registry.password
  - `.kamal/secrets.staging` → `KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD`
- **Value source**: `.dockerhubpass` file contains the password

#### 2. Database Configuration
- **Variable**: `DATABASE_URL`
- **Set in**: `.kamal/secrets.staging` as `DATABASE_URL=$STAGING_DATABASE_URL`
- **Local env var**: `STAGING_DATABASE_URL`
- **Used by**: Rails for database connection
- **Injected via**: Kamal env.secret in deploy.yml

#### 3. Rails Security
- **Variables**: 
  - `SECRET_KEY_BASE` 
  - `RAILS_MASTER_KEY`
- **Set in**: `.kamal/secrets.staging`
  - `SECRET_KEY_BASE=$STAGING_SECRET_KEY_BASE`
  - `RAILS_MASTER_KEY=$STAGING_RAILS_MASTER_KEY`
- **Local env vars**: `STAGING_SECRET_KEY_BASE`, `STAGING_RAILS_MASTER_KEY`
- **Used by**: Rails for encryption/decryption
- **Injected via**: Kamal env.secret in deploy.yml

#### 4. AWS Configuration
- **Variables**: 
  - `AWS_ACCESS_KEY_ID` (secret - different per environment)
  - `AWS_SECRET_ACCESS_KEY` (secret - different per environment)
  - `AWS_DEFAULT_REGION` (clear - us-east-1)
  - `AWS_BUCKET_NAME` (clear - different per environment)
  - `AWS_ENDPOINT_URL` (clear - empty for real AWS)
- **Set in**: env.secret for keys, env.clear for region/bucket
- **Used by**: Active Storage, S3 operations

#### 5. Azure Storage Configuration
- **Variables**:
  - `AZURE_STORAGE_ACCOUNT_NAME` (secret - different per environment)
  - `AZURE_STORAGE_ACCOUNT_KEY` (secret - different per environment)
  - `AZURE_STORAGE_SHARE_NAME` (clear - different per environment)
- **Set in**: env.secret for credentials, env.clear for share name
- **Used by**: Azure storage operations

#### 6. Development/Debug Configuration
- **Variables set in env.clear**:
  ```yaml
  LOCALSTACK_DEBUG: "0"  # Set to "1" for LocalStack debugging
  S3_SKIP_SIGNATURE_VALIDATION: "0"  # Set to "1" to skip S3 signature validation
  ```

#### 7. Application Configuration
- **Variables set in env.clear**:
  ```yaml
  RAILS_ENV: production
  SOLID_QUEUE_IN_PUMA: true
  ```

### Environment Variable Flow

```
Local Machine                    Kamal                         Docker Container
─────────────                    ─────                         ────────────────

.dockerhubpass ──┐
                 ├──> KAMAL_REGISTRY_PASSWORD ──> Docker Hub Auth
                 │
$STAGING_* vars ─┼──> .kamal/secrets.staging ──┐
                 │                              │
                 │                              ├──> env.secret ──> Container ENV
                 │                              │    - DATABASE_URL
                 │                              │    - SECRET_KEY_BASE
                 │                              │    - RAILS_MASTER_KEY
                 │                              │
config/deploy.yml────> env.clear ──────────────┴──> Container ENV
                       - RAILS_ENV                   - AWS_DEFAULT_REGION
                       - AWS_* vars                  - SOLID_QUEUE_IN_PUMA
                       - AZURE_* vars                etc.
```

### GitHub Secrets Setup

For GitHub Actions to work, you need to set these secrets in your repository:

#### Required for Both Staging & Production:
```
DOCKER_USERNAME=andremuta
DOCKER_PASSWORD=hJ9xfLCT2m2VqCe
```

#### Staging Secrets:
```
STAGING_SSH_PRIVATE_KEY=<contents of ~/.ssh/skillrx_web_staging.pem>
STAGING_DATABASE_URL=postgres://dbmasteruser:password@host:5432/skillrx_staging
STAGING_SECRET_KEY_BASE=your-staging-secret-key-base
STAGING_RAILS_MASTER_KEY=your-staging-master-key
STAGING_AWS_ACCESS_KEY_ID=test (or real AWS key)
STAGING_AWS_SECRET_ACCESS_KEY=test (or real AWS secret)
STAGING_AZURE_STORAGE_ACCOUNT_NAME=skillrx (or real Azure account)
STAGING_AZURE_STORAGE_ACCOUNT_KEY=skillrx (or real Azure key)
```

#### Production Secrets (when ready):
```
PRODUCTION_SSH_PRIVATE_KEY=<contents of ~/.ssh/skillrx_web_production.pem>
PRODUCTION_DATABASE_URL=postgres://dbmasteruser:password@host:5432/skillrx_production
PRODUCTION_SECRET_KEY_BASE=your-production-secret-key-base
PRODUCTION_RAILS_MASTER_KEY=your-production-master-key
PRODUCTION_AWS_ACCESS_KEY_ID=<real AWS access key>
PRODUCTION_AWS_SECRET_ACCESS_KEY=<real AWS secret key>
PRODUCTION_AZURE_STORAGE_ACCOUNT_NAME=<real Azure storage account>
PRODUCTION_AZURE_STORAGE_ACCOUNT_KEY=<real Azure storage key>
```

### Local Deployment Checklist
```bash
# 1. Set Docker Hub password
export KAMAL_REGISTRY_PASSWORD=$(cat .dockerhubpass)

# 2. Set staging database credentials
export STAGING_DATABASE_URL="postgres://dbmasteruser:password@host:5432/skillrx_staging"

# 3. Set Rails security keys
export STAGING_SECRET_KEY_BASE="your-secret-key-base"
export STAGING_RAILS_MASTER_KEY="your-master-key"

# 4. Deploy
KAMAL_DESTINATION=staging bin/kamal deploy
```

## Server Details

### Staging
- IP: 3.239.195.31
- SSH Key: ~/.ssh/skillrx_web_staging.pem
- URL: http://3.239.195.31/up

## Docker Hub
- Repository: andremuta/skillrx
- Public repository (no auth needed for pull)
- Tag format: GitHub SHA

## Known Issues

### Solid Queue Migrations
The app needs Solid Queue migrations to be run. Without them, you'll see:
```
PG::UndefinedTable: ERROR: relation "solid_queue_recurring_tasks" does not exist
```

## Testing Commands
```bash
# Check if Rails is responding
curl http://3.239.195.31/up

# Run linting
npm run lint

# Run type checking  
npm run typecheck
```

## Important Notes
- Always use KAMAL_DESTINATION=staging/production prefix for Kamal commands
- The app uses Rails 8 with multi-database setup (primary, cache, queue, cable)
- Database credentials are passed via environment variables, not Rails credentials
- GitHub Actions deploy on push to staging/main branches
- When SSH'ing to the server, use: ssh -o IdentitiesOnly=yes -i ~/.ssh/skillrx_web_staging.pem ubuntu@3.239.195.31
- The app successfully starts with db:prepare, Puma listens on port 3000, and Solid Queue workers start
- Kamal proxy runs on port 80 and forwards to the Rails app on port 3000

## Current Issues & Solutions

### Issue: Container exits with "host settings conflict with another service"
**Cause**: Kamal proxy configuration conflict
**Solution**: This error occurs at the end of deployment but the app actually starts successfully before this error. The Rails app responds with 200 on /up endpoint.

### Issue: Solid Queue missing tables
**Solution**: Run migrations manually first time:
```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/skillrx_web_staging.pem ubuntu@3.239.195.31 \
  'docker run --rm \
   -e RAILS_ENV=production \
   -e DATABASE_URL="$STAGING_DATABASE_URL" \
   -e SECRET_KEY_BASE="$STAGING_SECRET_KEY_BASE" \
   -e RAILS_MASTER_KEY="$STAGING_RAILS_MASTER_KEY" \
   andremuta/skillrx:latest bin/rails db:migrate'
```