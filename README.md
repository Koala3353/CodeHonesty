# Hackatime

Hackatime is a code time tracking service that monitors your coding activity across various editors and IDEs. It's compatible with WakaTime plugins and provides detailed insights into your programming habits.

## Table of Contents

- [How User Tracking Works](#how-user-tracking-works)
- [Features](#features)
- [User Installation Guide](#user-installation-guide)
- [API Configuration](#api-configuration)
- [Leaderboards and Statistics](#leaderboards-and-statistics)
- [Development Setup](#development-setup)
- [Deployment](#deployment)

---

## How User Tracking Works

Hackatime uses a **heartbeat-based tracking system** to monitor your coding activity:

### The Heartbeat System

1. **Editor Plugin Integration**: When you code, your editor plugin (WakaTime-compatible) sends "heartbeats" to the Hackatime server every few seconds while you're actively coding.

2. **Data Captured**: Each heartbeat includes:
   - **Timestamp**: When the activity occurred
   - **Entity**: The file you're working on (path/filename)
   - **Project**: The project name (usually derived from the folder or git repository)
   - **Language**: The programming language detected from the file
   - **Editor**: Which editor/IDE you're using (VS Code, Vim, JetBrains, etc.)
   - **Branch**: The current git branch (if applicable)
   - **Is Write**: Whether you're actively writing code vs. just reading

3. **Duration Calculation**: Hackatime calculates your coding time by measuring gaps between consecutive heartbeats. Gaps larger than 2 minutes are capped, ensuring accurate tracking even when you step away briefly.

4. **Privacy**: Only metadata about your files is tracked (filename, language, project). The actual content of your code is **never** sent to the server.

### How Time is Calculated

```
Heartbeat 1: 10:00:00 (file.js)
Heartbeat 2: 10:00:30 (file.js) → 30 seconds of coding
Heartbeat 3: 10:01:15 (file.js) → 45 seconds of coding
Heartbeat 4: 10:05:00 (file.js) → 2 minutes (capped, actual gap was 3:45)
```

This algorithm ensures that bathroom breaks or phone calls don't artificially inflate your coding time.

---

## Features

### For Users

| Feature | Description |
|---------|-------------|
| **Real-time Tracking** | Automatic tracking of your coding activity with no manual input required |
| **Multi-Editor Support** | Works with VS Code, Vim/Neovim, JetBrains IDEs, Sublime Text, Atom, Emacs, and more |
| **Language Statistics** | See breakdown of time spent in each programming language |
| **Project Tracking** | Track time spent on different projects separately |
| **Daily/Weekly Stats** | View your coding statistics for today, last 7 days, or custom ranges |
| **Streak Tracking** | Track consecutive days of coding (minimum 15 minutes/day) |
| **Editor Analytics** | See which editors you use most |
| **Coding Sessions (Spans)** | View continuous coding sessions with start/end times |
| **Status Bar Integration** | See today's coding time directly in your editor's status bar |
| **Leaderboards** | Compare your coding time with other users |
| **API Access** | Access your data programmatically via REST API |
| **OAuth Login** | Sign in with Slack or GitHub |
| **Timezone Support** | Statistics calculated in your local timezone |
| **WakaTime Mirror** | Sync heartbeats to WakaTime simultaneously |

### Trust System

Hackatime includes a trust system for leaderboard integrity:
- **Blue**: Default status (unscored)
- **Green**: Trusted user
- **Yellow**: Under review (hidden from user)
- **Red**: Excluded from leaderboards

---

## User Installation Guide

### Step 1: Create an Account

1. Visit your Hackatime instance (e.g., `https://hackatime.yourdomain.com`)
2. Sign in using **Slack** or **GitHub** OAuth
3. You'll be automatically assigned a username

### Step 2: Get Your API Key

1. Once logged in, go to **Settings**
2. Click **Create API Key**
3. Copy your API key (it looks like: `abc123xyz...`)

### Step 3: Install Editor Plugin

Install the WakaTime plugin for your editor:

#### VS Code
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "WakaTime"
4. Click Install on **WakaTime** by WakaTime
5. When prompted for API key, enter your Hackatime API key

#### Vim / Neovim
```bash
# Using vim-plug
Plug 'wakatime/vim-wakatime'

# Using Vundle
Plugin 'wakatime/vim-wakatime'

# Using Pathogen
git clone https://github.com/wakatime/vim-wakatime.git ~/.vim/bundle/vim-wakatime
```

#### JetBrains IDEs (IntelliJ, WebStorm, PyCharm, etc.)
1. Go to **Settings** → **Plugins**
2. Search for "WakaTime"
3. Install and restart IDE
4. Enter your API key when prompted

#### Sublime Text
1. Install Package Control if not already installed
2. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
3. Type "Install Package" and select it
4. Search for "WakaTime" and install

#### Other Editors
Visit [wakatime.com/plugins](https://wakatime.com/plugins) for plugins for:
- Emacs
- Atom
- Visual Studio
- Xcode
- Android Studio
- Eclipse
- And many more...

### Step 4: Configure API URL

After installing the plugin, you need to point it to your Hackatime server:

#### Option A: Edit Configuration File (Recommended)

Edit or create `~/.wakatime.cfg`:

```ini
[settings]
api_key = YOUR_API_KEY_HERE
api_url = https://hackatime.yourdomain.com/api/hackatime/v1
```

**Important**: Replace `https://hackatime.yourdomain.com` with your actual Hackatime server URL.

#### Option B: VS Code Settings

1. Open VS Code Settings (Ctrl+, / Cmd+,)
2. Search for "wakatime"
3. Set **Api Key** to your Hackatime API key
4. Set **Api Url** to `https://hackatime.yourdomain.com/api/hackatime/v1`

### Step 5: Verify It's Working

After configuration, start coding! You should see:

1. **Status Bar**: Your coding time for today appears in the editor status bar
2. **Dashboard**: Visit your Hackatime dashboard to see activity appearing within a few minutes

#### Test with curl

You can test your API key:

```bash
# Check today's status
curl https://hackatime.yourdomain.com/api/hackatime/v1/users/current/statusbar/today \
  -H "Authorization: Bearer YOUR_API_KEY"

# Check last 7 days stats
curl https://hackatime.yourdomain.com/api/hackatime/v1/users/current/stats/last_7_days \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## API Configuration

### API Endpoints

Hackatime provides a WakaTime-compatible API:

#### Core Endpoints (WakaTime Compatible)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/hackatime/v1/users/current/heartbeats` | POST | Submit a single heartbeat |
| `/api/hackatime/v1/users/current/heartbeats.bulk` | POST | Submit multiple heartbeats |
| `/api/hackatime/v1/users/current/statusbar/today` | GET | Get today's coding stats |
| `/api/hackatime/v1/users/current/stats/last_7_days` | GET | Get last 7 days summary |

#### Public User Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/users/:username/stats` | GET | Get user's coding statistics |
| `/api/v1/users/:username/heartbeats/spans` | GET | Get user's coding sessions |
| `/api/v1/users/:username/projects` | GET | Get user's project list |
| `/api/v1/users/:username/trust_factor` | GET | Get user's trust level |

#### Authenticated User Endpoints (OAuth)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/authenticated/me` | GET | Get current user profile |
| `/api/v1/authenticated/hours` | GET | Get total coding hours |
| `/api/v1/authenticated/streak` | GET | Get current coding streak |
| `/api/v1/authenticated/projects` | GET | Get current user's projects |
| `/api/v1/authenticated/heartbeats/latest` | GET | Get most recent heartbeat |
| `/api/v1/authenticated/api_keys` | GET | List user's API keys |

### Heartbeat Format

```json
{
  "time": 1701234567,
  "entity": "/home/user/project/app.rb",
  "project": "my-project",
  "language": "Ruby",
  "branch": "main",
  "is_write": true
}
```

### Authentication

Include your API key in requests:

```bash
# Bearer token (recommended)
Authorization: Bearer YOUR_API_KEY

# Or Basic auth (WakaTime style)
Authorization: Basic base64(API_KEY:)
```

---

## Leaderboards and Statistics

### Viewing Your Stats

- **Dashboard**: Your personal dashboard shows:
  - Today's coding time
  - Weekly summary
  - Language breakdown
  - Project breakdown
  - Editor usage

- **Public Profile**: Visit `/users/YOUR_USERNAME` to see your public profile

### Leaderboards

- View leaderboards at `/leaderboards`
- Compete with other users on:
  - Daily coding time
  - Weekly totals
  - Project-specific leaderboards

---

## Development Setup

For local development setup, see [DEVELOPMENT.md](./DEVELOPMENT.md).

Quick start:
```bash
# Clone and setup
git clone <repository-url>
cd <repository-name>
cp .env.example .env

# With Docker (recommended)
docker compose up -d
docker compose run --service-ports web /bin/bash
bin/rails db:create db:schema:load db:seed
bin/dev

# Visit http://localhost:3000
```

---

## Deployment

For production deployment options, see [HOSTING.md](./HOSTING.md).

Supported platforms:
- **Kamal** (Rails official deployment tool)
- **Docker** on any VPS
- **Railway**, **Render**, **Fly.io**
- **Heroku**, **DigitalOcean**

---

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Editor Plugin  │────▶│  Hackatime API   │────▶│   PostgreSQL    │
│  (WakaTime)     │     │  (Rails + Ruby)  │     │   Database      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  Background Jobs │
                        │  (GoodJob)       │
                        └──────────────────┘
```

### Tech Stack

- **Backend**: Ruby on Rails 8
- **Database**: PostgreSQL 16
- **Background Jobs**: GoodJob
- **Authentication**: OAuth (Slack, GitHub) + Magic Links
- **Styling**: Tailwind CSS

---

## Need Help?

- Check [DEVELOPMENT.md](./DEVELOPMENT.md) for development setup
- Check [HOSTING.md](./HOSTING.md) for deployment guides
- Open an issue on GitHub
- Join the Hack Club Slack community
