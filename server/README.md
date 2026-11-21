# FunEdu server

Backend for Chíp Chíp: family accounts (Google sign-in), progress sync and
online rocket race rooms. Design: `../docs/superpowers/specs/2026-11-21-giai-doan-2d-2b2-online-design.md`.

Stack: Java 21, Spring Boot 3.3, PostgreSQL 16, Flyway (`src/main/resources/db/migration`).

## API (v1)

| Method | Path | Auth | |
|---|---|---|---|
| POST | `/api/v1/auth/google`, `/api/v1/auth/apple` | — | `{idToken}` → `{accessToken, refreshToken, expiresIn, familyId}`; first sign-in creates the family |
| POST | `/api/v1/auth/refresh` | — | `{refreshToken}` → new pair; the old token dies, reusing it ends every session |
| POST | `/api/v1/auth/logout` | — | `{refreshToken}` → 204 |
| GET | `/api/v1/me` | Bearer | `{familyId, provider, email}` |
| DELETE | `/api/v1/account` | Bearer | Deletes the family and all its data → 204 |
| POST | `/api/v1/sync` | Bearer | `{since, changes:[{key, payload, deleted, baseVersion}]}` → `{version, records, conflicts, hasMore}` |

### Sync

Family data is stored as keyed records (`kid:<uuid>`, `glyph:<kid>:<glyph>`,
`lesson:<kid>:<time>`, …; kinds whitelisted in `SyncKinds`). The **app**
merges (stars and races are unioned, counters take the max, the rest is
last-writer-wins); the **server** stores, orders and guards:

- every write gets a new `version` (one sequence; syncs of a family are
  serialised with an advisory lock so a cursor never skips a record);
- a change whose `baseVersion` is not the server's current version is a
  **conflict**: it is not stored and the winning copy is returned so the app
  can merge and retry;
- deletions are tombstones (`deleted: true`, no payload);
- pull returns at most 1000 records after `since` (`hasMore` for the rest);
- at most 2000 changes per call, 16 KB per payload; stroke coordinates are
  not an allowed kind and never leave the device.

One parent account (Google **or** Apple) per family. Access tokens: HS256,
15 min. Refresh tokens: 256-bit random, stored as SHA-256, 90 days.
`/api/v1/auth/**` is limited to 20 requests per minute per address. Errors
are `{"error": "<code>"}` only.

The server refuses to start without `AUTH_JWT_SECRET` (≥ 32 bytes). With no
`GOOGLE_CLIENT_IDS`, Google sign-in rejects every token (fail closed).

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
DB_URL=jdbc:postgresql://localhost:5432/funedu DB_USER=funedu DB_PASSWORD=funedu \
  AUTH_JWT_SECRET=$(openssl rand -base64 48) GOOGLE_CLIENT_IDS=<client id> ./gradlew bootRun
curl localhost:8080/actuator/health
```

## Deploy (Oracle VM)

```bash
cd deploy
cp .env.example .env   # fill in every value; never commit .env
docker compose up -d --build
```

Caddy serves HTTPS for `API_DOMAIN` (its DNS must point at the VM, ports 80/443
open). Only `/actuator/health` is exposed. Secrets live only in `.env`.
Nightly off-site backups are added in step 2D-7.
