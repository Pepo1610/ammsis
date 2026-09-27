# =============================================================================
#  AMMSIS — lib/wizard_topology.sh
#  Interactive wizard for network topology collection
# =============================================================================

_COLLECT_COUNT=0

collect_routers() {
    local -n ips_ref="$1"
    local -n nets_ref="$2"
    local -n ifaces_ref="$3"
    local -n ids_ref="$4"

    local num_routers
    while true; do
        prompt_input "Quanti ROUTER vuoi configurare?" num_routers "1"
        if validate_positive_integer "$num_routers" "numero di router"; then
            NUM_ROUTERS="$num_routers"
            break
        fi
    done

    local r
    for (( r = 1; r <= NUM_ROUTERS; r++ )); do
        echo -e "\n  ${CLR_BOLD}Configurazione ROU${r}${CLR_RESET}"
        
        local num_ifaces
        while true; do
            prompt_input "  Quante interfacce (adapter) per ROU${r}?" num_ifaces "2"
            if validate_positive_integer "$num_ifaces" "numero di interfacce"; then
                break
            fi
        done

        local r_ips=""
        local r_nets=""
        local r_ids=""

        local i
        for (( i = 1; i <= num_ifaces; i++ )); do
            echo -e "\n    ${CLR_DIM}Interfaccia ${i} di ${num_ifaces}${CLR_RESET}"
            
            local adapter_id
            while true; do
                prompt_input "    Numero adapter Vagrant (2-8, 1 è eth0/NAT)" adapter_id "$((i+1))"
                if validate_positive_integer "$adapter_id" "adapter_id"; then
                    if (( adapter_id == 1 )); then
                        log_error "L'adapter 1 è riservato a eth0 (Vagrant NAT)."
                        continue
                    fi
                    
                    local is_duplicate=0
                    local id
                    for id in ${r_ids//;/ }; do
                        if [[ "$id" == "$adapter_id" ]]; then
                            is_duplicate=1
                            break
                        fi
                    done
                    
                    if (( is_duplicate == 1 )); then
                        log_error "Adapter $adapter_id già configurato su questo nodo."
                        continue
                    fi
                    break
                fi
            done

            local ip
            while true; do
                prompt_input "    Indirizzo IP" ip
                if validate_ipv4 "$ip" && check_ip_not_assigned "$ip"; then
                    break
                fi
            done

            local net
            prompt_input "    Nome del segmento intnet (es. NET1, NET2)" net

            if [[ -z "$r_ips" ]]; then
                r_ips="$ip"
                r_nets="$net"
                r_ids="$adapter_id"
            else
                r_ips="${r_ips};${ip}"
                r_nets="${r_nets};${net}"
                r_ids="${r_ids};${adapter_id}"
            fi
        done

        ips_ref+=("$r_ips")
        nets_ref+=("$r_nets")
        ifaces_ref+=("$num_ifaces")
        ids_ref+=("$r_ids")
        (( _COLLECT_COUNT++ ))
    done
}

collect_static_nodes() {
    local node_type="$1"
    local prefix="$2"
    local -n ips_ref="$3"
    local -n nets_ref="$4"
    local -n ifaces_ref="$5"
    local -n ids_ref="$6"

    local num_nodes
    while true; do
        prompt_input "Quanti ${node_type^^} vuoi configurare?" num_nodes "1"
        if validate_positive_integer "$num_nodes" "numero di ${node_type}"; then
            if [[ "$node_type" == "client" ]]; then
                NUM_CLIENTS="$num_nodes"
            else
                NUM_SERVERS="$num_nodes"
            fi
            break
        fi
    done

    local n
    for (( n = 1; n <= num_nodes; n++ )); do
        echo -e "\n  ${CLR_BOLD}Configurazione ${prefix}${n}${CLR_RESET}"
        
        local num_ifaces=1
        
        local r_ips=""
        local r_nets=""
        local r_ids=""

        local i
        for (( i = 1; i <= num_ifaces; i++ )); do
            local adapter_id
            while true; do
                prompt_input "    Numero adapter Vagrant (2-8)" adapter_id "2"
                if validate_positive_integer "$adapter_id" "adapter_id"; then
                    if (( adapter_id == 1 )); then
                        log_error "L'adapter 1 è riservato a eth0 (Vagrant NAT)."
                        continue
                    fi
                    break
                fi
            done

            local ip
            while true; do
                prompt_input "    Indirizzo IP" ip
                if validate_ipv4 "$ip" && check_ip_not_assigned "$ip"; then
                    break
                fi
            done

            local net
            local default_net="NET1"
            if [[ "$node_type" == "server" ]]; then
                default_net="NET2"
            fi
            prompt_input "    Nome del segmento intnet" net "$default_net"

            if [[ -z "$r_ips" ]]; then
                r_ips="$ip"
                r_nets="$net"
                r_ids="$adapter_id"
            else
                r_ips="${r_ips};${ip}"
                r_nets="${r_nets};${net}"
                r_ids="${r_ids};${adapter_id}"
            fi
        done

        ips_ref+=("$r_ips")
        nets_ref+=("$r_nets")
        ifaces_ref+=("$num_ifaces")
        ids_ref+=("$r_ids")
        (( _COLLECT_COUNT++ ))
    done
}

collect_dhcp_nodes() {
    local node_type="$1"
    local prefix="$2"
    local -n nets_ref="$3"
    local -n ifaces_ref="$4"
    local -n ids_ref="$5"

    local num_nodes
    while true; do
        prompt_input "Quanti ${node_type^^} vuoi configurare?" num_nodes "1"
        if validate_positive_integer "$num_nodes" "numero di ${node_type}"; then
            if [[ "$node_type" == "client" ]]; then
                NUM_CLIENTS="$num_nodes"
            else
                NUM_SERVERS="$num_nodes"
            fi
            break
        fi
    done
    
    local net
    local default_net="NET1"
    if [[ "$node_type" == "server" ]]; then
        default_net="NET2"
    fi
    prompt_input "Su quale segmento intnet condiviso si trovano i ${node_type}?" net "$default_net"
    
    local adapter_id
    while true; do
        prompt_input "Numero adapter Vagrant per tutti i ${node_type}" adapter_id "2"
        if validate_positive_integer "$adapter_id" "adapter_id"; then
            if (( adapter_id == 1 )); then
                log_error "L'adapter 1 è riservato a eth0."
                continue
            fi
            break
        fi
    done

    local n
    for (( n = 1; n <= num_nodes; n++ )); do
        nets_ref+=("$net")
        ifaces_ref+=("1")
        ids_ref+=("$adapter_id")
    done
}

collect_dhcp_info() {
    local node_type="$1"
    local -n net_cidr_ref="$2"
    local -n net_addr_ref="$3"
    local -n range_start_ref="$4"
    local -n range_end_ref="$5"
    local -n route_ref="$6"
    local ask_gateway="$7"

    echo -e "\n  ${CLR_BOLD}Configurazione rete DHCP per i ${node_type}${CLR_RESET}"
    
    local cidr_input
    while true; do
        prompt_input "    Rete in formato CIDR (es. 192.168.1.0/24)" cidr_input
        if validate_cidr_notation "$cidr_input"; then
            net_cidr_ref="$cidr_input"
            net_addr_ref="${cidr_input%%/*}"
            break
        fi
    done

    local cidr_val="${net_cidr_ref##*/}"
    
    while true; do
        prompt_input "    Range DHCP Start IP" range_start_ref
        if validate_ipv4 "$range_start_ref" && validate_ip_in_subnet "$range_start_ref" "$net_addr_ref" "$cidr_val"; then
            break
        fi
    done

    while true; do
        prompt_input "    Range DHCP End IP (es. 'ud' per ultimo usabile, o IP)" range_end_ref
        if [[ "${range_end_ref,,}" == "ud" ]]; then
            range_end_ref="ud"
            break
        elif validate_ipv4 "$range_end_ref" && validate_ip_in_subnet "$range_end_ref" "$net_addr_ref" "$cidr_val"; then
            break
        fi
    done

    if [[ "$ask_gateway" == "true" || "$ask_gateway" == "1" ]]; then
        prompt_input "    Rotta gateway per questa rete (opzionale)" route_ref
    fi
}

collect_dhcp_per_router() {
    local node_type="$1"
    local -n p_net_cidr_ref="$2"
    local -n p_net_addr_ref="$3"
    local -n p_range_start_ref="$4"
    local -n p_range_end_ref="$5"
    
    echo -e "\n  ${CLR_BOLD}Configurazione pool DHCP per router (${node_type})${CLR_RESET}"
    
    local r
    for (( r = 1; r <= NUM_ROUTERS; r++ )); do
        echo -e "\n    Pool per ROU${r}:"
        
        local cidr_input
        while true; do
            prompt_input "      Sottorete in formato CIDR (es. 192.168.1.0/24)" cidr_input
            if validate_cidr_notation "$cidr_input"; then
                p_net_cidr_ref[$r]="$cidr_input"
                p_net_addr_ref[$r]="${cidr_input%%/*}"
                break
            fi
        done
        
        local cidr_val="${p_net_cidr_ref[$r]##*/}"
        
        while true; do
            prompt_input "      Range Start IP" p_range_start_ref[$r]
            if validate_ipv4 "${p_range_start_ref[$r]}" && validate_ip_in_subnet "${p_range_start_ref[$r]}" "${p_net_addr_ref[$r]}" "$cidr_val"; then
                break
            fi
        done

        while true; do
            prompt_input "      Range End IP (usa 'ud' per ultimo usabile, o IP)" p_range_end_ref[$r]
            if [[ "${p_range_end_ref[$r],,}" == "ud" ]]; then
                p_range_end_ref[$r]="ud"
                break
            elif validate_ipv4 "${p_range_end_ref[$r]}" && validate_ip_in_subnet "${p_range_end_ref[$r]}" "${p_net_addr_ref[$r]}" "$cidr_val"; then
                break
            fi
        done
    done
}
