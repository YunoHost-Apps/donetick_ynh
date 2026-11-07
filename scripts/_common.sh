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
LOAD DATABASE
     FROM sqlite://$install_dir/donetick.db
     INTO postgresql://$db_user:$db_pwd@127.0.0.1:5432/$db_name

WITH include no drop, truncate, create no tables, create no indexes,
     preserve index names, no foreign keys, data only, workers = 8,
     concurrency = 1

CAST type json to text,
     type jsonb to text
;"

    ynh_safe_rm "$install_dir/donetick.db"

    if [ $initial_pgloader_install = false ]; then
        apt remove --autoremove -y pgloader
    fi
}
