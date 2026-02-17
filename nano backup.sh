#!/usr/bin/env bash
set -euo pipefail

echo "📦 Iniciando backup de PostgreSQL..."

# 1) Validar variables requeridas
: "${DATABASE_URL:?DATABASE_URL no está definida}"
: "${R2_ACCESS_KEY_ID:?R2_ACCESS_KEY_ID no está definida}"
: "${R2_SECRET_ACCESS_KEY:?R2_SECRET_ACCESS_KEY no está definida}"
: "${R2_ENDPOINT:?R2_ENDPOINT no está definido}"            # ej: https://<accountid>.r2.cloudflarestorage.com
: "${R2_BUCKET:?R2_BUCKET no está definido}"                # ej: verifirma-backups

# 2) Parsear DATABASE_URL → PG* vars
# Formato: postgres://user:pass@host:port/dbname
DB_URL="$DATABASE_URL"
DB_USER=$(echo "$DB_URL" | sed -E 's#^postgres://([^:]+):.*@\S+/\S+#\1#')
DB_PASS=$(echo "$DB_URL" | sed -E 's#^postgres://[^:]+:([^@]+)@\S+/\S+#\1#')
DB_HOST=$(echo "$DB_URL" | sed -E 's#^postgres://[^@]+@([^:/]+):?[0-9]*/\S+#\1#')
DB_NAME=$(echo "$DB_URL" | sed -E 's#^postgres://[^@]+@[^/]+/(\S+)#\1#')
DB_PORT=$(echo "$DB_URL" | sed -E 's#^postgres://[^@]+@[^:]+:([0-9]+)/\S+#\1#')

DB_PORT=${DB_PORT:-5432}

export PGPASSWORD="$DB_PASS"

TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
FILENAME="verifirma-backup-${TIMESTAMP}.dump"

echo "👤 USER: $DB_USER"
echo "🗄  HOST: $DB_HOST"
echo "🗃  DB: $DB_NAME"
echo "⏱  Timestamp: $TIMESTAMP"

# 3) Crear dump en formato custom (-Fc)
pg_dump \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -Fc \
  -f "$FILENAME"

echo "✅ Dump creado: $FILENAME"

# 4) Subir a R2 vía awscli compatible S3
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"

R2_PATH="s3://${R2_BUCKET}/postgres/${FILENAME}"

echo "☁️ Subiendo a R2: $R2_PATH"

aws s3 cp "$FILENAME" "$R2_PATH" \
  --endpoint-url "$R2_ENDPOINT" \
  --storage-class STANDARD

echo "✅ Backup subido a R2 correctamente"

# 5) Limpiar archivo local
rm -f "$FILENAME"
echo "🧹 Archivo local eliminado"
