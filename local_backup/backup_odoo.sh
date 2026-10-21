#!/bin/bash

#	NUEVO SCRIPT - VERSION PROD
# file: backup_odoo.sh

set -euo pipefail

# Variables
BACKUP_DIR="/root/backup"
DB_NAME="odoo"
OUTPUT_FILE="${BACKUP_DIR}/odoo_db_${DB_NAME}.zip"
SOURCE_FILE="/mnt/c/Users/drodriguez/Documents/dockerdoo19/custom/odoo_db_${DB_NAME}.zip"
CONTAINER="dockerdoo19-odoo-1"

LOG_DIR="/root/backup/logs"
LOG_FILE="${LOG_DIR}/backup_odoo.log"
mkdir -p "$BACKUP_DIR" "$LOG_DIR"
touch "$LOG_FILE"


START_TIME=$(date +%s)
FROM_EMAIL="Notificaciones // Solvos <notificaciones@solvos.es>"
TO_EMAIL="sistemas@solvos.es"
EXIT_CODE=0
STATUS="OK"
DURATION=0
MESSAGE=""

# Crear backup
mkdir -p "$BACKUP_DIR"
cd ${BACKUP_DIR}

if ! docker exec -i "$CONTAINER" bash < /root/backup/scripts/backup-odoo-click.sh; then
    STATUS="ERROR"
    MESSAGE="Error ejecutando backup dentro del contenedor Docker."
    EXIT_CODE=1
fi

if [ "$STATUS" = "OK" ]; then
    if [ -f "$SOURCE_FILE" ]; then
        mv "$SOURCE_FILE" "$OUTPUT_FILE"
    else
        STATUS="ERROR"
        MESSAGE="No se encontró el archivo de backup generado."
        EXIT_CODE=1
    fi
fi

#### Verificar integridad
if [ "$STATUS" = "OK" ] && unzip -t "$OUTPUT_FILE" >/dev/null 2>&1; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

    MESSAGE=$(cat <<EOF
Estado ejecución: OK
Fecha: $(date)
Base de datos: $DB_NAME
Nombre fichero: $(basename "$OUTPUT_FILE")
Duración: ${DURATION} segundos
Tamaño: ${SIZE}
EOF
)

else
    STATUS="ERROR"
    MESSAGE=$(cat <<EOF
Estado ejecución: ERROR
Fecha: $(date)
Base de datos: $DB_NAME
Nombre fichero: $(basename "$OUTPUT_FILE")
ERROR: El archivo de backup está corrupto o incompleto.
EOF
)
    EXIT_CODE=1
fi

{
    echo "======================================"
    echo "Fecha: $(date)"
    echo "Base de datos: $DB_NAME"
    echo "Estado: $STATUS"
    echo "Archivo destino: $OUTPUT_FILE"
    echo "Duración: ${DURATION} segundos"
    echo "======================================"
} >> "$LOG_FILE"

printf "From: %s\nTo: %s\nSubject: Backup %s %s\nContent-Type: text/plain; charset=UTF-8\n\n%s\n" "$FROM_EMAIL" "$TO_EMAIL" "$DB_NAME" "$STATUS" "$MESSAGE" | msmtp "$TO_EMAIL"
exit ${EXIT_CODE}