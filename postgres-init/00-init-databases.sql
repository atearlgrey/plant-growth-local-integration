-- ============================================
-- 🏗️ PostgreSQL initialization script
-- Creates:
--   - Database: keycloak       (User: keycloak)
--   - Database: plant_growth_db (User: plant_user)
-- ============================================

-- Create users
CREATE USER keycloak WITH PASSWORD 'keycloak';
CREATE USER plant_user WITH PASSWORD '123456';

-- Create Keycloak DB
CREATE DATABASE keycloak
  WITH OWNER = keycloak
  ENCODING = 'UTF8'
  LC_COLLATE = 'en_US.utf8'
  LC_CTYPE = 'en_US.utf8'
  TEMPLATE = template0;

-- Create Plant Growth DB
CREATE DATABASE plant_growth_db
  WITH OWNER = plant_user
  ENCODING = 'UTF8'
  LC_COLLATE = 'en_US.utf8'
  LC_CTYPE = 'en_US.utf8'
  TEMPLATE = template0;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
GRANT ALL PRIVILEGES ON DATABASE plant_growth_db TO plant_user;

-- Optional: make sure users can connect to their databases
ALTER DATABASE keycloak OWNER TO keycloak;
ALTER DATABASE plant_growth_db OWNER TO plant_user;
