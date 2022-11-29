#!/bin/bash

mysqld --datadir=/var/lib/mysql-no-volume/data > /dev/null 2>&1 &

query="$@"

# reformat the digest to match what vividcortex does
function normalize_digest_text_like_vividcortex() {
  digest=$1

  # convert to lowercase
  digest=$(echo "$digest" | tr '[:upper:]' '[:lower:]')

  # SELECT `user` . `id`  =>  SELECT `user`.`id`
  digest=$(echo "$digest" | sed -e 's/` \. `/`.`/g')

  # SELECT `user` . *  =>  SELECT `user`.*
  digest=$(echo "$digest" | sed -e 's/` \. \*/`.*/g')

  # WHERE `foo` = ?  =>  WHERE `foo`=?
  digest=$(echo "$digest" | sed -e 's/ \([<=>]\+\) /\1/g')

  # AND ( `foo` = ? )  =>  AND (`foo`=?)
  digest=$(echo "$digest" | sed -e 's/ )/)/g')       
  digest=$(echo "$digest" | sed -e 's/( /(/g')

  # `field`=false  => `field`=?
  digest=$(echo "$digest" | sed -e 's/=\(false\|true\)/=?/g')

  # digests are truncated
  digest=${digest:0:1024}

  echo -n "$digest"

  return 0
}

function generate_vividcortex_id() {
  vividcortex_digest_text=$1

  # mysql/VC truncates digest text at 1024 chars
  md5=$(echo -n "${vividcortex_digest_text:0:1024}" | md5sum)
  
  # vividcortex ids only use the first 16 chars of the md5 sum
  echo "${md5:0:16}"
  return 0
}

until _=$(mysql -e "SELECT 1" 2>&1 > /dev/null)
do
  #echo "Waiting for database connection..."
  # wait for 5 seconds before check again
  sleep 5
done

set +e
_=$(mysql -e "CREATE DATABASE IF NOT EXISTS test_db" 2>&1)

_=$(mysql -e "TRUNCATE performance_schema.events_statements_summary_by_digest; $query;" test_db 2>&1)

mysql_digest_text=$(mysql -sN -e "SELECT digest_text FROM performance_schema.events_statements_summary_by_digest WHERE schema_name='test_db' AND digest_text NOT LIKE 'TRUNCATE %' LIMIT 1")

echo "$mysql_digest_text"
echo "mysql_digest_text=$mysql_digest_text" >> $GITHUB_OUTPUT

vividcortex_digest_text=$(normalize_digest_text_like_vividcortex "$mysql_digest_text")
echo "$vividcortex_digest_text"
echo "vividcortex_digest_text=$vividcortex_digest_text" >> $GITHUB_OUTPUT

vividcortex_digest_id=$(generate_vividcortex_id "$vividcortex_digest_text")
echo "$vividcortex_digest_id"
echo "vividcortex_digest_id=$vividcortex_digest_id" >> $GITHUB_OUTPUT

