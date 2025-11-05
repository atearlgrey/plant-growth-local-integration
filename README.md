# Plant Growth Local Integration

This project provides a local development environment setup for the Plant Growth application using Docker Compose. It includes essential services like Keycloak for authentication and PostgreSQL for database management.

## Prerequisites

- Docker
- Docker Compose

## Services

The following services are included in this setup:

1. **Keycloak**
   - Identity and Access Management
   - Pre-configured realm available in `keycloak-init/realm-plant-growth.json`

2. **PostgreSQL**
   - Database service
   - Initial database setup scripts in `postgres-init/00-init-databases.sql`

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/atearlgrey/plant-growth-local-integration.git
   cd plant-growth-local-integration
   ```

2. Start the services:
   ```bash
   docker-compose up -d
   ```

3. The services will be available at:
   - Keycloak: http://localhost:8080
   - PostgreSQL: localhost:5432

## Project Structure

```
.
├── docker-compose.yml          # Docker Compose configuration
├── keycloak-init/             # Keycloak initialization files
│   └── realm-plant-growth.json # Predefined realm configuration
└── postgres-init/             # PostgreSQL initialization scripts
    └── 00-init-databases.sql  # Database initialization script
```

## Configuration

Check the `docker-compose.yml` file for detailed service configurations and environment variables.

## User Management

### Default Users

The system comes with pre-configured user accounts in Keycloak:

1. **Admin User**
   - Username: `admin`
   - Password: `admin`
   - Role: System Administrator
   - Access: Full system access including user management

2. **Default Test User**
   - Username: `user`
   - Password: `123456`
   - Role: Regular User
   - Access: Basic application features

### Managing Users in Keycloak

1. Access the Keycloak Admin Console:
   - URL: http://localhost:8080/admin
   - Login with the admin credentials

2. Navigate to Users:
   - Select the "plant-growth" realm
   - Click on "Users" in the left menu
   - Use "Add user" to create new users

3. User Properties:
   - Required Actions: Set password reset, email verification, etc.
   - Credentials: Set or reset passwords
   - Role Mappings: Assign roles to users
   - Groups: Manage user group memberships

### User Roles

1. **Administrator**
   - Full system access
   - User management
   - System configuration
   - Monitoring and reporting

2. **Manager**
   - View all plants
   - Manage plant data
   - Generate reports
   - View analytics

3. **User**
   - View assigned plants
   - Update plant status
   - Basic reporting

### Password Policy

Default password requirements:
- Minimum length: 8 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character

## Database migrations (Flyway)

This project now includes Flyway migrations to manage database creation and schema.

- Migration files are located in `./flyway/sql`.
- The first migration `V1__create_databases_and_users.sql` creates the `keycloak` and `plant_growth_db` databases and their users (converted from `postgres-init/00-init-databases.sql`).

How to run migrations:

1. Start the core services (Postgres and Keycloak):
```bash
docker-compose up -d postgres keycloak
```

2. Run Flyway migrations (recommended):
```bash
docker-compose run --rm flyway migrate
```

Alternatively, you can let Compose start the flyway service which will run migrations and exit:
```bash
docker-compose up flyway
```

Notes:
- Flyway connects to the Postgres server using the `postgres` superuser to create databases and users. The connection is configured in `docker-compose.yml` (FLYWAY_URL, FLYWAY_USER, FLYWAY_PASSWORD).
- If you prefer the old behaviour where SQL in `postgres-init/` is executed by Postgres during initialization, you can keep that mount and remove the Flyway service. Currently the compose file uses Flyway for initialization.
