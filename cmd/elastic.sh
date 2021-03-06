#!/bin/bash
set -e;

function elastic_schema_drop(){ compose_run 'schema' node scripts/drop_index "$@" || true; }
register 'elastic' 'drop' 'delete elasticsearch index & all data' elastic_schema_drop

function elastic_schema_create(){ compose_run 'schema' ./bin/create_index; }
register 'elastic' 'create' 'create elasticsearch index with pelias mapping' elastic_schema_create

function elastic_schema_alias(){ compose_run 'schema' ./bin/alias; }
register 'elastic' 'alias' 'create or update an alias for the api index to point to the schema index (pelias.json api.indexName points to schema.indexName)' elastic_schema_alias

function elastic_start(){
  mkdir -p $DATA_DIR/elasticsearch
  # attemp to set proper permissions if running as root
  chown $DOCKER_USER $DATA_DIR/elasticsearch 2>/dev/null || true
  compose_exec up -d elasticsearch
}
register 'elastic' 'start' 'start elasticsearch server' elastic_start

function elastic_stop(){ compose_exec kill elasticsearch; }
register 'elastic' 'stop' 'stop elasticsearch server' elastic_stop

# to use this function:
# if test $(elastic_status) -ne 200; then
function elastic_status(){ curl --output /dev/null --silent --write-out "%{http_code}" "http://${ELASTIC_HOST:-localhost:9200}" || true; }

# the same function but with a trailing newline
function elastic_status_newline(){ echo $(elastic_status); }
register 'elastic' 'status' 'HTTP status code of the elasticsearch service' elastic_status_newline

function elastic_wait(){
  echo 'waiting for elasticsearch service to come up';
  retry_count=30

  i=1
  while [[ "$i" -le "$retry_count" ]]; do
    if [[ $(elastic_status) -eq 200 ]]; then
      echo
      exit 0
    fi
    sleep 2
    printf "."
    i=$(($i + 1))
  done

  echo
  echo "Elasticsearch did not come up, check configuration"
  exit 1
}

register 'elastic' 'wait' 'wait for elasticsearch to start up' elastic_wait

function elastic_aliases(){ curl --silent  "http://${ELASTIC_HOST:-localhost:9200}/_cat/aliases?v"; }
register 'elastic' 'aliases' 'show all elasticsearch aliases' elastic_aliases

function elastic_indices(){ curl --silent  "http://${ELASTIC_HOST:-localhost:9200}/_cat/indices?v"; }
register 'elastic' 'indices' 'show all elasticsearch indices' elastic_indices
