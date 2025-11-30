# Hackatime Architecture Overview

Hackatime is a WakaTime-compatible coding time tracker built for [Hack Club](https://hackclub.com/). It tracks coding activity across 75+ editors and provides detailed statistics, leaderboards, and integrations with Slack.

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [Core Concepts](#core-concepts)
3. [Database Architecture](#database-architecture)
4. [Application Structure](#application-structure)
5. [Authentication & Authorization](#authentication--authorization)
6. [API Architecture](#api-architecture)
7. [Background Jobs](#background-jobs)
8. [Caching Strategy](#caching-strategy)
9. [Integrations](#integrations)
10. [Data Flow](#data-flow)

---

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.1.1
- **Database**: PostgreSQL 16
- **Background Jobs**: GoodJob (database-backed Active Job adapter)
- **Caching**: SolidCache (database-backed Rails.cache)
- **Real-time**: SolidCable (database-backed ActionCable)

### Frontend
- **CSS**: Tailwind CSS 4.x
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **Assets**: Propshaft + Importmap

### Infrastructure
- **Containerization**: Docker / Docker Compose
- **Deployment**: Kamal
- **Web Server**: Puma + Thruster
- **Error Tracking**: Honeybadger, Sentry
- **Performance Monitoring**: Skylight, Rack Mini Profiler
- **Analytics**: Ahoy

---

## Core Concepts

### Heartbeats
A **heartbeat** is the fundamental unit of tracking in Hackatime. Each heartbeat represents a single "ping" from an editor plugin, capturing:

- **time**: Unix timestamp of when the activity occurred
- **entity**: The file being edited
- **project**: The project/folder name
- **language**: Programming language detected
- **editor**: The editor/IDE being used
- **operating_system**: The user's OS
- **branch**: Git branch (if available)
- **machine**: Machine identifier

Heartbeats are aggregated into **coding duration** using a 2-minute timeout algorithm: consecutive heartbeats within 2 minutes are considered continuous coding activity.

### Duration Calculation
The `Heartbeatable` concern provides sophisticated duration calculation using PostgreSQL window functions:

```ruby
# Duration is calculated using window functions to find gaps between heartbeats.
# The algorithm:
# 1. Order heartbeats by time
# 2. Use LAG() to get the previous heartbeat's time
# 3. Calculate the difference, capped at 2 minutes (120 seconds)
# 4. Sum all capped differences

# Simplified SQL (actual implementation in Heartbeatable concern):
SELECT COALESCE(SUM(diff), 0)::integer FROM (
  SELECT CASE
    WHEN LAG(time) OVER (ORDER BY time) IS NULL THEN 0
    ELSE LEAST(
      EXTRACT(EPOCH FROM (to_timestamp(time) - to_timestamp(LAG(time) OVER (ORDER BY time)))),
      120  -- 2-minute timeout
    )
  END as diff
  FROM heartbeats
) AS diffs
```

The implementation also supports:
- **Span generation**: Converting heartbeats into continuous coding sessions
- **Grouped calculations**: Aggregating by project, language, editor, etc.
- **Boundary-aware duration**: Accurate calculations across time range boundaries

### Leaderboards
Leaderboards aggregate user coding times across configurable time periods:
- **Daily**: Single day rankings
- **Last 7 Days**: Rolling weekly rankings

Leaderboards are computed asynchronously and cached for performance.

### Streaks
A **streak** is the number of consecutive days a user has coded for at least 15 minutes. Streaks are calculated from heartbeat data and cached for 1 hour.

---

## Database Architecture

### Core Tables

#### `users`
The central user table with authentication and profile data:

| Column | Description |
|--------|-------------|
| `slack_uid` | Unique Slack user ID (primary auth) |
| `github_uid` | Linked GitHub account |
| `username` | Custom display username |
| `timezone` | User's timezone for calculations |
| `trust_level` | Moderation status (blue/green/yellow/red) |
| `admin_level` | Permission level (default/viewer/admin/superadmin) |

#### `heartbeats`
The main data table storing all coding activity:

| Column | Description |
|--------|-------------|
| `user_id` | Foreign key to users |
| `time` | Unix timestamp (indexed) |
| `entity` | File path being edited |
| `project` | Project name |
| `language` | Programming language |
| `editor` | Editor/IDE name |
| `source_type` | Origin: direct_entry, wakapi_import, test_entry |
| `fields_hash` | MD5 hash for deduplication |
| `deleted_at` | Soft delete timestamp |

Key indexes optimize common queries:
- `(user_id, time)` - User activity lookups
- `(user_id, project, time)` - Project statistics
- `(fields_hash)` - Deduplication

#### `api_keys`
API tokens for WakaTime-compatible authentication:

| Column | Description |
|--------|-------------|
| `user_id` | Foreign key to users |
| `token` | Unique API token |
| `name` | Friendly name for the key |

#### `leaderboards` & `leaderboard_entries`
Pre-computed ranking data:

| Leaderboard Fields | Description |
|-------------------|-------------|
| `start_date` | Period start |
| `period_type` | daily, last_7_days |
| `finished_generating_at` | Completion timestamp |

| Entry Fields | Description |
|-------------|-------------|
| `user_id` | Ranked user |
| `total_seconds` | Computed coding time |
| `rank` | Position |
| `streak_count` | Current streak |

### Supporting Tables

- **`email_addresses`**: Multiple emails per user
- **`sign_in_tokens`**: Magic link authentication
- **`project_repo_mappings`**: Link projects to GitHub repos
- **`repositories`**: Cached GitHub repository metadata
- **`commits`**: Tracked GitHub commits
- **`wakatime_mirrors`**: Sync to external WakaTime instances
- **`trust_level_audit_logs`**: Moderation history
- **`mailing_addresses`**: Physical mail for rewards
- **`physical_mails`**: Mail delivery tracking

### External Syncs

- **`neighborhood_*`**: Airtable synced data for Hack Club programs
- **`sailors_log_*`**: Slack bot integration data

---

## Application Structure

### Models (`app/models/`)

```
models/
├── user.rb                    # Core user model
├── heartbeat.rb               # Coding activity records
├── api_key.rb                 # API authentication
├── leaderboard.rb             # Leaderboard aggregations
├── leaderboard_entry.rb       # Individual rankings
├── repository.rb              # GitHub repos
├── commit.rb                  # GitHub commits
├── project_repo_mapping.rb    # Project to repo links
├── wakatime_mirror.rb         # External sync config
├── sailors_log.rb             # Slack bot state
└── concerns/
    ├── heartbeatable.rb       # Duration calculation logic
    ├── time_range_filterable.rb  # Date range queries
    └── timezone_regions.rb    # Timezone groupings
```

### Controllers (`app/controllers/`)

```
controllers/
├── application_controller.rb  # Base controller with auth
├── static_pages_controller.rb # Dashboard & homepage
├── sessions_controller.rb     # Auth (Slack/GitHub/Email)
├── users_controller.rb        # Settings & profile
├── leaderboards_controller.rb # Leaderboard views
├── slack_controller.rb        # Slack commands
├── api/
│   ├── hackatime/v1/         # WakaTime-compatible API
│   │   └── hackatime_controller.rb
│   ├── v1/                   # Custom Hackatime API
│   │   ├── stats_controller.rb
│   │   ├── users_controller.rb
│   │   └── authenticated/    # OAuth-protected endpoints
│   └── admin/v1/             # Admin API
└── admin/                    # Admin web interface
```

### Services (`app/services/`)

```
services/
├── leaderboard_service.rb    # Leaderboard orchestration
├── leaderboard_builder.rb    # Leaderboard computation
├── leaderboard_cache.rb      # Caching helpers
├── leaderboard_date_range.rb # Date calculations
├── heartbeat_import_service.rb # Bulk import
└── repo_host/                # GitHub integration
```

### Jobs (`app/jobs/`)

Priority queues (via GoodJob):
- `latency_10s`: Fast, real-time jobs
- `latency_1m`: Regular priority
- `latency_5m`: Batch processing
- `latency_15m`: Background maintenance

Key jobs:
```
jobs/
├── leaderboard_update_job.rb        # Rebuild leaderboards
├── migrate_user_from_hackatime_job.rb # Import legacy data
├── wakatime_mirror_sync_job.rb      # External sync
├── scan_github_repos_job.rb         # GitHub discovery
├── pull_repo_commits_job.rb         # Commit history
├── user_slack_status_update_job.rb  # Slack status
├── sailors_log_poll_for_changes_job.rb # Slack bot
└── cache/                           # Cache warming jobs
```

---

## Authentication & Authorization

### Authentication Methods

1. **Slack OAuth** (Primary)
   - Users authenticate via Slack OAuth 2.0
   - Grants access to profile, timezone, and status updates
   - Creates/links accounts via email matching

2. **GitHub OAuth** (Secondary, linked to existing account)
   - Links GitHub identity for repository features
   - Enables project-to-repo mapping
   - Triggers repository scanning

3. **Email Magic Links**
   - Passwordless email authentication
   - Creates `SignInToken` with expiration
   - Supports email verification flow

4. **API Key Authentication**
   - Bearer token or Basic auth
   - Required for editor plugins
   - Multiple keys per user supported

### Authorization Levels

```ruby
enum :trust_level, {
  blue: 0,     # Unscored (default)
  red: 1,      # Convicted (banned from leaderboards)
  green: 2,    # Trusted
  yellow: 3    # Suspected (hidden from user)
}

enum :admin_level, {
  default: 0,    # Regular user
  superadmin: 1, # Full access
  admin: 2,      # Moderation access
  viewer: 3      # Read-only admin
}
```

### API Authentication Flow

```
Request → Authorization Header → API Key lookup → User context
                    ↓
            Bearer <token>
                 OR
            Basic base64(<token>)
                 OR
            ?api_key=<token>
```

### OAuth 2.0 (Doorkeeper)

Hackatime implements OAuth 2.0 as a provider using Doorkeeper, enabling third-party applications to access user data with proper scopes.

---

## API Architecture

### WakaTime-Compatible API (`/api/hackatime/v1/`)

These endpoints mirror WakaTime's API for plugin compatibility:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/users/:id/heartbeats` | POST | Submit heartbeats |
| `/users/:id/heartbeats.bulk` | POST | Bulk submit |
| `/users/:id/statusbar/today` | GET | Editor status bar data |
| `/users/current/stats/last_7_days` | GET | 7-day statistics |

### Custom API (`/api/v1/`)

Hackatime-specific endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/stats` | GET | Global statistics (admin) |
| `/users/:username/stats` | GET | User public stats |
| `/users/:username/heartbeats/spans` | GET | Activity spans |
| `/users/:username/projects` | GET | Project list |
| `/users/:username/trust_factor` | GET | Trust level info |
| `/my/heartbeats` | GET | Current user heartbeats |
| `/my/heartbeats/most_recent` | GET | Latest heartbeat |

### OAuth-Authenticated API (`/api/v1/authenticated/`)

Protected by Doorkeeper OAuth:

| Endpoint | Description |
|----------|-------------|
| `/me` | Current user info |
| `/hours` | Coding hours data |
| `/streak` | Streak information |
| `/projects` | Project list |
| `/heartbeats/latest` | Most recent heartbeat |
| `/api_keys` | API key management |

### Admin API (`/api/admin/v1/`)

Admin-only operations:

| Endpoint | Description |
|----------|-------------|
| `/check` | Admin access verification |
| `/user/info` | User lookup |
| `/user/stats` | User statistics |
| `/user/convict` | Trust level changes |
| `/execute` | Admin operations |

---

## Background Jobs

### Job Processing (GoodJob)

GoodJob provides a PostgreSQL-backed job queue with:
- Concurrency control per job type
- Cron scheduling
- Job batching
- Web UI for monitoring

### Key Job Patterns

#### Concurrency Control
```ruby
# Only one leaderboard job per period/date
good_job_control_concurrency_with(
  key: -> { "leaderboard_#{arguments[0]}_#{arguments[1]}" },
  total: 1,
  drop: true
)
```

#### Cache Jobs
Jobs prefixed with `Cache::` warm frequently-accessed data:
- `Cache::HeartbeatCountsJob`
- `Cache::ActiveUsersGraphDataJob`
- `Cache::CurrentlyHackingJob`
- `Cache::HomeStatsJob`

### Scheduled Jobs

Defined in `config/initializers/good_job.rb`:
- Leaderboard updates
- Cache warming
- Stale data cleanup
- External syncs

---

## Caching Strategy

### Cache Layers

1. **SolidCache** (Database-backed)
   - Primary Rails.cache backend
   - Persistent across restarts
   - Stored in `solid_cache_entries` table

2. **Per-Request Counters**
   - Thread-local cache hit/miss tracking
   - Available via `ApplicationHelper#cache_stats`

### Common Cache Keys

```ruby
# User activity
"user_#{user_id}_daily_durations"
"user_#{user_id}_project_durations_#{interval}"
"user_streak_#{user_id}"

# Global data
"leaderboard_#{period}_#{date}"
"currently_hacking_users"
"active_projects"
"home_stats"
```

### Cache Invalidation

- Time-based expiration (1 minute to 1 hour typically)
- User timezone changes invalidate activity graphs
- Manual invalidation via admin tools

---

## Integrations

### Slack Integration

1. **OAuth Login**: Primary authentication method
2. **Slack Status**: Auto-update user status with current project
3. **Slash Commands**: `/sailorslog` for time queries
4. **Notifications**: Project time updates

### GitHub Integration

1. **OAuth Linking**: Connect GitHub identity
2. **Repository Scanning**: Discover user repositories
3. **Commit Tracking**: Link commits to coding time
4. **Project Mapping**: Auto-link projects to repos

### Airtable Integration

Uses `norairrecord` gem to sync:
- Neighborhood applications
- YSWS (You Ship We Ship) programs
- Project submissions

### WakaTime Mirror

Optional sync to external WakaTime instances:
- Encrypts API keys at rest
- Mirrors heartbeats on submission
- Supports custom endpoints

---

## Data Flow

### Heartbeat Submission Flow

```
Editor Plugin
     ↓
POST /api/hackatime/v1/users/:id/heartbeats
     ↓
API Key Authentication (set_user)
     ↓
Parse User Agent (WakatimeService)
     ↓
Find or Create Heartbeat (dedupe via fields_hash)
     ↓
Queue Side Effects:
├── AttemptProjectRepoMappingJob
└── CreateHeartbeatActivityJob (optional)
     ↓
Response: 201 Created
```

### Leaderboard Generation Flow

```
LeaderboardUpdateJob triggered
     ↓
Check existing leaderboard for date/period
     ↓
Query heartbeats with:
├── Time range filter
├── Valid timestamp filter
├── Coding category filter
├── GitHub-linked users only
└── Exclude convicted users
     ↓
Calculate duration_seconds per user
     ↓
Calculate streaks via daily_streaks_for_users
     ↓
Bulk insert LeaderboardEntry records
     ↓
Mark leaderboard as finished_generating
     ↓
Cache the leaderboard
```

### Dashboard Data Flow

```
User visits dashboard
     ↓
StaticPagesController#index
     ↓
Parallel data fetch:
├── Today's languages/editors (SQL window functions)
├── Leaderboard (LeaderboardService)
├── Project durations (cached)
├── Activity graph (cached)
└── Currently hacking users (cached)
     ↓
Render with Turbo Frames for lazy loading
```

---

## Development Setup

### Prerequisites
- Docker & Docker Compose
- Ruby 3.2+ (for local development without Docker)

### Quick Start

```bash
# Clone and configure
git clone https://github.com/hackclub/hackatime
cd hackatime
cp .env.example .env

# Start Docker and enter the container
docker compose run --service-ports web /bin/bash

# Inside the container (app#), run:
app# bin/rails db:create db:schema:load db:seed
app# bin/dev
```

> **Note**: Commands prefixed with `app#` should be run inside the Docker container after running the `docker compose run` command.

### Key Commands

All commands below should be run via Docker Compose:

```bash
# Development
docker compose run web rails c              # Interactive Rails console
docker compose run web rails test           # Run test suite
docker compose run web bundle exec rubocop  # Lint code

# Database
docker compose run web rails db:migrate     # Run migrations
docker compose run web rails db:seed        # Seed database

# Security
docker compose run web bundle exec brakeman     # Security audit
docker compose run web bin/importmap audit      # JS dependency scan
docker compose run web bin/rails zeitwerk:check # Autoloader check
```

---

## Security Considerations

### Trust System
- Users can be flagged as `yellow` (suspected) or `red` (convicted)
- Convicted users are excluded from leaderboards
- Audit logs track trust level changes

### Rate Limiting
Rack::Attack provides API rate limiting:
- Per-IP request limits
- API key-based throttling

### Input Validation
- Heartbeat fields are validated and hashed
- User agents are parsed and normalized
- UTF-8 sanitization on API inputs

### Encryption
- Slack/GitHub access tokens encrypted at rest
- API keys stored as secure tokens
- Database credentials via environment variables

---

## File Structure Summary

```
hackatime/
├── app/
│   ├── controllers/      # MVC controllers
│   ├── models/           # ActiveRecord models
│   ├── views/            # ERB templates
│   ├── jobs/             # GoodJob background jobs
│   ├── services/         # Business logic
│   ├── helpers/          # View helpers
│   ├── mailers/          # Email templates
│   └── lib/              # Utility classes
├── config/
│   ├── routes.rb         # URL routing
│   ├── database.yml      # DB configuration
│   └── initializers/     # App configuration
├── db/
│   ├── schema.rb         # Database schema
│   ├── migrate/          # Migrations
│   └── seeds.rb          # Seed data
├── docs/                 # API documentation
├── test/                 # Test suite
└── docker-compose.yml    # Development containers
```

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following existing patterns
4. Run tests and linting
5. Submit a pull request

See [README.md](./README.md) for detailed development setup instructions.
