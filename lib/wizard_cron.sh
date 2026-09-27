# =============================================================================
#  AMMSIS — lib/wizard_cron.sh
#  Interactive wizard for Cron
# =============================================================================

collect_cron_config() {
    echo -e "\n${CLR_BOLD}=== Configurazione Cron Jobs ===${CLR_RESET}"
    if ! prompt_confirm "Vuoi configurare dei job Cron?"; then
        USE_CRON=false
        return
    fi
    
    USE_CRON=true
    _build_all_hosts_list
    
    while true; do
        if ! prompt_confirm "Vuoi aggiungere un job Cron?"; then
            break
        fi
        
        local hosts_arr hosts_str cmd boot seconds periodic c_min c_hour c_dow c_user c_sec
        
        prompt_multi_select_hosts "Su quali host eseguire il job?" hosts_arr ALL_HOSTS
        
        # Unisci array di host
        hosts_str=""
        local h
        for h in "${hosts_arr[@]}"; do
            if [[ -z "$hosts_str" ]]; then
                hosts_str="$h"
            else
                hosts_str="${hosts_str},${h}"
            fi
        done
        
        prompt_input "  Comando da eseguire" cmd
        
        if prompt_confirm "  Eseguire al boot (@reboot)?"; then
            boot="true"
        else
            boot="false"
        fi
        
        if prompt_confirm "  Eseguire a intervalli di secondi?"; then
            seconds="true"
            prompt_input "    Ogni quanti secondi?" c_sec "30"
            c_min="*"
            c_hour="*"
            prompt_input "    Giorni (es. *, 1-5, mon-fri)" c_dow "*"
            periodic="false"
        else
            seconds="false"
            c_sec=""
            if prompt_confirm "  Eseguire periodicamente (min/hour/day)?"; then
                periodic="true"
                prompt_input "    Minuto (es. *, 0-59, */5)" c_min "*"
                prompt_input "    Ora (es. *, 0-23, */2)" c_hour "*"
                prompt_input "    Giorno/i (es. *, 1-5, mon-fri)" c_dow "*"
            else
                periodic="false"
                c_min=""
                c_hour=""
                c_dow=""
            fi
        fi
        
        if [[ "$boot" == "false" && "$seconds" == "false" && "$periodic" == "false" ]]; then
            log_warn "Nessuna modalità di attivazione selezionata. Job saltato."
            continue
        fi
        
        prompt_input "  Utente che esegue il comando" c_user "root"
        
        # Serializzazione in CRON_JOBS
        CRON_JOBS+=("${hosts_str}|${boot}|${periodic}|${c_min}|${c_hour}|${c_dow}|${c_user}|${cmd}|${c_sec}")
    done
}
