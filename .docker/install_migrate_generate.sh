#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs)

echo "Installing the service file"
docker cp pg_service.conf qgis:/etc/postgresql-common/

echo "Installation from version ${INSTALL_VERSION}"
docker exec qgis bash -c "psql service=test -c 'DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE;'" > /dev/null
docker exec qgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/test/data/install/sql/00_initialize_database.sql" > /dev/null
for sql_file in `ls -v ../${PLUGIN_NAME}/test/data/install/sql/${SCHEMA}/*.sql`; do
  echo "${sql_file}"
  docker exec qgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/${sql_file}" > /dev/null;
  done;

echo 'Run migrations'
for migration in `ls -v ../${PLUGIN_NAME}/install/sql/upgrade/*.sql`; do
  echo "${migration}"
  docker exec qgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/${migration}" > /dev/null;
  done;

echo 'Generate doc'
docker exec qgis bash -c "apt-get install -y rename" > /dev/null
docker exec qgis bash -c "cd /tests_directory/${PLUGIN_NAME}/install/sql/ && ./export_database_structure_to_SQL.sh test ${SCHEMA}"
docker exec qgis bash -c "cd /tests_directory/${PLUGIN_NAME}/install/sql/${SCHEMA} && chmod 777 *.sql"

git diff
[[ -z $(git status -s) ]]
exit $?
