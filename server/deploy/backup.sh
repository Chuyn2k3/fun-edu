#!/usr/bin/env bash
# Nightly encrypted backup of the FunEdu database (run by cron on the VM):
#   15 3 * * * cd /opt/funedu/server/deploy && ./backup.sh >> backup.log 2>&1
#
# Needs in .env (never committed):
#   BACKUP_PASSPHRASE  long random secret; without it backups cannot be read
#   BACKUP_REMOTE      optional rclone target off the VM, e.g. "b2:funedu-backups"
# Keeps the last BACKUP_KEEP_DAYS (default 14) dumps in BACKUP_DIR locally.
set -euo pipefail
cd "$(dirname "$0")"
if [ -f .env ]; then set -a; . ./.env; set +a; fi

: "${BACKUP_PASSPHRASE:?BACKUP_PASSPHRASE is not set}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
KEEP="${BACKUP_KEEP_DAYS:-14}"
# Tests and other hosts can swap the dump command (default: the db container).
DUMP_CMD="${DUMP_CMD:-docker compose exec -T db pg_dump -U ${DB_USER:-funedu} -d funedu -Fc}"

mkdir -p "$BACKUP_DIR"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
out="$BACKUP_DIR/funedu-$stamp.dump.enc"
tmp="$out.part"
# Never leave a half-written file behind (failed dump, full disk, ...).
trap 'rm -f "$tmp"' EXIT

# Custom-format dump (already compressed), encrypted with AES-256 + PBKDF2.
$DUMP_CMD | openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt \
  -pass env:BACKUP_PASSPHRASE -out "$tmp"
# An empty or tiny file means the dump failed silently.
if [ "$(wc -c < "$tmp")" -lt 1024 ]; then
  rm -f "$tmp"
  echo "$(date -u) backup FAILED: dump too small" >&2
  exit 1
fi
mv "$tmp" "$out"
echo "$(date -u) backup ok: $out ($(wc -c < "$out") bytes)"

if [ -n "${BACKUP_REMOTE:-}" ]; then
  rclone copy "$out" "$BACKUP_REMOTE/" && echo "$(date -u) uploaded to $BACKUP_REMOTE"
fi

find "$BACKUP_DIR" -name 'funedu-*.dump.enc' -mtime +"$KEEP" -delete
