#!/usr/bin/env bash
# Nightly backup -> Backblaze B2 (immutable bucket). Pushover alert on failure.
# Reads B2_BUCKET / B2_PREFIX / PUSHOVER_* from /etc/server-security/config.
#
# ►►► CUSTOMIZE the do_backup() block at the bottom for THIS server's data. ◄◄◄
# Helpers available: dump_mysql_all | dump_mysql_db <db> | dump_postgres_all |
#                    backup_sqlite <path> | add_file <path> | add_dir <dir>
set -euo pipefail
source /etc/server-security/config
: "${B2_BUCKET:?}"; : "${PUSHOVER_TOKEN:?}"; : "${PUSHOVER_USER:?}"
PREFIX="${B2_PREFIX:-$(hostname -s)}"

HOST="$(hostname -s)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
DATE_PATH="$(date -u +%Y/%m/%d)"
WORK="$(mktemp -d /tmp/b2backup.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

pushover() {
  curl -s --max-time 15 \
    --form-string "token=${PUSHOVER_TOKEN}" --form-string "user=${PUSHOVER_USER}" \
    --form-string "title=$1" --form-string "message=$2" --form-string "priority=1" \
    https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true
}
fail() { echo "ERROR: $1" >&2; pushover "B2 BACKUP FAILED on ${HOST}" "$1"; exit 1; }

# ---- helpers (write into $WORK) ----
dump_mysql_all()  { mariadb-dump --single-transaction --quick --routines --events --all-databases 2>/dev/null | gzip > "$WORK/mysql-all.sql.gz" || fail "mysqldump --all-databases failed"; [ -s "$WORK/mysql-all.sql.gz" ] || fail "mysql-all dump empty"; }
dump_mysql_db()   { local db="$1"; mariadb-dump --single-transaction --quick --routines --events "$db" 2>/dev/null | gzip > "$WORK/mysql-${db}.sql.gz" || fail "mysqldump $db failed"; [ -s "$WORK/mysql-${db}.sql.gz" ] || fail "mysql $db dump empty"; }
dump_postgres_all(){ sudo -u postgres pg_dumpall 2>/dev/null | gzip > "$WORK/postgres-all.sql.gz" || fail "pg_dumpall failed"; [ -s "$WORK/postgres-all.sql.gz" ] || fail "postgres dump empty"; }
backup_sqlite()   { local p="$1" n; n="$(basename "$p")"; command -v sqlite3 >/dev/null || apt-get install -y sqlite3 >/dev/null 2>&1; sqlite3 "$p" ".backup '$WORK/${n}'" || fail "sqlite backup $p failed"; gzip "$WORK/${n}"; }
add_file()        { local p="$1"; mkdir -p "$WORK/files"; cp "$p" "$WORK/files/$(echo "$p" | sed 's#^/##; s#/#_#g')" || fail "copy $p failed"; }
add_dir()         { local d="$1" n; n="$(echo "$d" | sed 's#^/##; s#/#_#g')"; tar czf "$WORK/dir-${n}.tar.gz" -C "$(dirname "$d")" "$(basename "$d")" 2>/dev/null || true; }

upload_bundle() {
  local bundle="${HOST}-backup-${TS}.tar.gz"
  ( cd "$WORK" && tar czf "$bundle" --exclude="$bundle" ./* ) || fail "bundling failed"
  local size; size="$(du -h "$WORK/$bundle" | cut -f1)"
  rclone copy "$WORK/$bundle" "${B2_BUCKET}/${PREFIX}/backups/${DATE_PATH}/" --no-check-dest 2>&1 || fail "rclone upload of $bundle failed"
  echo "$(date -u +%FT%TZ) OK ${PREFIX}/backups/${DATE_PATH}/${bundle} (${size})"
}

# ============================================================================
# ►►► EDIT THIS for the server. Call the helpers you need, then upload_bundle.
# Example: a MariaDB app database + a SQLite app + two .env files.
# ============================================================================
do_backup() {
  # dump_mysql_all
  # dump_mysql_db myapp
  # backup_sqlite /srv/myapp/database/database.sqlite
  # add_file /srv/myapp/.env
  # add_file /srv/otherapp/.env
  # add_dir  /srv/myapp/storage/app
  echo "!! do_backup() is empty — edit $0 to back up this server's data" >&2
  fail "do_backup() not customized for ${HOST}"
}

do_backup
upload_bundle
