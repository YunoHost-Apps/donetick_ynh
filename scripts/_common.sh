#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

_migrate_sqlite_to_psql() {
    ynh_print_info "Migrating to PostgreSQL database..."

    if [ ! -f "$install_dir/donetick.db" ]; then
        ynh_print_warn "SQLite DB not found, cancelling migration."
        return
    fi

    if dpkg -l "pgloader" &> /dev/null; then
        initial_pgloader_install=true
    else 
        initial_pgloader_install=false
        apt update
        apt install -y pgloader
    fi

    pgloader /dev/stdin <<< "
load database
     from sqlite://$install_dir/donetick.db
     into postgresql://$db_user:$db_pwd@127.0.0.1:5432/$db_name

cast
     column chores.frequency_meta_v2 to text
     column chores.notification_meta_v2 to text
     column filters.conditions to text
     column notifications.raw_event to text
     column time_sessions.pause_log to text

with include no drop, truncate, create no tables, create no indexes,
     preserve index names, no foreign keys, data only, workers = 8,
     concurrency = 1
;"

    ynh_safe_rm "$install_dir/donetick.db"

    if [ $initial_pgloader_install = false ]; then
        apt remove --autoremove -y pgloader
    fi
}
