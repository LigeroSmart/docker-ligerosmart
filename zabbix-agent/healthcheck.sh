#!/bin/bash

# exit on error
set -o errexit

ping -c 1 $MYSQL_HOST > /dev/null

mariadb --skip-ssl -BN -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD -e '/* ping */  SELECT 1' $MYSQL_DATABASE > /dev/null
