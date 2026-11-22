#!/usr/bin/env bash
# Restore an encrypted backup into a database (try it monthly on a scratch DB):
#   ./restore.sh backups/funedu-20261122T031500Z.dump.enc
# Default target: the db container's "funedu_restore" database (created
# fresh), so the live data is never touched unless RESTORE_DB=funedu.
set -euo pipefail
cd "$(dirname "$0")"
if [ -f .env ]; then set -a; . ./.env; set +a; fi
: "${BACKUP_PASSPHRASE:?BACKUP_PASSPHRASE is not set}"
file="${1:?usage: restore.sh <backup file>}"
DB="${RESTORE_DB:-funedu_restore}"
USER_="${DB_USER:-funedu}"
PSQL_CMD="${PSQL_CMD:-docker compose exec -T db psql -U $USER_ -d postgres}"
RESTORE_CMD="${RESTORE_CMD:-docker compose exec -T db pg_restore -U $USER_ --no-owner -d $DB}"

if [ "$DB" != "funedu" ]; then
  echo "DROP DATABASE IF EXISTS $DB; CREATE DATABASE $DB;" | $PSQL_CMD
fi
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -pass env:BACKUP_PASSPHRASE -in "$file" \
  | $RESTORE_CMD
echo "restored $file into $DB"
