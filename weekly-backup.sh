#!/bin/bash
##################################################################
# Purpose: Take a backup of given wordpress website with database
# Owner: Sunil Gadgil <info@tejoyasha.com>
# Version: 1.0
# Input: Wordpress website list
# Output: Push the output to google drive
##################################################################

WEBLIST=$1

if [ ! "$WEBLIST" ]; then
 echo "Usage: $0 <filename>"
 exit
fi

if [ ! -f "$WEBLIST" ]; then
  echo "Please enter the correct filename"
  exit
fi

if [ ! -f /usr/local/bin/gdrive ]; then
  echo "Google Drive program not available ....."
  exit
fi

WHOAMI=$(/usr/bin/whoami)

if [ "$WHOAMI" != "root" ]; then
  echo "You MUST be a root user..."
  exit
fi

for LINE in `cat $WEBLIST`
do
  WEBSITE=$(echo $LINE | awk -F: '{print $1}')
  DB=$(echo $LINE | awk -F: '{print $2}')
  TODAY=$(date +%d-%b-%Y)

  /usr/local/bin/gdrive list | grep "$WEBSITE-$TODAY.tar.gz"

  if [ "$?" -eq 0 ]; then
    echo "Backup for $WEBSITE-$TODAY.tar.gz already exists"
  else 
    cd /backup
    rm -rf "$WEBSITE"
    mkdir -p "$WEBSITE/site"
    cd "$WEBSITE/site"
    cp -Rp "/var/www/$WEBSITE"  .
    mkdir ../db
    cd ../db
    mysqldump -u root -p$MYPASS "$DB" > "$DB.sql"
    cd ..

    tar cf "$WEBSITE-$TODAY.tar" site db
    gzip "$WEBSITE-$TODAY.tar"

    /usr/local/bin/gdrive upload --no-progress --delete "$WEBSITE-$TODAY.tar.gz"  
    if [ "$?" -ne 0 ]; then
      echo "Failed Backup for $WEBSITE-$TODAY.tar.gz"
    else
      echo "Successful Backup of $WEBSITE-$TODAY.tar.gz"
    fi
    cd ..
    rm -rf "$WEBSITE"
 fi
done
