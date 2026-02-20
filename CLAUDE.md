# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MySQL schema repository for [Catalog.beer](https://catalog.beer), a beer catalog platform. This repo contains only database schema definitions and backups — no application code. The application code lives in separate repositories:

- **Frontend:** [catalog-beer](https://github.com/michaelkirkpatrick/catalog-beer)
- **API:** [catalog-beer-api](https://github.com/michaelkirkpatrick/catalog-beer-api)

## Database: `catalogbeer`

- **Engine:** InnoDB
- **Charset:** utf8mb4 (collation: utf8mb4_0900_ai_ci)
- **Primary keys:** All tables use `varchar(36)` UUIDs as primary keys (not auto-increment)
- **Timestamps:** Stored as Unix epoch integers (`int`), not `DATETIME`/`TIMESTAMP`
- **Booleans:** Stored as `bit(1)` with defaults of `b'0'`
- **Naming convention:** camelCase for column names (e.g., `brewerID`, `lastModified`, `cbVerified`)

## Schema Architecture

The canonical schema is `catalog-beer-schema.sql`.

### Core domain tables
- **`brewer`** — Breweries. Has unique constraints on `url` and `domainName`.
- **`beer`** — Beers, each belonging to a brewer (`brewerID` → `brewer.id`, CASCADE delete).
- **`location`** — Physical locations for brewers (`brewerID` → `brewer.id`, CASCADE delete).
- **`US_addresses`** — US address details for locations (`locationID` → `location.id`). References `subdivisions` for state codes.
- **`subdivisions`** — US state/territory codes (keyed by `sub_code`).

### User & auth tables
- **`users`** — User accounts with email auth and password reset fields.
- **`api_keys`** — API keys linked to users.
- **`privileges`** — Maps users to brewers they can manage (many-to-many).

### Search tables
- **`algolia`** — Maps local records to Algolia search index objectIDs. Polymorphic: each row references exactly one of `beer`, `brewer`, or `location` via nullable FKs (`beer_id`, `brewer_id`, `location_id`). Uses snake_case column names (unlike the rest of the schema).

### Operational tables
- **`api_logging`** — Request/response log for API calls.
- **`api_usage`** — Monthly API usage counters per key.
- **`error_log`** — Application error tracking.

### Key relationships
All foreign keys use `ON DELETE CASCADE`. The central entity is `brewer` — deleting a brewer cascades to its beers, locations, addresses, user privileges, and Algolia search mappings.

## Files

| File | Purpose |
|------|---------|
| `catalog-beer-schema.sql` | Canonical schema (DDL only) |
| `Schema.pdf` | Visual ER diagram |

## Schema Versioning

Schema versions are tracked via git tags: `v1.0.0`, `v1.1`, `v1.2`, `v1.3`, `v1.4`. Notable additions across versions include the billing/`api_usage` table (v1.1), foreign key constraints (v1.3), and the Algolia search mapping table (v1.4).
