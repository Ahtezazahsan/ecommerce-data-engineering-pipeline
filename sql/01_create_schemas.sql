-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 01_create_schemas.sql
-- Purpose: Create professional database schemas
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS mart;
CREATE SCHEMA IF NOT EXISTS audit;

-- Grant schema usage and create permissions to project user
GRANT USAGE, CREATE ON SCHEMA raw TO ecommerce_etl_user;
GRANT USAGE, CREATE ON SCHEMA staging TO ecommerce_etl_user;
GRANT USAGE, CREATE ON SCHEMA warehouse TO ecommerce_etl_user;
GRANT USAGE, CREATE ON SCHEMA mart TO ecommerce_etl_user;
GRANT USAGE, CREATE ON SCHEMA audit TO ecommerce_etl_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA raw
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ecommerce_etl_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA staging
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ecommerce_etl_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA warehouse
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ecommerce_etl_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA mart
GRANT SELECT ON TABLES TO ecommerce_etl_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA audit
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ecommerce_etl_user;