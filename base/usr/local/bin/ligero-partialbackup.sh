#!/bin/bash
# Requirements
# - NICE
# - IONICE (liblinux-io-prio-perl no debian)

. /etc/ligero-backup.conf

BACKUP_PREFFIX="partialbackup_"
NAME="${BACKUP_PREFFIX}`(date +%Y-%m-%d_%H-%M)`"
TMP_BKP_DIR="$BACKUP_DIR/$NAME/tmp/"
CompressType=${CompressType:-gzip}

mkdir -p $TMP_BKP_DIR

# DON'T EXPORT DATA FROM THOSE TABLES
IGNORED_TABLES_STRING=''
for TABLE in "${EXCLUDED_TABLES[@]}"
do :
   IGNORED_TABLES_STRING+=" --ignore-table=${DATABASE}.${TABLE}"
done

IGNORED_YEARS_STRING=''
for YEAR in "${EXCLUDED_YEARS[@]}"
do :
   IGNORED_YEARS_STRING+=" --exclude=${PASTA_OTRS}/var/article/${YEAR} "
done

IGNORED_PATHS_STRING=''
for EXCLUDED_PATH in "${EXCLUDED_BACKUP_PATHS[@]}"
do :
   IGNORED_PATHS_STRING+=" --exclude=${EXCLUDED_PATH} "
done

START=`(date +%H:%M:%S\ %Y-%m-%d)`
echo "Backup started at $START"

rm $TMP_BKP_DIR/* -rf

echo "Copying Config.pm..."
mkdir -p $TMP_BKP_DIR/otrs/Kernel
cp /opt/otrs/Kernel/Config.pm $TMP_BKP_DIR/otrs/Kernel
echo "Done"

echo "Copying Config folder..."
cp /opt/otrs/Kernel/Config $TMP_BKP_DIR/otrs -R
echo "Done"

mkdir $TMP_BKP_DIR/otrs/var

sleep $DELAY
echo "Copying important var folders..."
cp /opt/otrs/var/log $TMP_BKP_DIR/otrs/var -R
cp /opt/otrs/var/run $TMP_BKP_DIR/otrs/var -R
cp /opt/otrs/var/sessions $TMP_BKP_DIR/otrs/var -R
cp /opt/otrs/var/spool $TMP_BKP_DIR/otrs/var -R
cp /opt/otrs/var/stats $TMP_BKP_DIR/otrs/var -R
echo "Done"

sleep $DELAY
mkdir $TMP_BKP_DIR/otrs/var/article
echo "Copying last $PARTIAL_DAYS day(s) articles..."
for ((i=0; i<=$PARTIAL_DAYS; i++))
do
    CAMINHO=`(date +%Y/%m/%d -d "$i day ago")`
    YEAR=`(date +%Y -d "$i day ago")`
    MONTH=`(date +%m -d "$i day ago")`
    ARTICLE_DIR_TO_CP=$TMP_BKP_DIR/otrs/var/article/$YEAR/$MONTH
    [[ ! -d "/opt/otrs/var/article/$CAMINHO" ]] && echo "$CAMINHO not found" && continue
    mkdir -p $ARTICLE_DIR_TO_CP
    nice -n 10 ionice -c2 -n7 cp /opt/otrs/var/article/$CAMINHO $ARTICLE_DIR_TO_CP -R
    echo "Day $i done"
    sleep $DELAY
done
echo "Last $PARTIAL_DAYS day(s) articles copied."

sleep $DELAY

echo "Dumping Database and compressing files..."
case $CompressType in
    bz2)
        #nice -n 10 ionice -c2 -n7 tar jcpf /app-backups/$NAME/DatabaseBackup.sql.bz2 -C $TMP_BKP_DIR/ DatabaseBackup.sql
        nice -n 10 ionice -c2 -n7 /opt/otrs/scripts/backup.pl -t dbonly -d /tmp -c bzip2
        mv /tmp/$YEAR-$MONTH-*/DatabaseBackup* /app-backups/$NAME
        nice -n 10 ionice -c2 -n7 tar jcpf /app-backups/$NAME/Application.tar.bz2 -C $TMP_BKP_DIR/otrs $IGNORED_PATHS_STRING .
        ;;
    gzip)
        #nice -n 10 ionice -c2 -n7 tar zcpf /app-backups/$NAME/DatabaseBackup.sql.gz -C $TMP_BKP_DIR/ DatabaseBackup.sql
        nice -n 10 ionice -c2 -n7 /opt/otrs/scripts/backup.pl -t dbonly -d /tmp -c gzip
        mv /tmp/$YEAR-$MONTH-*/DatabaseBackup* /app-backups/$NAME
        nice -n 10 ionice -c2 -n7 tar zcpf /app-backups/$NAME/Application.tar.gz -C $TMP_BKP_DIR/otrs $IGNORED_PATHS_STRING .
        ;;
esac

echo "Done"

#set permissions to otrs user
if [ "$USER" == "root" ]; then
    chown otrs:www-data -R /app-backups/$NAME
fi

echo "Removing temporary files..."
rm -rf $TMP_BKP_DIR
echo "Done"

END=`(date +%H:%M:%S\ %Y-%m-%d)`
echo "Partial Backup is done at $END!"

