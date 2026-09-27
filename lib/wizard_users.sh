# =============================================================================
#  AMMSIS — lib/wizard_users.sh
#  Interactive wizard for Local Users
# =============================================================================

validate_linux_name() {
    local value="$1"
    if [[ "$value" =~ ^[a-z_][a-z0-9_-]*\$?$ ]]; then
        return 0
    fi
    log_error "Il nome '${value}' non è un nome utente Linux valido."
    return 1
}

yaml_quote() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    echo "\"$str\""
}

collect_local_users_config() {
    echo -e "\n${CLR_BOLD}=== Configurazione Utenti Locali ===${CLR_RESET}"
    if ! prompt_confirm "Vuoi configurare degli utenti locali aggiuntivi?"; then
        return
    fi
    
    _build_all_hosts_list
    
    while true; do
        if ! prompt_confirm "Vuoi aggiungere un utente locale?"; then
            break
        fi
        
        local target_host uname gecos uid group gid sec_groups shell home create_home pass sudo sudo_nopw
        
        prompt_single_select_host "Su quale host?" target_host ALL_HOSTS
        
        while true; do
            prompt_input "  Username" uname
            if validate_linux_name "$uname"; then
                break
            fi
        done
        
        prompt_input "  GECOS / Commento" gecos "Local user $uname"
        prompt_input "  UID (lascia vuoto per auto)" uid ""
        prompt_input "  Gruppo principale" group "$uname"
        prompt_input "  GID del gruppo (lascia vuoto per auto)" gid ""
        prompt_input "  Gruppi secondari (separati da virgola)" sec_groups ""
        prompt_input "  Shell" shell "/bin/bash"
        prompt_input "  Home directory" home "/home/$uname"
        
        if prompt_confirm "  Creare la home directory?"; then
            create_home="yes"
        else
            create_home="no"
        fi
        
        prompt_input "  Password (in chiaro, verrà hashata)" pass "$uname"
        
        if prompt_confirm "  Abilitare permessi sudo?"; then
            sudo="yes"
            if prompt_confirm "    Senza richiesta password (NOPASSWD)?"; then
                sudo_nopw="yes"
            else
                sudo_nopw="no"
            fi
        else
            sudo="no"
            sudo_nopw="no"
        fi
        
        LOCAL_USERS+=("${target_host}|${uname}|${gecos}|${uid}|${group}|${gid}|${sec_groups}|${shell}|${home}|${create_home}|${pass}|${sudo}|${sudo_nopw}")
    done
}
