#!/bin/bash
set -euo pipefail

PROD_PATH="/mnt/c/Users/drodriguez/Documents/dockerdoo19"
PRE_PATH="/mnt/c/Users/drodriguez/Documents/dockerdoo19-pre"

PROD_CONTAINER="dockerdoo19-odoo-1"
PRE_PROD_CONTAINER="dockerdoo19-pre-odoo-1"

PROD_DB="odoo"
PRE_DB="odoo"

DUMP="odoo_db_refresh.zip"

echo "==== REFRESH PREPROD ===="
# 1. Generar backup de Prod
echo "Backup PROD..."
cd $PROD_PATH
rm -f custom/$DUMP
docker exec -i -u 0 "$PROD_CONTAINER" bash -c "click-odoo-backupdb -c \$ODOO_RC $PROD_DB /mnt/extra-addons/$DUMP"

# 2 SINCRONIZAR CUSTOM
echo "Sincronizando código..."
mv ${PROD_PATH}/custom/${DUMP} ${PRE_PATH}/custom/
rsync -av ${PROD_PATH}/custom/ ${PRE_PATH}/custom/

# 3 BORRADO BDD Y REINICIO DE ODOO
echo "Borrando base de datos PRE..."
cd $PRE_PATH
docker exec -i "$PRE_PROD_CONTAINER" bash -c "click-odoo-dropdb -c \$ODOO_RC $PRE_DB --if-exists"
docker-compose down
docker-compose up -d
echo "Esperando odoo"
until curl -sSf http://localhost:8669/web/database/selector >/dev/null; do
    echo "No operativo, reintentando en 5 segundos"
    sleep 5
done


# 4 RESTAURAR EN PRE (CON ODOO ARRANCADO)
echo "Restaurando base de datos..."
docker exec -i "$PRE_PROD_CONTAINER" bash -c "click-odoo-restoredb -c \$ODOO_RC $PRE_DB /mnt/extra-addons/$DUMP"
docker-compose down

# 5 ARRANCAR PREPROD COMPLETO
echo "Arrancando PREPROD..."
docker-compose up -d
# 6 ESPERAR ODOO
echo "Esperando odoo"
until curl -sSf http://localhost:8669/web/login >/dev/null; do
    echo "No operativo, reintentando en 5 segundos"
    sleep 5
done

# 7 NEUTRALIZAR
echo "Neutralizando..."
docker exec -i "$PRE_PROD_CONTAINER" odoo shell -d "$PRE_DB" --no-http < /mnt/c/Users/drodriguez/Documents/scripts/update_pre/neutralize_odoo_shell.py
echo "Neutralización aplicada"
rm -f custom/$DUMP

# 8 REINICIO LIMPIO
docker-compose down
docker-compose up -d

echo "REFRESH FINALIZADO"