# =============================================================================
#  AMMSIS — lib/choices.sh
#  Functions for saving and loading user choices
# =============================================================================

save_choices() {
    local file="$1"
    {
        echo "# Configurazione AMMSIS generata automaticamente"
        echo "# Data: $(date)"
        declare -p NUM_ROUTERS ROUTER_IPS ROUTER_NETS ROUTER_IFACES ROUTER_IFACE_IDS 2>/dev/null || true
        declare -p NUM_CLIENTS CLIENT_IPS CLIENT_NETS CLIENT_IFACES CLIENT_IFACE_IDS CLIENT_SUBNET_CIDR CLIENT_SUBNET_MASK CLIENT_NET_MODE 2>/dev/null || true
        declare -p NUM_SERVERS SERVER_IPS SERVER_NETS SERVER_IFACES SERVER_IFACE_IDS SERVER_SUBNET_CIDR SERVER_SUBNET_MASK SERVER_NET_MODE 2>/dev/null || true
        declare -p CLIENT_DHCP_NETWORK CLIENT_DHCP_NET_ADDR CLIENT_DHCP_RANGE_START CLIENT_DHCP_RANGE_END CLIENT_DHCP_SERVER_ROUTE 2>/dev/null || true
        declare -p SERVER_DHCP_NETWORK SERVER_DHCP_NET_ADDR SERVER_DHCP_RANGE_START SERVER_DHCP_RANGE_END SERVER_DHCP_CLIENT_ROUTE 2>/dev/null || true
        declare -p ROUTER_DHCP_CLIENT_NETWORK ROUTER_DHCP_CLIENT_NET_ADDR ROUTER_DHCP_CLIENT_RANGE_START ROUTER_DHCP_CLIENT_RANGE_END 2>/dev/null || true
        declare -p ROUTER_DHCP_SERVER_NETWORK ROUTER_DHCP_SERVER_NET_ADDR ROUTER_DHCP_SERVER_RANGE_START ROUTER_DHCP_SERVER_RANGE_END 2>/dev/null || true
        declare -p USE_PROXY_LAB 2>/dev/null || true
        declare -p USE_SSH_PASSWORDLESS_CLIENTS USE_SSH_PASSWORDLESS_SERVERS SSH_PASSWORDLESS_CLIENT_USER SSH_PASSWORDLESS_SERVER_USER 2>/dev/null || true
        declare -p USE_LDAP LDAP_SERVER_HOST LDAP_DOMAIN LDAP_ORG LDAP_ADMIN_PASSWORD LDAP_BASE_DN LDAP_ADMIN_DN LDAP_CLIENT_HOSTS LDAP_RW_HOSTS LDAP_USERS LDAP_GROUPS LDAP_STANDALONE_GROUPS LOCAL_USERS 2>/dev/null || true
        declare -p LDAP_CRED_SEPARATE LDAP_CRED_FILENAME LDAP_CRED_PATH LDAP_CRED_ADMIN_USER LDAP_CRED_HOSTS 2>/dev/null || true
        declare -p USE_SNMP SNMP_AGENT_HOSTS SNMP_AGENT_EXTENDS SNMP_MANAGER_HOSTS SNMP_CUSTOM_COMMUNITY SNMP_CUSTOM_VIEW 2>/dev/null || true
        declare -p USE_LOGGER LOGGER_HOSTS LOGGER_FACILITY LOGGER_FILE_PATH 2>/dev/null || true
        declare -p USE_CRON CRON_JOBS CRON_HOST CRON_AT_REBOOT CRON_MINUTE CRON_HOUR CRON_DOW CRON_USER 2>/dev/null || true
        declare -p ALL_HOSTS 2>/dev/null || true
    } > "$file"
    log_info "Scelte utente salvate in: $file"
}

load_choices() {
    local file="$1"
    log_info "Caricamento scelte da: $file"
    # `declare -p` produce istruzioni "declare -a ..." / "declare -- ...".
    # Quando vengono eseguite con `source` **dentro una funzione**, Bash le
    # tratta come variabili LOCALI, lasciando vuoti gli array globali.
    # Soluzione: iniettiamo il flag -g in ogni `declare` prima del source,
    # così le variabili vengono impostate nello scope globale.
    local tmp_file
    tmp_file="$(mktemp)"
    sed -e 's/^declare -- /declare -g /' -e 's/^declare -\([^g]\)/declare -g\1/' "$file" > "$tmp_file"
    # shellcheck source=/dev/null
    source "$tmp_file"
    rm -f "$tmp_file"
    _build_all_hosts_list
}

migrate_legacy_cron_config() {
    if [[ "$USE_CRON" == true ]] && (( ${#CRON_JOBS[@]} == 0 )) && [[ -n "$CRON_HOST" ]]; then
        CRON_JOBS+=("${CRON_HOST}|${CRON_AT_REBOOT}|true|${CRON_MINUTE}|${CRON_HOUR}|${CRON_DOW}|${CRON_USER}|/path/da/configurare|")
        log_warn "Configurazione Cron v3 rilevata: migrata al formato multi-job."
    fi
}
