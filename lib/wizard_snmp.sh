# =============================================================================
#  AMMSIS — lib/wizard_snmp.sh
#  Interactive wizard for SNMP
# =============================================================================

collect_snmp_config() {
    echo -e "\n${CLR_BOLD}=== Configurazione SNMP ===${CLR_RESET}"
    if ! prompt_confirm "Vuoi configurare SNMP?"; then
        USE_SNMP=false
        return
    fi
    
    USE_SNMP=true
    _build_all_hosts_list
    
    prompt_multi_select_hosts "Quali host saranno AGENTI SNMP?" SNMP_AGENT_HOSTS ALL_HOSTS
    
    local agent
    for agent in "${SNMP_AGENT_HOSTS[@]}"; do
        if prompt_confirm "Vuoi configurare OID custom (extend) su ${agent}?"; then
            while true; do
                if ! prompt_confirm "  Aggiungere un extend su ${agent}?"; then
                    break
                fi
                
                local ext_name ext_cmd
                prompt_input "    Nome dell'extend (es. load, status)" ext_name
                prompt_input "    Comando da eseguire" ext_cmd
                SNMP_AGENT_EXTENDS+=("${agent}:${ext_name}:${ext_cmd}")
            done
        fi
    done
    
    prompt_input "Community string (default: public se vuoto)" SNMP_CUSTOM_COMMUNITY "public"
    prompt_input "View name (default: all se vuoto)" SNMP_CUSTOM_VIEW "all"
    
    prompt_multi_select_hosts "Quali host saranno MANAGER SNMP?" SNMP_MANAGER_HOSTS ALL_HOSTS
}
