# =============================================================================
#  AMMSIS — lib/wizard_logger.sh
#  Interactive wizard for syslog/logger
# =============================================================================

collect_logger_config() {
    echo -e "\n${CLR_BOLD}=== Configurazione Syslog Centrale ===${CLR_RESET}"
    if ! prompt_confirm "Vuoi configurare un LOGGER (server rsyslog centrale)?"; then
        USE_LOGGER=false
        return
    fi
    
    USE_LOGGER=true
    _build_all_hosts_list
    
    prompt_multi_select_hosts "Quali host fungeranno da LOGGER (ricevono i log)?" LOGGER_HOSTS ALL_HOSTS
    
    prompt_input "Inserisci la facility.priority (es. local1.info, auth.warn)" LOGGER_FACILITY "local1.info"
    prompt_input "Percorso assoluto del file di log (es. /var/log/custom.log)" LOGGER_FILE_PATH "/var/log/syslog"
}
