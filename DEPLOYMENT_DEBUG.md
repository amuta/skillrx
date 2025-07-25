# Deployment Debug Log

## Current Status: 🔍 INVESTIGATING

**Last Updated**: 2025-07-25

## 🎯 What We're Trying to Achieve
Set up automated Kamal deployment to AWS Lightsail using GitHub Actions with separate staging and production environments.

## ✅ What's Working

### Kamal Configuration
- ✅ Local Kamal configuration works
- ✅ Can manually deploy to Lightsail server (3.239.195.31) using: `bin/kamal app boot --destination staging --version <sha>`
- ✅ Docker image builds and pushes to Docker Hub successfully
- ✅ Container pulls from public Docker Hub repo (andremuta/skillrx)
- ✅ SSH connection to server works with key: `~/.ssh/skillrx_web_staging.pem`
- ✅ Docker is installed on Lightsail server
- ✅ Basic Rails app container starts (but fails due to Rails config issues)

### GitHub Setup
- ✅ Repository has correct workflow files
- ✅ All required GitHub secrets are configured:
  - `DOCKER_USERNAME` & `DOCKER_PASSWORD`
  - `STAGING_DATABASE_URL`, `STAGING_SECRET_KEY_BASE`, `STAGING_RAILS_MASTER_KEY`
  - `STAGING_SSH_PRIVATE_KEY`

## ❌ What's NOT Working

### GitHub Actions Workflows
- ❌ Staging workflow (`deploy-staging.yml`) not visible in `gh workflow list`
- ❌ Workflows not triggering on push to `develop` branch
- ❌ Manual workflow trigger via CLI fails: `gh workflow run deploy-staging.yml`
- ❌ No new workflow runs appearing in `gh run list`

### Rails Application Issues
- ❌ App fails to start due to `ActiveSupport::MessageEncryptor::InvalidMessage`
- ❌ Error occurs in `/rails/config/initializers/acts_as_taggable.rb:1`
- ❌ Even with correct `RAILS_MASTER_KEY=789808daecc93cb5ee171f88c646cbbe`

## 🔍 Current Investigation

### GitHub Workflow Issues
**Problem**: Workflows exist in repository but GitHub doesn't recognize them
**Possible Causes**:
1. Workflow file syntax errors (YAML formatting)
2. GitHub needs time to process new workflow files
3. Workflow files not on correct branch (they're on main now)
4. GitHub secrets causing workflows to fail immediately

**Evidence**:
- Files exist: `.github/workflows/deploy-staging.yml` & `deploy-production.yml`
- `gh workflow list` only shows: "CI" and "Dependabot Updates"
- No runs triggered by pushes to `develop` or `main`

### Rails Application Issues
**Problem**: App starts but crashes during initialization
**Error**: `ActiveSupport::MessageEncryptor::InvalidMessage`
**Location**: `/rails/config/initializers/acts_as_taggable.rb:1`

**Evidence**:
- Container starts successfully
- All environment variables are set correctly
- Master key matches the one in repository
- Error suggests encrypted credentials can't be decrypted

## 🛠️ What We CAN Do

### Local Testing
- ✅ Run `bin/kamal app boot --destination staging --version <sha>` locally
- ✅ Build and push Docker images manually
- ✅ SSH into Lightsail server and inspect containers
- ✅ Test individual components (Docker, SSH, database connections)

### GitHub CLI Capabilities
- ✅ List and set GitHub secrets: `gh secret list/set`
- ✅ Check workflow runs: `gh run list`
- ✅ View repository info: `gh repo view`

### Debugging Commands
```bash
# Check workflow files exist
ls -la .github/workflows/

# Validate YAML syntax
cat .github/workflows/deploy-staging.yml

# Check GitHub secrets
gh secret list -R amuta/skillrx

# Check recent workflow runs
gh run list --limit 10

# Manual deployment test
bin/kamal app boot --destination staging --version latest

# Check container logs on server
ssh -i ~/.ssh/skillrx_web_staging.pem ubuntu@3.239.195.31 "docker logs skillrx-web-<version>"
```

## ❌ What We CANNOT Do

### GitHub Web Interface
- ❌ Cannot access GitHub web interface to manually trigger workflows
- ❌ Cannot see detailed workflow error messages from failed runs
- ❌ Cannot configure GitHub environments or branch protection rules
- ❌ Cannot see workflow file syntax errors in GitHub's UI

### Limited Debugging
- ❌ Cannot see GitHub's internal workflow processing logs
- ❌ Cannot directly interact with GitHub Actions runners
- ❌ Cannot see detailed Rails application logs without SSH access

## 📋 Immediate Next Steps

### Verify GitHub Workflows
1. **Check GitHub web interface**: Visit https://github.com/amuta/skillrx/actions
2. **Look for failed workflows**: Any errors or warnings?
3. **Validate YAML syntax**: Use online YAML validator
4. **Check branch**: Ensure workflows are on main branch

### Debug Rails Application
1. **SSH into server**: `ssh -i ~/.ssh/skillrx_web_staging.pem ubuntu@3.239.195.31`
2. **Check container logs**: `docker logs skillrx-web-<version> --tail 50`
3. **Inspect credentials**: Check if encrypted credentials file is accessible
4. **Test Rails console**: Try starting Rails in container interactively

### Alternative Approaches
1. **Simplify Rails config**: Remove/comment acts_as_taggable initializer temporarily
2. **Use different secrets**: Try with fresh Rails credentials
3. **Manual deployment**: Use working local Kamal setup for now
4. **GitHub webhook**: Consider alternative CI/CD triggers

## 🔧 Configuration Files Status

| File | Status | Notes |
|------|--------|-------|
| `config/deploy.staging.yml` | ✅ Working | Tested locally |
| `config/deploy.production.yml` | ⚠️ Needs production server IP | Template ready |
| `.github/workflows/deploy-staging.yml` | ❓ Unknown | Exists but not triggering |
| `.github/workflows/deploy-production.yml` | ❓ Unknown | Exists but not triggering |
| `.kamal/secrets.staging` | ✅ Template ready | Uses GitHub secrets |
| GitHub Secrets | ✅ All configured | Verified with `gh secret list` |

## 💡 Working Deployment Command

For immediate deployment needs, this works locally:
```bash
# Set environment variables (from .env file)
export RAILS_ENV=production
export DATABASE_URL="postgres://dbmasteruser:U0dplZ7NMoer3HveyM96WPt6Xhp@ls-8bb6904ba269b14c7d09489b908f65a526363016.co9scq0os79j.us-east-1.rds.amazonaws.com:5432"
export SECRET_KEY_BASE="dummy_secret_key_base_for_production_testing_only"
export RAILS_MASTER_KEY="789808daecc93cb5ee171f88c646cbbe"

# Deploy specific version
bin/kamal app boot --destination staging --version 0f096426c2e53e45dd433a9c50dd4b3cce8cedfb
```

## 📞 Support Escalation

If GitHub workflows continue to not trigger:
1. Check GitHub Status page for Actions issues
2. Try recreating workflow files with different names
3. Contact GitHub Support if this appears to be a platform issue
4. Consider alternative CI/CD platforms (GitLab CI, CircleCI, etc.)

---
**Note**: This is a living document. Update as we discover new information or resolve issues.