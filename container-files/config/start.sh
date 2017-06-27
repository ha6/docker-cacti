#!/bin/sh
set -eu
export TERM=xterm
#Export default DB Password
export MYSQL_PWD=$DB_PASS
# Bash Colors
green=`tput setaf 2`
bold=`tput bold`
reset=`tput sgr0`
log() {
  if [[ "$@" ]]; then echo "${bold}${green}[LOG `date +'%T'`]${reset} $@";
  else echo; fi
}
move_cacti() {
    if [ -e "/cacti" ]; then
        log "Moving Cacti into Web Directory"
        rm -rf /var/www/html
        mv -f /cacti /var/www/html
        mkdir -p /var/www/html/log
	chown -R apache:apache /var/www
        log "Cacti moved"
    fi  
}
move_config_files() {
    if [ -e "/config.php" ]; then
        log "Moving Config files"
        mv -f /config.php /var/www/html/include/config.php
        mv -f /global.php /var/www/html/include/global.php
        chown -R apache:apache /var/www
        log "Config files moved"
    fi
}
create_db(){
    log "Creating Cacti Database"
    mysql -u $DB_USER -h $DB_ADDRESS -e "CREATE DATABASE  IF NOT EXISTS cacti DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    mysql -u $DB_USER -h $DB_ADDRESS -e "GRANT ALL ON cacti.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';"
    mysql -u $DB_USER -h $DB_ADDRESS -e "flush privileges;"
    log "Database created successfully"
}
import_db() {
    log "Importing Database..."
    mysql -u $DB_USER -h $DB_ADDRESS cacti < /var/www/html/cacti.sql
    log "Database Imported successfully"
}
spine_db_update() {
    log "Update databse with spine config details"
    mysql -u $DB_USER -h $DB_ADDRESS -e "REPLACE INTO cacti.settings SET name='path_spine', value='/usr/local/spine/bin/spine';"
    log "Database updated"
}
update_cacti_db_config() {
    log "Updating default Cacti config file"
    sed -i 's/$DB_ADDRESS/'$DB_ADDRESS'/g' /var/www/html/include/config.php
    sed -i 's/$DB_USER/'$DB_USER'/g' /var/www/html/include/config.php
    sed -i 's/$DB_PASS/'$DB_PASS'/g' /var/www/html/include/config.php
    log "Config file updated with Database credentials"
}
update_cacti_global_config() {
    log "Updating default Cacti global config file"
    sed -i 's/$DB_ADDRESS/'$DB_ADDRESS'/g' /var/www/html/include/global.php
    sed -i 's/$DB_USER/'$DB_USER'/g' /var/www/html/include/global.php
    sed -i 's/$DB_PASS/'$DB_PASS'/g' /var/www/html/include/global.php
    log "Config file updated with global Database credentials"
}
update_spine_config() {
    log "Updating Spine config file"
    if [ -e "/spine.conf" ]; then
    mv -f /spine.conf /usr/local/spine/etc/spine.conf
    sed -i 's/$DB_ADDRESS/'$DB_ADDRESS'/g' /usr/local/spine/etc/spine.conf
    sed -i 's/$DB_USER/'$DB_USER'/g' /usr/local/spine/etc/spine.conf
    sed -i 's/$DB_PASS/'$DB_PASS'/g' /usr/local/spine/etc/spine.conf
    log "Spine config updated"
    fi
    }
update_backup_config() {
    log "Updating backup config file"
    if [ -e "/bash/backup.sh" ]; then
    mv -f /bash/backup.sh /backup.sh
    sed -i 's/$DB_ADDRESS/'$DB_ADDRESS'/g' /backup.sh
    sed -i 's/$DB_USER/'$DB_USER'/g' /backup.sh
    sed -i 's/$DB_PASS/'$DB_PASS'/g' /backup.sh
    chmod +x /backup.sh
    log "backup config updated"
    fi
    }
update_export_config() {
    log "Updating export config file"
    if [ -e "/bash/export.sh" ]; then
    mv -f /bash/export.sh /export.sh
    sed -i 's/$DB_ADDRESS/'$DB_ADDRESS'/g' /export.sh
    sed -i 's/$DB_USER/'$DB_USER'/g' /export.sh
    sed -i 's/$DB_PASS/'$DB_PASS'/g' /export.sh
    chmod +x /export.sh
    log "export config updated"
    fi
    }
load_temple_config(){
    log "$(date +%F_%R) [New Install] Installing supporting template files."
       #cp -r /templates/resource /var/www/html
       #cp -r /templates/scripts /var/www/html

       # install additional templates
       for filename in /templates/*.xml; do
              echo "$(date +%F_%R) [New Install] Installing template file $filename"
              php -q /cacti/cli/import_template.php --filename=$filename > /dev/null
       done
}
change_auth_config(){
log "change export auth file"
sed -i "/include('.\/include\/auth.php');/a include('.\/include\/global.php');" /var/www/html/graph_xport.php
sed -i "s/include('.\/include\/auth.php');/#include('.\/include\/auth.php');/" /var/www/html/graph_xport.php
sed -i "/include('.\/include\/auth.php');/a include('.\/include\/global.php');" /var/www/html/graph_image.php
sed -i "s/include('.\/include\/auth.php');/#include('.\/include\/auth.php');/" /var/www/html/graph_image.php
log "export auth file changed"
}
update_cron() {
    log "Updating Cron jobs"
    # Add Cron jobs
    crontab /etc/import-cron.conf
    log "Crontab updated."
}
set_timezone() {
    if [[ $(grep "date.timezone = ${TIMEZONE}" /etc/php.ini) != "date.timezone = ${TIMEZONE}" ]]; then
        log "Updating TIMEZONE"
        echo "date.timezone = ${TIMEZONE}" >> /etc/php.ini
        log "TIMEZONE set to: ${TIMEZONE}"
    fi
}
start_crond() {
    crond
    log "Started cron daemon"
}
# ## Magic Starts Here
move_cacti
move_config_files
# Check Database Status and update if needed
if [[ $(mysql -u "${DB_USER}" -h "${DB_ADDRESS}" -e "show databases" | grep cacti) != "cacti" ]]; then
    create_db
    import_db
    spine_db_update
fi
# Update Cacti config
update_cacti_db_config
update_cacti_global_config
update_spine_config
update_backup_config
update_export_config
#load_temple_config
update_cron
set_timezone
start_crond
/usr/bin/supervisord
log "Cacti Server UP."
