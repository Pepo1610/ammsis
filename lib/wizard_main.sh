# =============================================================================
#  AMMSIS — lib/wizard_main.sh
#  Main interactive wizard orchestrator
# =============================================================================

print_topology_summary() {
    echo -e "\n${CLR_BOLD}${CLR_GREEN}=== RIEPILOGO TOPOLOGIA ===${CLR_RESET}"
    
    echo -e "\n${CLR_CYAN}[ROUTER]${CLR_RESET}"
    local i
    for (( i = 0; i < NUM_ROUTERS; i++ )); do
        local r_id=$((i+1))
        echo "  ROU${r_id}:"
        echo "    IPs:      ${ROUTER_IPS[$i]}"
        echo "    Nets:     ${ROUTER_NETS[$i]}"
        echo "    Adapters: ${ROUTER_IFACE_IDS[$i]}"
    done
    
    echo -e "\n${CLR_CYAN}[CLIENT] (${CLIENT_NET_MODE})${CLR_RESET}"
    if [[ "$CLIENT_NET_MODE" == "static" ]]; then
        for (( i = 0; i < NUM_CLIENTS; i++ )); do
            local c_id=$((i+1))
            echo "  WKS${c_id}:"
            echo "    IP:       ${CLIENT_IPS[$i]}"
            echo "    Net:      ${CLIENT_NETS[$i]}"
        done
    else
        echo "  Numero Clients: $NUM_CLIENTS (Shared Net: ${CLIENT_NETS[0]})"
        if (( NUM_ROUTERS == 1 )); then
            echo "    Network: ${CLIENT_DHCP_NETWORK}"
            echo "    Range:   ${CLIENT_DHCP_RANGE_START} - ${CLIENT_DHCP_RANGE_END}"
        else
            for (( i = 1; i <= NUM_ROUTERS; i++ )); do
                if [[ -n "${ROUTER_DHCP_CLIENT_NETWORK[$i]}" ]]; then
                    echo "    [ROU${i}] Network: ${ROUTER_DHCP_CLIENT_NETWORK[$i]}, Range: ${ROUTER_DHCP_CLIENT_RANGE_START[$i]} - ${ROUTER_DHCP_CLIENT_RANGE_END[$i]}"
                fi
            done
        fi
    fi
    
    echo -e "\n${CLR_CYAN}[SERVER] (${SERVER_NET_MODE})${CLR_RESET}"
    if [[ "$SERVER_NET_MODE" == "static" ]]; then
        for (( i = 0; i < NUM_SERVERS; i++ )); do
            local s_id=$((i+1))
            echo "  SRV${s_id}:"
            echo "    IP:       ${SERVER_IPS[$i]}"
            echo "    Net:      ${SERVER_NETS[$i]}"
        done
    else
        echo "  Numero Servers: $NUM_SERVERS (Shared Net: ${SERVER_NETS[0]})"
        if (( NUM_ROUTERS == 1 )); then
            echo "    Network: ${SERVER_DHCP_NETWORK}"
            echo "    Range:   ${SERVER_DHCP_RANGE_START} - ${SERVER_DHCP_RANGE_END}"
        else
            for (( i = 1; i <= NUM_ROUTERS; i++ )); do
                if [[ -n "${ROUTER_DHCP_SERVER_NETWORK[$i]}" ]]; then
                    echo "    [ROU${i}] Network: ${ROUTER_DHCP_SERVER_NETWORK[$i]}, Range: ${ROUTER_DHCP_SERVER_RANGE_START[$i]} - ${ROUTER_DHCP_SERVER_RANGE_END[$i]}"
                fi
            done
        fi
    fi
    
    echo -e "\n${CLR_CYAN}[PROXY LAB]${CLR_RESET}: $USE_PROXY_LAB"
    echo "=========================================================================="
}

run_interactive_wizard() {
    echo -e "${CLR_BOLD}Benvenuto nel wizard AMMSIS v${AMMSIS_VERSION}${CLR_RESET}\n"
    
    collect_routers ROUTER_IPS ROUTER_NETS ROUTER_IFACES ROUTER_IFACE_IDS
    
    if prompt_confirm "Vuoi abilitare proxy_lab su tutti i nodi?"; then
        USE_PROXY_LAB=true
    else
        USE_PROXY_LAB=false
    fi
    
    CLIENT_NET_MODE=$(prompt_net_mode "client")
    if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
        collect_dhcp_nodes "client" "WKS" CLIENT_NETS CLIENT_IFACES CLIENT_IFACE_IDS
        if (( NUM_ROUTERS == 1 )); then
            collect_dhcp_info "client" CLIENT_DHCP_NETWORK CLIENT_DHCP_NET_ADDR CLIENT_DHCP_RANGE_START CLIENT_DHCP_RANGE_END CLIENT_DHCP_SERVER_ROUTE true
        else
            collect_dhcp_per_router "client" ROUTER_DHCP_CLIENT_NETWORK ROUTER_DHCP_CLIENT_NET_ADDR ROUTER_DHCP_CLIENT_RANGE_START ROUTER_DHCP_CLIENT_RANGE_END
        fi
        # Ricava la subnet CIDR dal network DHCP già inserito
        if (( NUM_ROUTERS == 1 )); then
            CLIENT_SUBNET_CIDR="${CLIENT_DHCP_NETWORK##*/}"
        else
            CLIENT_SUBNET_CIDR="${ROUTER_DHCP_CLIENT_NETWORK[1]##*/}"
        fi
        CLIENT_SUBNET_MASK="$(cidr_to_netmask "$CLIENT_SUBNET_CIDR")"
    else
        collect_static_nodes "client" "WKS" CLIENT_IPS CLIENT_NETS CLIENT_IFACES CLIENT_IFACE_IDS
        # Chiedi la subnet per la rete dei client (necessaria per i file di interfaccia)
        _collect_subnet "client" CLIENT_SUBNET_CIDR CLIENT_SUBNET_MASK
    fi
    
    SERVER_NET_MODE=$(prompt_net_mode "server")
    if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
        collect_dhcp_nodes "server" "SRV" SERVER_NETS SERVER_IFACES SERVER_IFACE_IDS
        if (( NUM_ROUTERS == 1 )); then
            collect_dhcp_info "server" SERVER_DHCP_NETWORK SERVER_DHCP_NET_ADDR SERVER_DHCP_RANGE_START SERVER_DHCP_RANGE_END SERVER_DHCP_CLIENT_ROUTE true
        else
            collect_dhcp_per_router "server" ROUTER_DHCP_SERVER_NETWORK ROUTER_DHCP_SERVER_NET_ADDR ROUTER_DHCP_SERVER_RANGE_START ROUTER_DHCP_SERVER_RANGE_END
        fi
        # Ricava la subnet CIDR dal network DHCP già inserito
        if (( NUM_ROUTERS == 1 )); then
            SERVER_SUBNET_CIDR="${SERVER_DHCP_NETWORK##*/}"
        else
            SERVER_SUBNET_CIDR="${ROUTER_DHCP_SERVER_NETWORK[1]##*/}"
        fi
        SERVER_SUBNET_MASK="$(cidr_to_netmask "$SERVER_SUBNET_CIDR")"
    else
        collect_static_nodes "server" "SRV" SERVER_IPS SERVER_NETS SERVER_IFACES SERVER_IFACE_IDS
        # Chiedi la subnet per la rete dei server (necessaria per i file di interfaccia)
        _collect_subnet "server" SERVER_SUBNET_CIDR SERVER_SUBNET_MASK
    fi
    
    collect_ssh_passwordless_config
    
    print_topology_summary
    if ! prompt_confirm "La topologia è corretta? Premi 'n' per annullare e riavviare, 's' per proseguire."; then
        log_error "Wizard annullato."
        exit 1
    fi
    
    collect_ldap_config
    collect_local_users_config
    collect_snmp_config
    collect_logger_config
    collect_cron_config
    
    echo -e "\n${CLR_BOLD}${CLR_GREEN}Configurazione completata.${CLR_RESET}"
    if ! prompt_confirm "Vuoi generare i file Ansible e Vagrant?"; then
        log_error "Annullato dall'utente."
        exit 1
    fi
}
