# =============================================================================
#  AMMSIS — lib/generate_vagrantfile.sh
#  Function to generate the Vagrantfile
# =============================================================================

generate_vagrantfile() {
    local outfile="${VAGRANTFILE_NAME}"

    log_step "1" "Generazione del Vagrantfile..."

    # Costruisci il commento descrittivo della topologia
    local topo_comment=""
    topo_comment+="# Topologia generata da AMMSIS v${AMMSIS_VERSION}\n"
    topo_comment+="# Data: $(date '+%Y-%m-%d %H:%M:%S')\n"
    topo_comment+="#\n"

    # Descrizione router
    local i j
    for (( i = 0; i < NUM_ROUTERS; i++ )); do
        IFS=';' read -ra ip_arr <<< "${ROUTER_IPS[$i]}"
        IFS=';' read -ra net_arr <<< "${ROUTER_NETS[$i]}"
        IFS=';' read -ra id_arr <<< "${ROUTER_IFACE_IDS[$i]}"
        topo_comment+="#   ROU$((i+1)) = Router"
        for (( j = 0; j < ${#ip_arr[@]}; j++ )); do
            topo_comment+=" (${ip_arr[$j]}/${CLIENT_SUBNET_CIDR} su ${net_arr[$j]})"
        done
        topo_comment+="\n"
    done

    # Descrizione client
    for (( i = 0; i < NUM_CLIENTS; i++ )); do
        if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
            topo_comment+="#   WKS$((i+1)) = Client (DHCP su ${CLIENT_NETS[$i]})\n"
        else
            IFS=';' read -ra ip_arr <<< "${CLIENT_IPS[$i]}"
            IFS=';' read -ra net_arr <<< "${CLIENT_NETS[$i]}"
            topo_comment+="#   WKS$((i+1)) = Client (${ip_arr[0]}/${CLIENT_SUBNET_CIDR} su ${net_arr[0]})\n"
        fi
    done

    # Descrizione server
    for (( i = 0; i < NUM_SERVERS; i++ )); do
        if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
            topo_comment+="#   SRV$((i+1)) = Server (DHCP su ${SERVER_NETS[$i]})\n"
        else
            IFS=';' read -ra ip_arr <<< "${SERVER_IPS[$i]}"
            IFS=';' read -ra net_arr <<< "${SERVER_NETS[$i]}"
            topo_comment+="#   SRV$((i+1)) = Server (${ip_arr[0]}/${SERVER_SUBNET_CIDR} su ${net_arr[0]})\n"
        fi
    done

    # --- Calcola i segmenti intnet necessari per ogni tipo di nodo ---

    # Per i router, raccogliamo tutte le reti intnet uniche per ogni interfaccia
    # e le useremo nel loop Ruby
    # Per semplicità, se tutti i router hanno le stesse reti intnet, usiamo un unico loop.
    # Altrimenti, generiamo blocchi define individuali.

    # Inizia a scrivere il Vagrantfile
    {
        echo "# -*- mode: ruby -*-"
        echo "# vi: set ft=ruby :"
        echo -e "$topo_comment"
        echo "# parametrizzato con loop"
        echo ""
        echo "NUM_CLIENTS = ${NUM_CLIENTS}"
        echo "NUM_ROUTERS = ${NUM_ROUTERS}"
        echo "NUM_SERVERS = ${NUM_SERVERS}"
        echo ""
        echo "Vagrant.configure(\"2\") do |config|"
        echo ""
        echo "  config.vm.box = \"${DEFAULT_BOX}\""
        echo "  config.vm.provider \"virtualbox\" do |vb|"
        echo "    vb.linked_clone = true"
        echo "  end"
        echo "  config.vm.provision \"ansible\" do |ansible|"
        echo "    ansible.playbook = \"site.yml\""
        echo "  end"
        echo ""

        # ── ROUTER ──
        echo "  # il router va creato per primo: ospita DHCP e directory server"

        # Se tutti i router hanno le stesse reti intnet possiamo usare un loop
        # Altrimenti generiamo blocchi individuali
        local all_routers_same_nets=true
        if (( NUM_ROUTERS > 1 )); then
            local first_nets="${ROUTER_NETS[0]}"
            for (( i = 1; i < NUM_ROUTERS; i++ )); do
                if [[ "${ROUTER_NETS[$i]}" != "$first_nets" ]]; then
                    all_routers_same_nets=false
                    break
                fi
            done
        fi

        if [[ "$all_routers_same_nets" == true ]] && (( NUM_ROUTERS >= 1 )); then
            echo "  (1..NUM_ROUTERS).each do |i|"
            echo "    config.vm.define \"ROU#{i}\" do |machine|"
            echo "      machine.vm.hostname = \"ROU#{i}\""

            # Genera le linee network per le interfacce del primo router (tutte uguali)
            IFS=';' read -ra net_arr <<< "${ROUTER_NETS[0]}"
            IFS=';' read -ra id_arr <<< "${ROUTER_IFACE_IDS[0]}"
            for (( j = 0; j < ${#net_arr[@]}; j++ )); do
                echo "      machine.vm.network \"private_network\", virtualbox__intnet: \"${net_arr[$j]}\", auto_config: false"
            done

            echo "    end"
            echo "  end"
        else
            # Genera blocchi individuali per ogni router
            for (( i = 0; i < NUM_ROUTERS; i++ )); do
                local rnum=$((i+1))
                echo "  config.vm.define \"ROU${rnum}\" do |machine|"
                echo "    machine.vm.hostname = \"ROU${rnum}\""
                IFS=';' read -ra net_arr <<< "${ROUTER_NETS[$i]}"
                for (( j = 0; j < ${#net_arr[@]}; j++ )); do
                    echo "    machine.vm.network \"private_network\", virtualbox__intnet: \"${net_arr[$j]}\", auto_config: false"
                done
                echo "  end"
                echo ""
            done
        fi

        echo ""

        # ── SERVER ──
        # Per i server, controlliamo se tutti hanno le stesse reti intnet
        local all_servers_same_nets=true
        if (( NUM_SERVERS > 1 )); then
            local first_nets="${SERVER_NETS[0]}"
            for (( i = 1; i < NUM_SERVERS; i++ )); do
                if [[ "${SERVER_NETS[$i]}" != "$first_nets" ]]; then
                    all_servers_same_nets=false
                    break
                fi
            done
        fi

        if [[ "$all_servers_same_nets" == true ]] && (( NUM_SERVERS >= 1 )); then
            echo "  (1..NUM_SERVERS).each do |i|"
            echo "    config.vm.define \"SRV#{i}\" do |machine|"
            echo "      machine.vm.hostname = \"SRV#{i}\""

            if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
                echo "      machine.vm.network \"private_network\", virtualbox__intnet: \"${SERVER_NETS[0]}\", auto_config: false"
            else
                # Per IP statico, usiamo le reti dal primo server (tutte uguali)
                IFS=';' read -ra net_arr <<< "${SERVER_NETS[0]}"
                for (( j = 0; j < ${#net_arr[@]}; j++ )); do
                    echo "      machine.vm.network \"private_network\", virtualbox__intnet: \"${net_arr[$j]}\", auto_config: false"
                done
            fi

            echo "    end"
            echo "  end"
        else
            for (( i = 0; i < NUM_SERVERS; i++ )); do
                local snum=$((i+1))
                echo "  config.vm.define \"SRV${snum}\" do |machine|"
                echo "    machine.vm.hostname = \"SRV${snum}\""
                if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
                    echo "    machine.vm.network \"private_network\", virtualbox__intnet: \"${SERVER_NETS[$i]}\", auto_config: false"
                else
                    IFS=';' read -ra net_arr <<< "${SERVER_NETS[$i]}"
                    for (( j = 0; j < ${#net_arr[@]}; j++ )); do
                        echo "    machine.vm.network \"private_network\", virtualbox__intnet: \"${net_arr[$j]}\", auto_config: false"
                    done
                fi
                echo "  end"
                echo ""
            done
        fi

        echo ""

        # ── CLIENT ──
        local all_clients_same_nets=true
        if (( NUM_CLIENTS > 1 )); then
            local first_nets="${CLIENT_NETS[0]}"
            for (( i = 1; i < NUM_CLIENTS; i++ )); do
                if [[ "${CLIENT_NETS[$i]}" != "$first_nets" ]]; then
                    all_clients_same_nets=false
                    break
                fi
            done
        fi

        if [[ "$all_clients_same_nets" == true ]] && (( NUM_CLIENTS >= 1 )); then
            echo "  (1..NUM_CLIENTS).each do |i|"
            echo "    config.vm.define \"WKS#{i}\" do |machine|"
            echo "      machine.vm.hostname = \"WKS#{i}\""

            if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
                echo "      machine.vm.network \"private_network\", virtualbox__intnet: \"${CLIENT_NETS[0]}\", auto_config: false"
            else
                IFS=';' read -ra net_arr <<< "${CLIENT_NETS[0]}"
                for (( j = 0; j < ${#net_arr[@]}; j++ )); do
                    echo "      machine.vm.network \"private_network\", virtualbox__intnet: \"${net_arr[$j]}\", auto_config: false"
                done
            fi

            echo "    end"
            echo "  end"
        else
            for (( i = 0; i < NUM_CLIENTS; i++ )); do
                local cnum=$((i+1))
                echo "  config.vm.define \"WKS${cnum}\" do |machine|"
                echo "    machine.vm.hostname = \"WKS${cnum}\""
                if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
                    echo "    machine.vm.network \"private_network\", virtualbox__intnet: \"${CLIENT_NETS[$i]}\", auto_config: false"
                else
                    IFS=';' read -ra net_arr <<< "${CLIENT_NETS[$i]}"
                    for (( j = 0; j < ${#net_arr[@]}; j++ )); do
                        echo "    machine.vm.network \"private_network\", virtualbox__intnet: \"${net_arr[$j]}\", auto_config: false"
                    done
                fi
                echo "  end"
                echo ""
            done
        fi

        echo ""
        echo "end"

    } > "$outfile"

    log_success "Vagrantfile generato con successo: ${outfile}"
}
