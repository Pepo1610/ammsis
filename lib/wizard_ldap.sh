# =============================================================================
#  AMMSIS — lib/wizard_ldap.sh
#  Interactive wizard for LDAP configuration
# =============================================================================

domain_to_base_dn() {
    local domain="$1"
    local dn=""
    local part
    for part in ${domain//./ }; do
        if [[ -z "$dn" ]]; then
            dn="dc=$part"
        else
            dn="$dn,dc=$part"
        fi
    done
    echo "$dn"
}

collect_ldap_config() {
    echo -e "\n${CLR_BOLD}=== Configurazione LDAP ===${CLR_RESET}"
    if ! prompt_confirm "Vuoi configurare LDAP?"; then
        USE_LDAP=false
        return
    fi
    
    USE_LDAP=true
    _build_all_hosts_list
    
    prompt_single_select_host "Quale host sarà il SERVER LDAP?" LDAP_SERVER_HOST ALL_HOSTS
    
    if prompt_confirm "Vuoi usare un file di credenziali admin separato?"; then
        LDAP_CRED_SEPARATE=true
        prompt_input "  Nome del file" LDAP_CRED_FILENAME "ldap.admin.cred"
        prompt_input "  Percorso destinazione" LDAP_CRED_PATH "/etc/"
        prompt_input "  Username admin" LDAP_CRED_ADMIN_USER "admin"
        prompt_multi_select_hosts "Su quali host distribuire il file credenziali?" LDAP_CRED_HOSTS ALL_HOSTS
    else
        LDAP_CRED_SEPARATE=false
    fi
    
    prompt_multi_select_hosts "Quali host saranno CLIENT LDAP (login centralizzato)?" LDAP_CLIENT_HOSTS ALL_HOSTS "$LDAP_SERVER_HOST"
    
    prompt_multi_select_hosts "Quali host avranno permessi RW sul server LDAP?" LDAP_RW_HOSTS ALL_HOSTS
    
    prompt_input "Dominio LDAP (es. labammsis.it)" LDAP_DOMAIN "labammsis"
    prompt_input "Organizzazione" LDAP_ORG "Unibo"
    prompt_input "Password di admin" LDAP_ADMIN_PASSWORD "admin_password"
    
    LDAP_BASE_DN=$(domain_to_base_dn "$LDAP_DOMAIN")
    LDAP_ADMIN_DN="cn=${LDAP_CRED_ADMIN_USER:-admin},${LDAP_BASE_DN}"
    
    echo -e "\n  ${CLR_BOLD}Utenti LDAP${CLR_RESET}"
    while true; do
        if ! prompt_confirm "Vuoi aggiungere un utente LDAP?"; then
            break
        fi
        
        local uid cn sn uidNumber gidNumber group home shell pass descr gecos
        
        prompt_input "  Username (uid)" uid
        prompt_input "  Nome (cn)" cn "$uid"
        prompt_input "  Cognome (sn)" sn "$uid"
        prompt_input "  UID Number" uidNumber ""
        prompt_input "  Gruppo principale" group "$uid"
        
        local is_existing_group=0
        local g
        for g in "${LDAP_GROUPS[@]}"; do
            local g_name="${g%%;*}"
            if [[ "$g_name" == "$group" ]]; then
                is_existing_group=1
                break
            fi
        done
        
        if (( is_existing_group == 1 )); then
            gidNumber=""
        else
            prompt_input "  GID Number del gruppo" gidNumber ""
            LDAP_GROUPS+=("${group};${gidNumber}")
        fi
        
        prompt_input "  Home directory" home "/home/$uid"
        prompt_input "  Shell" shell "/bin/bash"
        prompt_input "  Password" pass "$uid"
        prompt_input "  Descrizione" descr "Utente LDAP $uid"
        prompt_input "  GECOS" gecos "$cn $sn"
        
        LDAP_USERS+=("${uid};${cn};${sn};${uidNumber};${gidNumber};${group};${home};${shell};${pass};${descr};${gecos}")
    done
    
    echo -e "\n  ${CLR_BOLD}Gruppi Standalone LDAP${CLR_RESET}"
    while true; do
        if ! prompt_confirm "Vuoi aggiungere un gruppo LDAP senza utenti (standalone)?"; then
            break
        fi
        
        local gname ggid gmembers
        prompt_input "  Nome gruppo" gname
        prompt_input "  GID Number" ggid ""
        prompt_input "  Membri (uid separati da virgola, es. user1,user2)" gmembers ""
        
        LDAP_STANDALONE_GROUPS+=("${gname};${ggid};${gmembers}")
    done
}
