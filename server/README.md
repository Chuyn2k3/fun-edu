# FunEdu server

Backend for Chíp Chíp: family accounts (Google sign-in), progress sync and
online rocket race rooms. Design: `../docs/superpowers/specs/2026-11-21-giai-doan-2d-2b2-online-design.md`.

Stack: Java 21, Spring Boot 3.3, PostgreSQL 16, Flyway (`src/main/resources/db/migration`).
Requires JDK 21 installed locally (`JAVA_HOME` pointing to JDK 21) or Docker for containerized deployment.
Foojay auto-download plugin was removed to prevent external network fetching during Gradle builds.

## API (v1)

| Method | Path | Auth | |
|---|---|---|---|
| POST | `/api/v1/auth/google`, `/api/v1/auth/apple` | — | `{idToken, authorizationCode?}` → `{accessToken, refreshToken, expiresIn, familyId}`; first sign-in creates the family. Apple: the code is exchanged (with `APPLE_TEAM_ID/KEY_ID/PRIVATE_KEY`) for Apple's refresh token, stored AES-GCM sealed, and revoked when the account is deleted (Apple's rule); Apple being down never blocks sign-in or deletion |
| POST | `/api/v1/auth/refresh` | — | `{refreshToken}` → new pair; the old token dies, reusing it ends every session |
| POST | `/api/v1/auth/logout` | — | `{refreshToken}` → 204 |
| GET | `/api/v1/me` | Bearer | `{familyId, provider, email}` |
| DELETE | `/api/v1/account` | Bearer | Deletes the family and all its data → 204 |
| POST | `/api/v1/sync` | Bearer | `{since, changes:[{key, payload, deleted, baseVersion}]}` → `{version, records, conflicts, hasMore}` |

| POST | `/api/v1/rooms` | Bearer | Opens a race room → `{code, expiresAt}` (6 chars, no 0/O/1/I, 30 min) |
| WS | `/ws/room?code=XXXXXX` | Bearer (handshake header) | Live race room, see below |

### Race rooms

In memory (rooms live minutes; one instance is enough). JSON messages with a
`t` type. Client → server: `join {kid, name, avatar, rocket}` (first),
`start` (host, ≥ 2 kids), `step {n}` (+1 or +2, ≥ 600 ms apart, up to 10),
`sticker {id}` (fixed set: cheer, wow, love, fast, hi, gg; 1 per 1.5 s),
`again` (host, after the race), `leave`. Server → client: `room` (full
snapshot: `state` lobby/countdown/racing/done, `you`, `host`, `startsAt`,
`players[{id, name, avatar, rocket, steps, rank, connected}]`), `sticker
{from, id}`, `error {code}` (`not_found`, `room_full`, `started`,
`not_host`, `need_two`, `too_many`, `expired`, `bad_message`).

The server decides the finish order. A dropped kid may rejoin within 20 s
with the same kid id and keeps their steps. Names are cleaned to one line of
≤ 16 characters; avatars must be app asset paths; no free text is relayed.
Each family may open 20 rooms an hour and miss a code 10 times a minute.

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
### Backups

`deploy/backup.sh` dumps the database (`pg_dump -Fc`), encrypts it with
AES-256 (`BACKUP_PASSPHRASE`, PBKDF2) and keeps 14 days in
`deploy/backups/`; with `BACKUP_REMOTE` set it also copies each file off the
VM with rclone (the Oracle VM is a single point of failure). Run it nightly:

```bash
crontab -e   # 15 3 * * * cd /opt/funedu/server/deploy && ./backup.sh >> backup.log 2>&1
```

Try a restore every month into a scratch database (`funedu_restore`, the
live one is never touched unless `RESTORE_DB=funedu`):

```bash
./restore.sh backups/funedu-<stamp>.dump.enc
```

Keep `BACKUP_PASSPHRASE` somewhere safe off the VM too: without it no backup
can be read.
