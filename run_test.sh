#!/bin/bash

export MYSQL_USER=avoid_lock_test
export MYSQL_PASS=avoid_lock_test
export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=43306
export MYSQL_VERSION=5.7.23
export DB=avoid_lock_test
DATABASE_YML=./database.yml


echo "Setup MySQL for test"
./setup_db.sh | tee setup_db.log

echo "Setting up $DATABASE_YML"
INSTALLED_PATH=$(cat setup_db.log | tail -n 1)
echo "test:" > $DATABASE_YML
echo "  database: $DB" >> $DATABASE_YML
echo "  adapter: mysql2" >> $DATABASE_YML
cat $INSTALLED_PATH/my.sandbox.cnf | grep -A 4 client | tail -n 4 | sed -e 's/  * = /: /' -e 's/^/  /' >> $DATABASE_YML
cat $DATABASE_YML
echo ""


echo "DONE!"

echo "Running test"
ruby avoid_lock.rb $INSTALLED_PATH/my.sandbox.cnf

echo "Tear down MySQL for test"
$INSTALLED_PATH/stop
