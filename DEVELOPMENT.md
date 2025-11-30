# Hackatime Development Guide

This guide will help you set up and run Hackatime locally for development.

## Prerequisites

- **Docker** and **Docker Compose** (recommended)
- OR **Ruby 3.2+** and **PostgreSQL 16** for local development

## Quick Start with Docker (Recommended)

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/hackclub/hackatime
cd hackatime

# Copy environment configuration
cp .env.example .env
```

### 2. Start Docker Containers

```bash
# Start all services (PostgreSQL, Redis, and the web app)
docker compose up -d

# Enter the web container
docker compose run --service-ports web /bin/bash
```

### 3. Set Up the Database

Inside the Docker container (`app#` prompt):

```bash
# Create the database and run migrations
app# bin/rails db:create db:schema:load

# Seed with sample data (optional, for development)
app# bin/rails db:seed
```

### 4. Start the Development Server

```bash
# Start Rails server with Tailwind CSS watching
app# bin/dev
```

The application will be available at **http://localhost:3000**

---

## Local Development Setup (Without Docker)

### 1. Install Dependencies

**macOS:**
```bash
# Install Ruby (using rbenv or asdf)
brew install rbenv ruby-build
rbenv install 3.2.3
rbenv global 3.2.3

# Install PostgreSQL
brew install postgresql@16
brew services start postgresql@16

# Install Redis (optional, for caching)
brew install redis
brew services start redis
```

**Ubuntu/Debian:**
```bash
# Install Ruby dependencies
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev

# Install rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install ruby-build and Ruby
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 3.2.3
rbenv global 3.2.3

# Install PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib libpq-dev
sudo systemctl start postgresql

# Install Redis (optional)
sudo apt-get install -y redis-server
sudo systemctl start redis
```

### 2. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/hackclub/hackatime
cd hackatime

# Copy environment configuration
cp .env.example .env

# Edit .env with your database credentials
# DATABASE_URL=postgres://username:password@localhost:5432/hackatime_development
```

### 3. Install Ruby Dependencies

```bash
# Install bundler
gem install bundler

# Install gems
bundle install
```

### 4. Set Up the Database

```bash
# Create PostgreSQL user (if needed)
createuser -s hackatime

# Create and set up the database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # Optional: adds sample data
```

### 5. Start the Server

```bash
# Start the development server
bin/dev
```

Visit **http://localhost:3000**

---

## Configuration

### Environment Variables

Edit `.env` to configure your local environment:

```bash
# Database
DATABASE_URL=postgres://localhost:5432/hackatime_development

# OAuth (required for login)
SLACK_CLIENT_ID=your_slack_client_id
SLACK_CLIENT_SECRET=your_slack_client_secret
SLACK_REDIRECT_URI=http://localhost:3000/auth/slack/callback

GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# GoodJob Dashboard (optional)
GOOD_JOB_USERNAME=admin
GOOD_JOB_PASSWORD=admin
```

### Setting Up OAuth

#### Slack OAuth

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Create a new app
3. Add OAuth scopes: `openid`, `email`, `profile`
4. Set redirect URL to `http://localhost:3000/auth/slack/callback`
5. Copy Client ID and Client Secret to `.env`

#### GitHub OAuth

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App
3. Set Homepage URL to `http://localhost:3000`
4. Set callback URL to `http://localhost:3000/auth/github/callback`
5. Copy Client ID and Client Secret to `.env`

---

## Common Commands

### Rails Commands

```bash
# Start the development server
bin/dev

# Open Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Reset the database
bin/rails db:reset

# View all routes
bin/rails routes

# Check autoloader
bin/rails zeitwerk:check
```

### Testing

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run with verbose output
bin/rails test -v
```

### Linting

```bash
# Run RuboCop
bin/rubocop

# Auto-fix issues
bin/rubocop -a

# Security audit
bin/brakeman
bin/bundler-audit
```

### Background Jobs

```bash
# Jobs run automatically in development with async mode
# To view the GoodJob dashboard, visit:
# http://localhost:3000/good_job
# (Use credentials from .env: GOOD_JOB_USERNAME/GOOD_JOB_PASSWORD)
```

---

## Testing the API

### Get an API Key

1. Sign in to the app
2. Go to Settings
3. Create a new API Key
4. Copy the token

### Submit a Heartbeat

```bash
curl -X POST http://localhost:3000/api/hackatime/v1/users/current/heartbeats \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "time": 1701234567,
    "entity": "/home/user/project/app.rb",
    "project": "my-project",
    "language": "Ruby",
    "is_write": true
  }'
```

### Get Today's Stats

```bash
curl http://localhost:3000/api/hackatime/v1/users/current/statusbar/today \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Get 7-Day Stats

```bash
curl http://localhost:3000/api/hackatime/v1/users/current/stats/last_7_days \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## Connecting Your Editor

Hackatime is compatible with WakaTime plugins. To connect your editor:

1. Install the WakaTime plugin for your editor:
   - [VS Code](https://marketplace.visualstudio.com/items?itemName=WakaTime.vscode-wakatime)
   - [Vim/Neovim](https://github.com/wakatime/vim-wakatime)
   - [JetBrains IDEs](https://plugins.jetbrains.com/plugin/7425-wakatime)
   - [Other editors](https://wakatime.com/plugins)

2. When prompted for settings, configure:
   - **API Key**: Your Hackatime API key from Settings
   - **API URL**: `http://localhost:3000/api/hackatime/v1`

3. For most plugins, edit `~/.wakatime.cfg`:
   ```ini
   [settings]
   api_key = YOUR_API_KEY
   api_url = http://localhost:3000/api/hackatime/v1
   ```

---

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Check database exists
psql -l | grep hackatime

# Recreate database
bin/rails db:drop db:create db:migrate db:seed
```

### Bundle Install Fails

```bash
# Update bundler
gem update bundler

# Clear bundle cache
rm -rf vendor/bundle
bundle install
```

### Asset Compilation Issues

```bash
# Clear asset cache
bin/rails assets:clobber

# Rebuild assets
bin/rails assets:precompile
```

### Port Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

---

## Project Structure

```
hackatime/
├── app/
│   ├── controllers/      # MVC controllers
│   │   ├── api/          # API endpoints
│   │   └── admin/        # Admin interface
│   ├── models/           # ActiveRecord models
│   ├── views/            # ERB templates
│   ├── jobs/             # Background jobs
│   └── services/         # Business logic
├── config/
│   ├── routes.rb         # URL routing
│   └── initializers/     # App configuration
├── db/
│   ├── migrate/          # Database migrations
│   └── seeds.rb          # Seed data
└── test/                 # Test suite
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `bin/rails test`
5. Run linting: `bin/rubocop`
6. Commit with a clear message
7. Push and create a Pull Request

---

## Need Help?

- Check the [README](./README.md) for architecture overview
- Open an issue on GitHub
- Join the Hack Club Slack community
