# Hosting Hackatime

This guide covers various options for deploying Hackatime to production.

## Table of Contents

1. [Deployment Options Overview](#deployment-options-overview)
2. [Deploy with Kamal (Recommended)](#deploy-with-kamal-recommended)
3. [Deploy with Docker](#deploy-with-docker)
4. [Deploy to Railway](#deploy-to-railway)
5. [Deploy to Render](#deploy-to-render)
6. [Deploy to Fly.io](#deploy-to-flyio)
7. [Deploy to Heroku](#deploy-to-heroku)
8. [Deploy to DigitalOcean](#deploy-to-digitalocean)
9. [Production Configuration](#production-configuration)
10. [SSL/HTTPS Setup](#sslhttps-setup)
11. [Monitoring & Maintenance](#monitoring--maintenance)

---

## Deployment Options Overview

| Platform | Difficulty | Cost | Best For |
|----------|------------|------|----------|
| **Kamal** | Medium | VPS cost (~$5-20/mo) | Full control, Docker-based |
| **Railway** | Easy | Free tier available | Quick deploys, beginners |
| **Render** | Easy | Free tier available | Simple hosting |
| **Fly.io** | Easy | Free tier available | Global edge deployment |
| **Heroku** | Easy | ~$7+/mo | Familiar PaaS |
| **DigitalOcean** | Medium | $5+/mo | App Platform or Droplets |

---

## Deploy with Kamal (Recommended)

Kamal is Rails' official deployment tool, included with Rails 8. It deploys Docker containers to any VPS.

### Prerequisites

- A VPS (DigitalOcean, Hetzner, Linode, AWS EC2, etc.)
- Docker installed locally
- SSH access to your server

### 1. Configure Kamal

Edit `config/deploy.yml`:

```yaml
service: hackatime
image: your-dockerhub-username/hackatime

servers:
  web:
    hosts:
      - your-server-ip
    labels:
      traefik.http.routers.hackatime.rule: Host(`hackatime.yourdomain.com`)
      traefik.http.routers.hackatime.tls.certresolver: letsencrypt

registry:
  username: your-dockerhub-username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - SLACK_CLIENT_ID
    - SLACK_CLIENT_SECRET
    - GITHUB_CLIENT_ID
    - GITHUB_CLIENT_SECRET

accessories:
  db:
    image: postgres:16
    host: your-server-ip
    port: 5432
    env:
      clear:
        POSTGRES_DB: hackatime_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "your-email@example.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpChallenge.entryPoint: "web"
```

### 2. Set Environment Variables

Create `.env` with your secrets:

```bash
KAMAL_REGISTRY_PASSWORD=your-dockerhub-token
RAILS_MASTER_KEY=your-master-key
DATABASE_URL=postgres://hackatime:password@hackatime-db:5432/hackatime_production
POSTGRES_PASSWORD=your-db-password
SLACK_CLIENT_ID=your-slack-client-id
SLACK_CLIENT_SECRET=your-slack-client-secret
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
```

### 3. Deploy

```bash
# Initial setup (first time only)
kamal setup

# Deploy updates
kamal deploy

# View logs
kamal logs

# Open Rails console
kamal console
```

---

## Deploy with Docker

For manual Docker deployment on any VPS.

### 1. Build the Image

```bash
# Build production image
docker build -t hackatime:latest .

# Or push to a registry
docker build -t your-registry/hackatime:latest .
docker push your-registry/hackatime:latest
```

### 2. Create docker-compose.prod.yml

```yaml
version: '3.8'

services:
  web:
    image: hackatime:latest
    ports:
      - "3000:80"
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - DATABASE_URL=postgres://hackatime:${DB_PASSWORD}@db:5432/hackatime_production
      - SLACK_CLIENT_ID=${SLACK_CLIENT_ID}
      - SLACK_CLIENT_SECRET=${SLACK_CLIENT_SECRET}
      - GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
      - GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
    depends_on:
      - db
    restart: always

  db:
    image: postgres:16
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=hackatime
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=hackatime_production
    restart: always

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - /etc/letsencrypt:/etc/letsencrypt
    depends_on:
      - web
    restart: always

volumes:
  postgres_data:
```

### 3. Deploy

```bash
# Copy files to server
scp docker-compose.prod.yml user@server:/app/
scp .env.production user@server:/app/.env

# SSH to server
ssh user@server

# Start services
cd /app
docker compose -f docker-compose.prod.yml up -d

# Run migrations
docker compose exec web bin/rails db:migrate
```

---

## Deploy to Railway

Railway offers easy deployments with a generous free tier.

### 1. Create Railway Account

Sign up at [railway.app](https://railway.app)

### 2. Create New Project

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Link to existing project (if needed)
railway link
```

### 3. Add PostgreSQL

In Railway dashboard:
1. Click "New" → "Database" → "PostgreSQL"
2. Railway automatically sets `DATABASE_URL`

### 4. Configure Environment

Add these environment variables in Railway dashboard:

```
RAILS_ENV=production
RAILS_MASTER_KEY=<from config/master.key>
SECRET_KEY_BASE=<generate with: rails secret>
SLACK_CLIENT_ID=your-slack-client-id
SLACK_CLIENT_SECRET=your-slack-client-secret
SLACK_REDIRECT_URI=https://your-app.railway.app/auth/slack/callback
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
```

### 5. Deploy

```bash
# Deploy
railway up

# Or connect GitHub for auto-deploys
# In Railway dashboard: Settings → Connect GitHub repo
```

### 6. Run Migrations

```bash
railway run bin/rails db:migrate
```

---

## Deploy to Render

Render provides simple hosting with free tier options.

### 1. Create render.yaml

Create `render.yaml` in your repo root:

```yaml
services:
  - type: web
    name: hackatime
    runtime: docker
    plan: starter
    healthCheckPath: /up
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: hackatime-db
          property: connectionString
      - key: SLACK_CLIENT_ID
        sync: false
      - key: SLACK_CLIENT_SECRET
        sync: false
      - key: GITHUB_CLIENT_ID
        sync: false
      - key: GITHUB_CLIENT_SECRET
        sync: false

databases:
  - name: hackatime-db
    plan: starter
    databaseName: hackatime_production
```

### 2. Deploy

1. Go to [render.com](https://render.com)
2. Click "New" → "Blueprint"
3. Connect your GitHub repo
4. Render detects `render.yaml` and creates services
5. Add secret environment variables in dashboard

---

## Deploy to Fly.io

Fly.io offers global edge deployment with a free tier.

### 1. Install Fly CLI

```bash
# macOS
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Login
fly auth login
```

### 2. Launch App

```bash
# Initialize (creates fly.toml)
fly launch

# This will ask questions about:
# - App name
# - Region
# - PostgreSQL database
```

### 3. Configure fly.toml

```toml
app = "hackatime"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[env]
  RAILS_ENV = "production"
  RAILS_LOG_TO_STDOUT = "true"

[http_service]
  internal_port = 80
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1

[[services]]
  protocol = "tcp"
  internal_port = 80

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  [[services.http_checks]]
    interval = 10000
    grace_period = "10s"
    method = "get"
    path = "/up"
```

### 4. Set Secrets

```bash
fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
fly secrets set SLACK_CLIENT_ID=your-slack-client-id
fly secrets set SLACK_CLIENT_SECRET=your-slack-client-secret
fly secrets set GITHUB_CLIENT_ID=your-github-client-id
fly secrets set GITHUB_CLIENT_SECRET=your-github-client-secret
```

### 5. Deploy

```bash
# Deploy
fly deploy

# Run migrations
fly ssh console -C "bin/rails db:migrate"

# View logs
fly logs
```

---

## Deploy to Heroku

Traditional PaaS deployment.

### 1. Install Heroku CLI

```bash
# macOS
brew tap heroku/brew && brew install heroku

# Login
heroku login
```

### 2. Create App

```bash
# Create app
heroku create hackatime

# Add PostgreSQL
heroku addons:create heroku-postgresql:essential-0

# Add Redis (for ActionCable)
heroku addons:create heroku-redis:mini
```

### 3. Configure

```bash
# Set environment variables
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
heroku config:set SLACK_CLIENT_ID=your-slack-client-id
heroku config:set SLACK_CLIENT_SECRET=your-slack-client-secret
heroku config:set SLACK_REDIRECT_URI=https://your-app.herokuapp.com/auth/slack/callback
heroku config:set GITHUB_CLIENT_ID=your-github-client-id
heroku config:set GITHUB_CLIENT_SECRET=your-github-client-secret
```

### 4. Deploy

```bash
# Deploy
git push heroku main

# Run migrations
heroku run bin/rails db:migrate

# Open app
heroku open
```

---

## Deploy to DigitalOcean

### Option A: App Platform

1. Go to [cloud.digitalocean.com](https://cloud.digitalocean.com)
2. Click "Create" → "Apps"
3. Connect GitHub repo
4. Configure:
   - Add PostgreSQL database
   - Set environment variables
5. Deploy

### Option B: Droplet with Docker

```bash
# Create droplet with Docker pre-installed
# SSH to droplet

# Clone repo
git clone https://github.com/your-repo/hackatime.git
cd hackatime

# Create .env with production settings
cp .env.example .env
nano .env  # Edit with production values

# Build and run
docker compose -f docker-compose.prod.yml up -d

# Run migrations
docker compose exec web bin/rails db:migrate
```

---

## Production Configuration

### Required Environment Variables

```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<from config/master.key>
SECRET_KEY_BASE=<generate with: bundle exec rails secret>

# Database
DATABASE_URL=postgres://user:password@host:5432/hackatime_production

# OAuth - Update callback URLs for your domain!
SLACK_CLIENT_ID=your-slack-client-id
SLACK_CLIENT_SECRET=your-slack-client-secret
SLACK_REDIRECT_URI=https://yourdomain.com/auth/slack/callback

GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret

# Error tracking (optional but recommended)
HONEYBADGER_API_KEY=your-honeybadger-key
SENTRY_DSN=your-sentry-dsn

# Performance monitoring (optional)
SKYLIGHT_AUTH_TOKEN=your-skylight-token

# GoodJob dashboard
GOOD_JOB_USERNAME=admin
GOOD_JOB_PASSWORD=secure-password
```

### Update OAuth Callback URLs

After deployment, update your OAuth apps with production URLs:

**Slack:**
- Redirect URL: `https://yourdomain.com/auth/slack/callback`

**GitHub:**
- Homepage URL: `https://yourdomain.com`
- Callback URL: `https://yourdomain.com/auth/github/callback`

---

## SSL/HTTPS Setup

### With Kamal/Traefik (Automatic)

SSL is automatically configured with Let's Encrypt in the Kamal config above.

### With Nginx + Certbot

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d hackatime.yourdomain.com

# Auto-renewal is configured automatically
```

### With Cloudflare

1. Add your domain to Cloudflare
2. Enable "Full (strict)" SSL mode
3. Point DNS to your server
4. Cloudflare handles SSL termination

---

## Monitoring & Maintenance

### Health Check

The app exposes `/up` endpoint for health checks.

### View Logs

```bash
# Kamal
kamal logs

# Docker
docker compose logs -f web

# Fly.io
fly logs

# Heroku
heroku logs --tail

# Railway
railway logs
```

### Database Backups

```bash
# Manual backup
pg_dump $DATABASE_URL > backup-$(date +%Y%m%d).sql

# Restore
psql $DATABASE_URL < backup.sql
```

### Scaling

Most platforms support horizontal scaling:

```bash
# Fly.io
fly scale count 3

# Heroku
heroku ps:scale web=3

# Kamal - add more hosts in deploy.yml
```

---

## Troubleshooting

### App Won't Start

```bash
# Check logs for errors
docker compose logs web

# Verify environment variables
docker compose exec web env | grep RAILS

# Check database connection
docker compose exec web bin/rails db:version
```

### OAuth Not Working

1. Verify callback URLs match your domain exactly
2. Check SLACK_CLIENT_ID and SLACK_CLIENT_SECRET are set
3. Ensure HTTPS is working (OAuth requires HTTPS in production)

### Database Issues

```bash
# Check connection
docker compose exec web bin/rails db:version

# Run pending migrations
docker compose exec web bin/rails db:migrate

# Reset database (WARNING: destroys data)
docker compose exec web bin/rails db:reset
```

---

## Need Help?

- Check [DEVELOPMENT.md](./DEVELOPMENT.md) for local setup
- Open an issue on GitHub
- Join the Hack Club Slack community
