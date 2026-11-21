# FunEdu server

Backend for Chíp Chíp: family accounts (Google sign-in), progress sync and
online rocket race rooms. Design: `../docs/superpowers/specs/2026-11-21-giai-doan-2d-2b2-online-design.md`.

Stack: Java 21, Spring Boot 3.3, PostgreSQL 16, Flyway (`src/main/resources/db/migration`).

## Run tests

```bash
./gradlew test
```

Tests start a throwaway PostgreSQL with Testcontainers (needs Docker). Without
Docker, point them at an existing database:

```bash
TEST_DB_URL=jdbc:postgresql://localhost:5432/funedu_test TEST_DB_USER=funedu TEST_DB_PASSWORD=funedu ./gradlew test
```

## Run locally

```bash
DB_URL=jdbc:postgresql://localhost:5432/funedu DB_USER=funedu DB_PASSWORD=funedu ./gradlew bootRun
curl localhost:8080/actuator/health
```

## Deploy (Oracle VM)

```bash
cd deploy
cp .env.example .env   # fill in API_DOMAIN and a strong DB_PASSWORD
docker compose up -d --build
```

Caddy serves HTTPS for `API_DOMAIN` (its DNS must point at the VM, ports 80/443
open). Only `/actuator/health` is exposed. Secrets live only in `.env`.
Nightly off-site backups are added in step 2D-7.
