# 🚀 Keelfin - Capistrano Deployment Guide

## 📋 Before You Deploy

### 1. Git Repository
Repository: `git@github.com:Mutalenic/keelfin.git`

### 2. Push Your Code to GitHub
```bash
git add .
git commit -m "Add Capistrano deployment configuration"
git push origin main
```

### 3. Create Production Database Config
Copy the database config to server:
```bash
scp config/database.yml.production deploy@144.126.239.114:~/keelfin/shared/config/database.yml
```

## 🚀 Deploy Commands

### First Time Setup
```bash
# Check connection
bundle exec cap production doctor

# Setup server directories
bundle exec cap production deploy:check

# Install dependencies
bundle exec cap production bundler:install

# Setup database
bundle exec cap production rails:db:migrate
```

### Deploy Your App
```bash
# Full deployment
bundle exec cap production deploy
```

## 🔄 Deploy Workflow

### For Future Updates
1. Make changes locally
2. Commit and push to GitHub
3. Run: `bundle exec cap production deploy`

### Useful Commands
```bash
# Check server status
bundle exec cap production puma:status

# Restart Puma
bundle exec cap production puma:restart

# View logs
bundle exec cap production puma:logs

# Rollback to previous version
bundle exec cap production deploy:rollback
```

## 🌐 Access Your App

After successful deployment:
- **URL**: https://keelfin.app
- **SSH**: ssh deploy@144.126.239.114

## 🔧 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   ssh deploy@144.126.239.114 "chmod +x ~/.rbenv/bin/rbenv"
   ```

2. **Database Connection Issues**
   ```bash
   ssh deploy@144.126.239.114 "sudo -u postgres psql -c 'ALTER USER deploy CREATEDB;'"
   ```

3. **Puma Not Starting**
   ```bash
   bundle exec cap production puma:stop
   bundle exec cap production puma:start
   ```

4. **NGINX Issues**
   ```bash
   ssh root@144.126.239.114 "nginx -t && systemctl restart nginx"
   ```

## 📊 Server Specs

- **RAM**: 1GB (optimized for Rails)
- **CPU**: 1 core
- **Storage**: 25GB SSD
- **OS**: Ubuntu 24.04 LTS
- **Ruby**: 3.3.5 (rbenv)
- **Database**: PostgreSQL 16
- **Web Server**: NGINX + Puma

## ⚡ Performance Optimizations

- **Puma**: 1 worker, 1-2 threads (optimized for 1GB RAM)
- **NGINX**: Static asset caching
- **Rails**: Production optimizations enabled

## 🛡️ Security

- SSH key authentication only
- Firewall enabled (SSH only)
- Deploy user with limited sudo access
- PostgreSQL peer authentication
