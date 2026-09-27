# =============================================================================
#  AMMSIS — lib/orchestrator.sh
#  Function to orchestrate the setup
# =============================================================================

run_setup() {
    local config_file="${1:-}"

    # Inizializza la mappa CIDR
    _init_cidr_map

    if [[ -n "$config_file" && -f "$config_file" ]]; then
        load_choices "$config_file"
        migrate_legacy_cron_config
    else
        # Fase 1: Raccolta interattiva della topologia
        run_interactive_wizard
        save_choices "scelte.txt"
    fi

    # Fase 2: Generazione del Vagrantfile
    generate_vagrantfile

    # Fase 3: Setup ambiente Ansible (PRIMA di vagrant up, perché il
    #          Vagrantfile contiene blocchi 'vm.provision "ansible"' che
    #          necessitano di site.yml e roles/ già presenti su disco)
    setup_ansible_environment

    # Fase 4: Avvio delle VM — ora Vagrant trova l'ambiente Ansible pronto
    start_virtual_machines

    # Fase 5: Generazione script di consegna
    generate_maketar_script

    # Completamento
    echo ""
    print_separator
    echo -e "${CLR_GREEN}${CLR_BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║         ORCHESTRAZIONE COMPLETATA CON SUCCESSO       ║ "
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo -e "${CLR_RESET}"
    echo -e "  ${CLR_GREEN}Il cluster è attivo e l'ambiente è configurato.${CLR_RESET}"
    echo ""
    echo -e "  ${CLR_BOLD}File generati:${CLR_RESET}"
    echo -e "    • ${VAGRANTFILE_NAME}  — Configurazione delle macchine virtuali"
    echo -e "    • maketar.sh          — Script di consegna (configurabile)"
    echo -e "    • site.yml            — Playbook Ansible principale"
    echo -e "    • roles/              — Struttura ruoli Ansible per ogni nodo"
    echo ""
    echo -e "  ${CLR_BOLD}Componenti Ansible configurati automaticamente:${CLR_RESET}"
    echo -e "    • Rete router (net_rouX) con IP e subnet"
    echo -e "    • DHCP server (dnsmasq) con range e rotte"
    if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
        echo -e "    • DHCP client per WKS*"
    fi
    if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
        echo -e "    • DHCP client per SRV*"
    fi
    if [[ "$USE_LDAP" == true ]]; then
        echo -e "    • LDAP server (${LDAP_SERVER_HOST}) con dominio ${LDAP_DOMAIN}"
        if (( ${#LDAP_CLIENT_HOSTS[@]} > 0 )); then
            echo -e "    • LDAP client (login): ${LDAP_CLIENT_HOSTS[*]}"
        fi
        if (( ${#LDAP_RW_HOSTS[@]} > 0 )); then
            echo -e "    • LDAP client (lettura/scrittura): ${LDAP_RW_HOSTS[*]}"
        fi
        echo -e "    • ${#LDAP_USERS[@]} utenti e ${#LDAP_GROUPS[@]} gruppi LDAP"
        echo -e "    • group_vars/all.yml con variabili LDAP condivise"
    fi
    if [[ "$USE_SNMP" == true ]]; then
        if (( ${#SNMP_AGENT_HOSTS[@]} > 0 )); then
            echo -e "    • SNMP agent: ${SNMP_AGENT_HOSTS[*]}"
        fi
        if (( ${#SNMP_MANAGER_HOSTS[@]} > 0 )); then
            echo -e "    • SNMP manager: ${SNMP_MANAGER_HOSTS[*]}"
        fi
    fi
    if [[ "$USE_SSH_PASSWORDLESS_CLIENTS" == true ]] || [[ "$USE_SSH_PASSWORDLESS_SERVERS" == true ]]; then
        if [[ "$USE_SSH_PASSWORDLESS_CLIENTS" == true ]]; then
            echo -e "    • SSH passwordless client (${SSH_PASSWORDLESS_CLIENT_USER}@WKS*)"
        fi
        if [[ "$USE_SSH_PASSWORDLESS_SERVERS" == true ]]; then
            echo -e "    • SSH passwordless server (${SSH_PASSWORDLESS_SERVER_USER}@SRV*)"
        fi
    fi
    echo -e "    • SSH, Syslog, Cron, Systemd, etc."
    echo ""
    echo -e "  ${CLR_BOLD}Prossimi passi:${CLR_RESET}"
    echo -e "    1. Configura gli script in ${CLR_CYAN}roles/install_script_server/files/${CLR_RESET}"
    echo -e "    2. Per la consegna: ${CLR_CYAN}./ammsis.sh --maketar${CLR_RESET}"
    print_separator
}
