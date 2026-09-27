# =============================================================================
#  AMMSIS — lib/generate_ansible.sh
#  Functions for generating Ansible provisioning
# =============================================================================

strip_grading_comments() {
    local target_dir="$1"

    if [[ ! -d "$target_dir" ]]; then
        return 0
    fi

    # Cerca tutti i file .yml nella directory e rimuove le righe di valutazione
    while IFS= read -r -d '' yml_file; do
        if grep -qE '^\s*#\s*V\s+x\s+[0-9]' "$yml_file" 2>/dev/null; then
            sed -i '/^\s*#\s*V\s\+x\s\+[0-9]/d' "$yml_file"
        fi
    done < <(find "$target_dir" -name '*.yml' -print0)
}

# ---------------------------------------------------------------------------
# Copia un componente dalla cartella componenti/ alla cartella roles/
# Dopo la copia, rimuove automaticamente eventuali commenti di valutazione
# residui nei file YAML.
# Argomenti: $1 = percorso sorgente (relativo a componenti/), $2 = nome ruolo
# ---------------------------------------------------------------------------

copy_component() {
    local src_path="$1"
    local role_name="$2"
    local full_src="${COMPONENTI_DIR}/${src_path}"
    local full_dest="./roles/${role_name}"

    if [[ -d "$full_src" ]]; then
        cp -r "$full_src" "$full_dest"
        log_info "  Copiato componente: ${src_path} → roles/${role_name}"
    else
        log_warn "  Componente non trovato: ${full_src} — creo struttura vuota per ${role_name}"
        mkdir -p "${full_dest}/tasks"
        mkdir -p "${full_dest}/handlers"
        mkdir -p "${full_dest}/files"
        cat > "${full_dest}/tasks/main.yml" <<EOF
---
# TODO: Configura i task per il ruolo ${role_name}
EOF
        cat > "${full_dest}/handlers/main.yml" <<EOF
---
# TODO: Configura gli handler per il ruolo ${role_name}
EOF
    fi

    # Sanitizza i file YAML copiati rimuovendo eventuali commenti di valutazione
    strip_grading_comments "$full_dest"
}

# ---------------------------------------------------------------------------
# Crea la struttura di directory e file per Ansible, copia i componenti
# dalla cartella componenti/, e configura i file di rete con i dati
# immessi dall'utente.
# ---------------------------------------------------------------------------

setup_ansible_environment() {
    log_step "2" "Configurazione dell'ambiente Ansible..."

    # Pulisci e ricrea la directory roles/
    rm -rf ./roles
    mkdir -p ./roles

    # ══════════════════════════════════════════════════════════════════
    # A) COPIA DEI COMPONENTI
    # ══════════════════════════════════════════════════════════════════

    # --- Common (struttura vuota per fix auto eth0) ---
    mkdir -p ./roles/common/tasks
    mkdir -p ./roles/common/handlers
    mkdir -p ./roles/common/files
    cat > ./roles/common/tasks/main.yml <<'EOF'
---
# Ruolo common: fix auto eth0
# Aggiungi qui eventuali configurazioni comuni a tutte le VM.
EOF
    log_info "  Creato ruolo: common (struttura vuota)"

    # --- Proxy Lab (se abilitato) ---
    if [[ "$USE_PROXY_LAB" == true ]]; then
        copy_component "filesystem/proxy_lab" "proxy_lab"
    fi

    # --- Router: net_rouX (uno per router) ---
    local i j
    for (( i = 0; i < NUM_ROUTERS; i++ )); do
        local rnum=$((i+1))
        local role_name="net_rou${rnum}"
        copy_component "rete/net_router" "$role_name"

        # Configura i file di rete del router con i dati dell'utente
        IFS=';' read -ra ip_arr <<< "${ROUTER_IPS[$i]}"
        IFS=';' read -ra net_arr <<< "${ROUTER_NETS[$i]}"
        IFS=';' read -ra id_arr <<< "${ROUTER_IFACE_IDS[$i]}"

        # Rimuovi i file eth1/eth2 template e crea quelli corretti
        rm -f "./roles/${role_name}/files/eth1" "./roles/${role_name}/files/eth2"

        local eth_list=""
        for (( j = 0; j < ${#ip_arr[@]}; j++ )); do
            local eth_num="${id_arr[$j]}"
            local eth_ip="${ip_arr[$j]}"
            local eth_file="./roles/${role_name}/files/eth${eth_num}"

            # Determina la netmask: se questa interfaccia è sulla rete client
            # usiamo CLIENT_SUBNET_MASK, altrimenti SERVER_SUBNET_MASK
            # Euristica: se è la prima interfaccia (tipicamente eth1 = rete client),
            # se è la seconda (eth2 = rete server), etc.
            # Meglio: per il router determiniamo la netmask in base alla posizione
            local netmask
            if (( j == 0 )); then
                netmask="$CLIENT_SUBNET_MASK"
            else
                netmask="$SERVER_SUBNET_MASK"
            fi

            cat > "$eth_file" <<ETHEOF
auto eth${eth_num}
iface eth${eth_num} inet static
    address ${eth_ip}
    netmask ${netmask}
ETHEOF
            log_info "    Configurato: ${role_name}/files/eth${eth_num} → ${eth_ip}/${netmask}"

            # Accumula lista per il task loop
            if [[ -z "$eth_list" ]]; then
                eth_list="eth${eth_num}"
            else
                eth_list="${eth_list};eth${eth_num}"
            fi
        done

        # Aggiorna il tasks/main.yml con la lista corretta di interfacce
        local task_file="./roles/${role_name}/tasks/main.yml"
        {
            echo "---"
            echo "- name: Copy a new configuration \"interfaces\" files into place, after passing validation with ifup"
            echo "  ansible.builtin.copy:"
            echo "    src: \"{{ item }}\""
            echo "    dest: \"/etc/network/interfaces.d/{{ item }}\""
            echo "    owner: root"
            echo "    group: root"
            echo "    mode: '0644'"
            echo "    validate: /usr/sbin/ifup --no-act -i %s  \"{{ item }}\""
            echo "  loop:"
            IFS=';' read -ra eth_items <<< "$eth_list"
            for eth_item in "${eth_items[@]}"; do
                echo "    - ${eth_item}"
            done
            echo "  notify: Restart Networking"
        } > "$task_file"
    done

    # --- DHCP Server ---
    if (( NUM_ROUTERS > 1 )); then
        # Multi-router: un ruolo net_dhcp_server_rouX per ogni router con il suo dnsmasq.conf
        for (( i = 0; i < NUM_ROUTERS; i++ )); do
            local rnum=$((i+1))
            local dhcp_role="net_dhcp_server_rou${rnum}"
            copy_component "rete/net_dhcp_server" "$dhcp_role"

            local dnsmasq_file="./roles/${dhcp_role}/files/dnsmasq.conf"
            IFS=';' read -ra _rou_ids <<< "${ROUTER_IFACE_IDS[$i]}"
            IFS=';' read -ra _rou_ips <<< "${ROUTER_IPS[$i]}"

            {
                echo "# Configurazione dnsmasq per ROU${rnum} — generata da AMMSIS v${AMMSIS_VERSION}"
                echo ""

                # Pool DHCP client per questo router
                if [[ "$CLIENT_NET_MODE" == "dhcp" ]] && (( ${#ROUTER_DHCP_CLIENT_NETWORK[@]} > 0 )); then
                    local _c_eth="eth${_rou_ids[0]}"
                    echo "interface=${_c_eth}"
                    echo ""
                    echo "dhcp-range=${_c_eth},${ROUTER_DHCP_CLIENT_RANGE_START[$i]},${ROUTER_DHCP_CLIENT_RANGE_END[$i]},${CLIENT_SUBNET_MASK},12h"
                    echo ""
                    echo "# nessun default gateway: il Client deve continuare a usare la eth0 di Vagrant"
                    echo "dhcp-option=${_c_eth},3"
                    echo ""

                    # Rotta verso la rete dei server (option 121)
                    if (( ${#_rou_ids[@]} > 1 )); then
                        local _srv_route=""
                        if [[ "$SERVER_NET_MODE" == "dhcp" ]] && (( ${#ROUTER_DHCP_SERVER_NETWORK[@]} > 0 )); then
                            _srv_route="${ROUTER_DHCP_SERVER_NETWORK[0]}"
                        elif [[ "$SERVER_NET_MODE" == "static" ]] && (( NUM_SERVERS > 0 )); then
                            IFS=';' read -ra _s_ip <<< "${SERVER_IPS[0]}"
                            local _s_net
                            _s_net=$(calculate_network_address "${_s_ip[0]}" "$SERVER_SUBNET_CIDR")
                            _srv_route="${_s_net}/${SERVER_SUBNET_CIDR}"
                        fi
                        if [[ -n "$_srv_route" ]]; then
                            echo "# rotta verso la rete dei Server attraverso ROU${rnum}"
                            echo "dhcp-option=${_c_eth},121,${_srv_route},${_rou_ips[0]}"
                        fi
                    fi
                fi

                echo ""

                # Pool DHCP server per questo router
                if [[ "$SERVER_NET_MODE" == "dhcp" ]] && (( ${#_rou_ids[@]} > 1 )) && (( ${#ROUTER_DHCP_SERVER_NETWORK[@]} > 0 )); then
                    local _s_eth="eth${_rou_ids[1]}"
                    echo "interface=${_s_eth}"
                    echo ""
                    echo "dhcp-range=${_s_eth},${ROUTER_DHCP_SERVER_RANGE_START[$i]},${ROUTER_DHCP_SERVER_RANGE_END[$i]},${SERVER_SUBNET_MASK},12h"
                    echo ""
                    echo "# nessun default gateway: il Server deve continuare a usare la eth0 di Vagrant"
                    echo "dhcp-option=${_s_eth},3"
                    echo ""

                    # Rotta verso la rete dei client (option 121)
                    if [[ "$CLIENT_NET_MODE" == "dhcp" ]] && (( ${#ROUTER_DHCP_CLIENT_NETWORK[@]} > 0 )); then
                        echo "# rotta verso la rete dei Client attraverso ROU${rnum}"
                        echo "dhcp-option=${_s_eth},121,${ROUTER_DHCP_CLIENT_NETWORK[0]},${_rou_ips[1]}"
                    fi
                fi

            } > "$dnsmasq_file"
            log_info "  Configurato dnsmasq.conf per ROU${rnum} (${dhcp_role})"
        done
    else
        # Singolo router: un unico ruolo net_dhcp_server
        copy_component "rete/net_dhcp_server" "net_dhcp_server"

        local dnsmasq_file="./roles/net_dhcp_server/files/dnsmasq.conf"
        {
            echo "# Configurazione dnsmasq generata da AMMSIS v${AMMSIS_VERSION}"
            echo ""

            # Determina l'interfaccia DHCP del router per la rete client
            IFS=';' read -ra rou1_ids <<< "${ROUTER_IFACE_IDS[0]}"
            IFS=';' read -ra rou1_ips <<< "${ROUTER_IPS[0]}"

            if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
                local client_eth="eth${rou1_ids[0]}"
                echo "interface=${client_eth}"
                echo ""
                echo "dhcp-range=${client_eth},${CLIENT_DHCP_RANGE_START},${CLIENT_DHCP_RANGE_END},${CLIENT_SUBNET_MASK},12h"
                echo ""
                echo "# nessun default gateway: il Client deve continuare a usare la eth0 di Vagrant"
                echo "dhcp-option=${client_eth},3"
                echo ""

                # Rotta verso la rete dei server (option 121) se ci sono almeno 2 reti
                if (( ${#rou1_ids[@]} > 1 )); then
                    local server_net_for_route=""
                    if [[ -n "$CLIENT_DHCP_SERVER_ROUTE" ]]; then
                        server_net_for_route="$CLIENT_DHCP_SERVER_ROUTE"
                    elif [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
                        server_net_for_route="${SERVER_DHCP_NETWORK}"
                    else
                        if (( NUM_SERVERS > 0 )); then
                            IFS=';' read -ra srv_ip_arr <<< "${SERVER_IPS[0]}"
                            local srv_net_prefix
                            srv_net_prefix=$(calculate_network_address "${srv_ip_arr[0]}" "$SERVER_SUBNET_CIDR")
                            server_net_for_route="${srv_net_prefix}/${SERVER_SUBNET_CIDR}"
                        fi
                    fi

                    if [[ -n "$server_net_for_route" ]]; then
                        echo "# rotta verso la rete dei Server attraverso ROU1"
                        echo "dhcp-option=${client_eth},121,${server_net_for_route},${rou1_ips[0]}"
                    fi
                fi
            fi

            echo ""

            # Anche il DHCP per i server, se richiesto
            if [[ "$SERVER_NET_MODE" == "dhcp" ]] && (( ${#rou1_ids[@]} > 1 )); then
                local server_eth="eth${rou1_ids[1]}"
                echo "interface=${server_eth}"
                echo ""
                echo "dhcp-range=${server_eth},${SERVER_DHCP_RANGE_START},${SERVER_DHCP_RANGE_END},${SERVER_SUBNET_MASK},12h"
                echo ""
                echo "# nessun default gateway: il Server deve continuare a usare la eth0 di Vagrant"
                echo "dhcp-option=${server_eth},3"
                echo ""

                # Rotta verso la rete dei client (option 121)
                local client_net_for_route=""
                if [[ -n "$SERVER_DHCP_CLIENT_ROUTE" ]]; then
                    client_net_for_route="$SERVER_DHCP_CLIENT_ROUTE"
                elif [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
                    client_net_for_route="${CLIENT_DHCP_NETWORK}"
                fi
                if [[ -n "$client_net_for_route" ]]; then
                    echo "# rotta verso la rete dei Client attraverso ROU1"
                    echo "dhcp-option=${server_eth},121,${client_net_for_route},${rou1_ips[1]}"
                fi
            fi

        } > "$dnsmasq_file"
        log_info "  Configurato dnsmasq.conf con i dati DHCP"
    fi

    # --- IP Forward ---
    copy_component "rete/net_ipforward" "net_ipforward"

    # --- LDAP (condizionale) ---
    if [[ "$USE_LDAP" == true ]]; then
        log_info "  Configurazione LDAP..."
        copy_component "ldap/ldap_utils" "ldap_utils"
        copy_component "ldap/ldap_creds" "ldap_creds"
        copy_component "ldap/ldap_server" "ldap_server"
        copy_component "ldap/ldap_login" "ldap_login"
        copy_component "ldap/ldap_create_group" "ldap_create_group"
        copy_component "ldap/create_ldap_user" "create_ldap_user"

        # Genera group_vars/all.yml con le variabili LDAP condivise
        mkdir -p ./group_vars
        {
            echo "---"
            echo "# Variabili LDAP condivise - generate da AMMSIS v${AMMSIS_VERSION}"
            echo "ldap_domain: \"${LDAP_DOMAIN}\""
            echo "ldap_org: \"${LDAP_ORG}\""
            echo "ldap_admin_password: \"${LDAP_ADMIN_PASSWORD}\""
            echo "ldap_base_dn: \"${LDAP_BASE_DN}\""
            echo "ldap_admin_dn: \"cn=admin,{{ ldap_base_dn }}\""
        } > ./group_vars/all.yml
        log_info "  Generato group_vars/all.yml con variabili LDAP"

        # Trova l'IP del server LDAP nella topologia
        local ldap_server_ip="127.0.0.1"
        local _ldap_host_type _ldap_host_idx
        _ldap_host_type="${LDAP_SERVER_HOST:0:3}"
        _ldap_host_idx="${LDAP_SERVER_HOST:3}"

        case "$_ldap_host_type" in
            ROU)
                IFS=';' read -ra _lip_arr <<< "${ROUTER_IPS[$((_ldap_host_idx-1))]}"
                ldap_server_ip="${_lip_arr[0]}"
                ;;
            SRV)
                if [[ "$SERVER_NET_MODE" == "static" ]]; then
                    IFS=';' read -ra _lip_arr <<< "${SERVER_IPS[$((_ldap_host_idx-1))]}"
                    ldap_server_ip="${_lip_arr[0]}"
                fi
                ;;
            WKS)
                if [[ "$CLIENT_NET_MODE" == "static" ]]; then
                    IFS=';' read -ra _lip_arr <<< "${CLIENT_IPS[$((_ldap_host_idx-1))]}"
                    ldap_server_ip="${_lip_arr[0]}"
                fi
                ;;
        esac

        # Genera host_vars per il server LDAP
        mkdir -p ./host_vars
        {
            echo "---"
            echo "# Host vars per ${LDAP_SERVER_HOST} - generate da AMMSIS v${AMMSIS_VERSION}"
            echo "ldap_server_ip: \"127.0.0.1\"  # localhost perché è il server stesso"
        } > "./host_vars/${LDAP_SERVER_HOST}.yml"
        log_info "  Generato host_vars/${LDAP_SERVER_HOST}.yml"

        # Genera host_vars per i client LDAP con IP del server LDAP
        local _lclient
        for _lclient in "${LDAP_CLIENT_HOSTS[@]}"; do
            # Determina l'IP del server LDAP raggiungibile dal client
            # (il server LDAP potrebbe essere su una rete diversa, ma usiamo il primo IP)
            local _client_ldap_ip="$ldap_server_ip"

            # Se il file host_vars esiste già, aggiungi; altrimenti crea
            local _hv_file="./host_vars/${_lclient}.yml"
            if [[ -f "$_hv_file" ]]; then
                echo "ldap_server_ip: \"${_client_ldap_ip}\"" >> "$_hv_file"
            else
                {
                    echo "---"
                    echo "# Host vars per ${_lclient} - generate da AMMSIS v${AMMSIS_VERSION}"
                    echo "ldap_server_ip: \"${_client_ldap_ip}\""
                } > "$_hv_file"
            fi
            log_info "  Generato/aggiornato host_vars/${_lclient}.yml (ldap_server_ip)"
        done

        # Genera/aggiorna host_vars anche per gli host con accesso lettura/scrittura a LDAP
        local _lrw_host
        for _lrw_host in "${LDAP_RW_HOSTS[@]}"; do
            local _hv_file="./host_vars/${_lrw_host}.yml"
            if [[ -f "$_hv_file" ]]; then
                if ! grep -q "ldap_server_ip" "$_hv_file" 2>/dev/null; then
                    echo "ldap_server_ip: \"${ldap_server_ip}\"" >> "$_hv_file"
                fi
            else
                {
                    echo "---"
                    echo "# Host vars per ${_lrw_host} - generate da AMMSIS v${AMMSIS_VERSION}"
                    echo "ldap_server_ip: \"${ldap_server_ip}\""
                } > "$_hv_file"
            fi
            log_info "  Generato/aggiornato host_vars/${_lrw_host}.yml (ldap_server_ip per RW)"
        done

        # Genera ruoli per gli utenti LDAP
        # Prima: crea un ruolo per ogni gruppo unico
        local _g_entry
        declare -A _group_created=()  # traccia quali gruppi sono già stati generati come ruolo

        for _g_entry in "${LDAP_GROUPS[@]}"; do
            IFS=';' read -ra _gp <<< "$_g_entry"
            local _gname="${_gp[0]}"
            local _ggid="${_gp[1]}"

            if [[ -z "${_group_created[$_gname]:-}" ]]; then
                local _grole="ldap_group_${_gname}"
                copy_component "ldap/ldap_create_group" "$_grole"

                # Trova tutti gli utenti che appartengono a questo gruppo
                local _gmembers=""
                local _u_entry
                for _u_entry in "${LDAP_USERS[@]}"; do
                    IFS=';' read -ra _up <<< "$_u_entry"
                    if [[ "${_up[5]}" == "$_gname" ]]; then
                        if [[ -z "$_gmembers" ]]; then
                            _gmembers="${_up[0]}"
                        else
                            _gmembers="${_gmembers}, ${_up[0]}"
                        fi
                    fi
                done

                # Scrivi le vars del ruolo
                {
                    echo "---"
                    echo "group_name: \"${_gname}\""
                    echo "group_gid: \"${_ggid}\""
                    if [[ -n "$_gmembers" ]]; then
                        echo "group_members:"
                        IFS=',' read -ra _mlist <<< "$_gmembers"
                        local _m
                        for _m in "${_mlist[@]}"; do
                            _m="$(echo "$_m" | xargs)"  # trim
                            echo "  - \"${_m}\""
                        done
                    else
                        echo "group_members: []"
                    fi
                } > "./roles/${_grole}/vars/main.yml"
                log_info "  Configurato ruolo: ${_grole}"
                _group_created[$_gname]=1
            fi
        done

        # Gruppi standalone
        for _g_entry in "${LDAP_STANDALONE_GROUPS[@]}"; do
            IFS=';' read -ra _gp <<< "$_g_entry"
            local _gname="${_gp[0]}"
            local _ggid="${_gp[1]}"
            local _gmembers_raw="${_gp[2]:-}"

            local _grole="ldap_group_${_gname}"
            copy_component "ldap/ldap_create_group" "$_grole"
            {
                echo "---"
                echo "group_name: \"${_gname}\""
                echo "group_gid: \"${_ggid}\""
                if [[ -n "$_gmembers_raw" ]]; then
                    echo "group_members:"
                    IFS=',' read -ra _mlist <<< "$_gmembers_raw"
                    local _m
                    for _m in "${_mlist[@]}"; do
                        _m="$(echo "$_m" | xargs)"
                        echo "  - \"${_m}\""
                    done
                else
                    echo "group_members: []"
                fi
            } > "./roles/${_grole}/vars/main.yml"
            log_info "  Configurato ruolo gruppo standalone: ${_grole}"
        done

        # Genera ruoli per ogni utente LDAP

        local _u_entry
        for _u_entry in "${LDAP_USERS[@]}"; do
            IFS=';' read -ra _up <<< "$_u_entry"
            local _urole="ldap_user_${_up[0]}"
            copy_component "ldap/create_ldap_user" "$_urole"

            # Scrivi le vars del ruolo utente
            {
                echo "---"
                echo "ldap_server_ip: \"${ldap_server_ip}\""
                echo "user_uid: \"${_up[0]}\""
                echo "user_cn: \"${_up[1]}\""
                echo "user_sn: \"${_up[2]}\""
                echo "user_uidnumber: \"${_up[3]}\""
                echo "user_gidnumber: \"${_up[4]}\""
                echo "user_group: \"${_up[5]}\""
                echo "user_home: \"${_up[6]}\""
                echo "user_shell: \"${_up[7]}\""
                echo "user_pass: \"${_up[8]}\""
                echo "user_description: \"${_up[9]}\""
                # GECOS opzionale (campo 11)
                if [[ -n "${_up[10]:-}" ]]; then
                    echo "user_gecos: \"${_up[10]}\""
                fi
            } > "./roles/${_urole}/vars/main.yml"

            # Rigenera tasks/main.yml per includere condizionalmente il gecos
            local _utask="./roles/${_urole}/tasks/main.yml"
            {
                echo "---"
                echo "- name: Assicura che ou=Groups e ou=People siano gia' stati importati"
                echo "  meta: flush_handlers"
                echo ""
                echo "- name: Creazione utente LDAP"
                echo "  ansible.builtin.command: >"
                echo "    ldapadd -x -H ldap://{{ ldap_server_ip }}"
                echo "    -D \"{{ ldap_admin_dn }}\" -w \"{{ ldap_admin_password }}\""
                echo "  args:"
                echo "    stdin: |"
                echo "      dn: uid={{ user_uid }},ou=People,{{ ldap_base_dn }}"
                echo "      objectClass: inetOrgPerson"
                echo "      objectClass: posixAccount"
                echo "      objectClass: shadowAccount"
                echo "      cn: {{ user_cn }}"
                echo "      sn: {{ user_sn }}"
                echo "      uid: {{ user_uid }}"
                echo "      uidNumber: {{ user_uidnumber }}"
                echo "      gidNumber: {{ user_gidnumber }}"
                echo "      homeDirectory: {{ user_home }}"
                echo "      loginShell: {{ user_shell }}"
                echo "      description: {{ user_description }}"
                # Aggiunge gecos solo se la variabile è definita
                if [[ -n "${_up[10]:-}" ]]; then
                    echo "      gecos: {{ user_gecos }}"
                fi
                echo "      userPassword: {CRYPT}x"
                echo ""
                echo "- name: Imposta la password"
                echo "  ansible.builtin.command: >"
                echo "    ldappasswd -x -H ldap://{{ ldap_server_ip }}"
                echo "    -D \"{{ ldap_admin_dn }}\" -w \"{{ ldap_admin_password }}\""
                echo "    -s {{ user_pass }}"
                echo "    uid={{ user_uid }},ou=People,{{ ldap_base_dn }}"
            } > "$_utask"

            log_info "  Configurato ruolo: ${_urole}"

        done

        # Genera il ruolo per il file credenziali separato (se richiesto)
        if [[ "$LDAP_CRED_SEPARATE" == true ]] && (( ${#LDAP_CRED_HOSTS[@]} > 0 )); then
            log_info "  Configurazione file credenziali LDAP separato..."
            copy_component "ldap/ldap_admin_cred_file" "ldap_admin_cred_file"
            local _cred_full_path="${LDAP_CRED_PATH%/}/${LDAP_CRED_FILENAME}"
            {
                echo "---"
                echo "ldap_cred_file_path: \"${_cred_full_path}\""
                echo "ldap_cred_admin_user: \"${LDAP_CRED_ADMIN_USER}\""
                echo "ldap_cred_admin_password: \"${LDAP_ADMIN_PASSWORD}\""
            } > "./roles/ldap_admin_cred_file/vars/main.yml"
            log_info "  Configurato ruolo: ldap_admin_cred_file (${_cred_full_path})"
        fi
    else
        log_info "  LDAP non richiesto — componenti LDAP non copiati."
    fi

    # --- Utenti locali (uno o più per qualunque macchina) ---
    if (( ${#LOCAL_USERS[@]} > 0 )); then
        log_info "  Configurazione utenti locali..."
        local _local_user _local_index=0
        for _local_user in "${LOCAL_USERS[@]}"; do
            (( ++_local_index ))
            IFS='|' read -ra _local_parts <<< "${_local_user}"
            local _local_role="local_user_${_local_index}"
            local _local_vars="./roles/${_local_role}/vars/main.yml"
            copy_component "filesystem/create_user" "${_local_role}"
            {
                echo "---"
                echo "new_user_name: $(yaml_quote "${_local_parts[1]}")"
                echo "new_user_comment: $(yaml_quote "${_local_parts[2]}")"
                if [[ -n "${_local_parts[3]}" ]]; then
                    echo "new_user_uid: $(yaml_quote "${_local_parts[3]}")"
                fi
                echo "new_user_group: $(yaml_quote "${_local_parts[4]}")"
                if [[ -n "${_local_parts[5]}" ]]; then
                    echo "new_user_gid: $(yaml_quote "${_local_parts[5]}")"
                fi
                echo "new_user_groups:"
                if [[ -n "${_local_parts[6]}" ]]; then
                    local _secondary_group
                    IFS=',' read -ra _secondary_groups <<< "${_local_parts[6]}"
                    for _secondary_group in "${_secondary_groups[@]}"; do
                        _secondary_group="${_secondary_group// /}"
                        [[ -n "${_secondary_group}" ]] && echo "  - $(yaml_quote "${_secondary_group}")"
                    done
                fi
                echo "new_user_shell: $(yaml_quote "${_local_parts[7]}")"
                echo "new_user_home: $(yaml_quote "${_local_parts[8]}")"
                echo "new_user_create_home: ${_local_parts[9]}"
                echo "new_user_password: $(yaml_quote "${_local_parts[10]}")"
                echo "new_user_sudo_enabled: ${_local_parts[11]}"
                echo "new_user_sudo_commands: \"ALL\""
                echo "new_user_sudo_nopasswd: ${_local_parts[12]}"
            } > "${_local_vars}"
            log_info "  Configurato ruolo: ${_local_role} (${_local_parts[1]} su ${_local_parts[0]})"
        done
    fi

    # --- Server: net_srvX (IP statico) o net_dhcp_client (DHCP) ---
    if [[ "$SERVER_NET_MODE" == "static" ]]; then
        for (( i = 0; i < NUM_SERVERS; i++ )); do
            local snum=$((i+1))
            local role_name="net_srv${snum}"
            copy_component "rete/net_server" "$role_name"

            # Configura il file eth1 del server con IP e rotta statica
            IFS=';' read -ra srv_ip_arr <<< "${SERVER_IPS[$i]}"
            IFS=';' read -ra srv_net_arr <<< "${SERVER_NETS[$i]}"
            IFS=';' read -ra srv_id_arr <<< "${SERVER_IFACE_IDS[$i]}"

            # Rimuovi il file template e crea quello corretto
            rm -f "./roles/${role_name}/files/eth1"

            local eth_list=""
            for (( j = 0; j < ${#srv_ip_arr[@]}; j++ )); do
                local eth_num="${srv_id_arr[$j]}"
                local eth_ip="${srv_ip_arr[$j]}"
                local eth_file="./roles/${role_name}/files/eth${eth_num}"

                # Trova l'IP del router che si affaccia sulla rete del server
                # (cerchiamo tra le interfacce dei router quale è sullo stesso segmento intnet)
                local router_gw_ip=""
                local srv_intnet="${srv_net_arr[$j]}"
                local ri rj
                for (( ri = 0; ri < NUM_ROUTERS; ri++ )); do
                    IFS=';' read -ra r_nets <<< "${ROUTER_NETS[$ri]}"
                    IFS=';' read -ra r_ips <<< "${ROUTER_IPS[$ri]}"
                    for (( rj = 0; rj < ${#r_nets[@]}; rj++ )); do
                        if [[ "${r_nets[$rj]}" == "$srv_intnet" ]]; then
                            router_gw_ip="${r_ips[$rj]}"
                            break 2
                        fi
                    done
                done

                # Calcola la rete dei client per la rotta statica
                local client_net_route=""
                if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
                    client_net_route="${CLIENT_DHCP_NETWORK}"
                elif (( NUM_CLIENTS > 0 )); then
                    IFS=';' read -ra c_ip_arr <<< "${CLIENT_IPS[0]}"
                    # Calcola l'indirizzo di rete corretto via bitwise AND
                    local c_net_prefix
                    c_net_prefix=$(calculate_network_address "${c_ip_arr[0]}" "$CLIENT_SUBNET_CIDR")
                    client_net_route="${c_net_prefix}/${CLIENT_SUBNET_CIDR}"
                fi

                {
                    echo "auto eth${eth_num}"
                    echo "iface eth${eth_num} inet static"
                    echo "    address ${eth_ip}"
                    echo "    netmask ${SERVER_SUBNET_MASK}"
                    if [[ -n "$client_net_route" ]] && [[ -n "$router_gw_ip" ]]; then
                        echo "    up ip r add ${client_net_route} via ${router_gw_ip}"
                    fi
                } > "$eth_file"

                log_info "    Configurato: ${role_name}/files/eth${eth_num} → ${eth_ip}/${SERVER_SUBNET_MASK}"

                if [[ -z "$eth_list" ]]; then
                    eth_list="eth${eth_num}"
                else
                    eth_list="${eth_list};eth${eth_num}"
                fi
            done

            # Aggiorna il tasks/main.yml del server
            local task_file="./roles/${role_name}/tasks/main.yml"
            {
                echo "---"
                echo "- name: Copy a new configuration \"interfaces\" files into place, after passing validation with ifup"
                echo "  ansible.builtin.copy:"
                echo "    src: \"{{ item }}\""
                echo "    dest: \"/etc/network/interfaces.d/{{ item }}\""
                echo "    owner: root"
                echo "    group: root"
                echo "    mode: '0644'"
                echo "    validate: /usr/sbin/ifup --no-act -i %s  \"{{ item }}\""
                echo "  loop:"
                IFS=';' read -ra eth_items <<< "$eth_list"
                for eth_item in "${eth_items[@]}"; do
                    echo "    - ${eth_item}"
                done
                echo "  notify: Restart Networking"
            } > "$task_file"
        done
    fi

    # --- DHCP Client (per i client, se DHCP) ---
    if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
        copy_component "rete/net_dhcp_client" "net_dhcp_client"

        # Aggiorna l'interfaccia nel file se diversa da eth1
        if (( NUM_CLIENTS > 0 )); then
            local client_eth_id="${CLIENT_IFACE_IDS[0]}"
            if [[ "$client_eth_id" != "1" ]]; then
                local dhcp_client_file="./roles/net_dhcp_client/files/eth1dhcp"
                local new_dhcp_file="./roles/net_dhcp_client/files/eth${client_eth_id}dhcp"
                cat > "$new_dhcp_file" <<DHCPEOF
auto eth${client_eth_id}
iface eth${client_eth_id} inet dhcp
DHCPEOF
                rm -f "$dhcp_client_file"
                # Aggiorna il task
                sed -i "s/eth1dhcp/eth${client_eth_id}dhcp/g" "./roles/net_dhcp_client/tasks/main.yml"
                sed -i "s/eth1/eth${client_eth_id}/g" "./roles/net_dhcp_client/tasks/main.yml"
            fi
        fi
    fi

    # --- DHCP Client per server (se server DHCP) ---
    if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
        # Crea un ruolo net_dhcp_client_server basato su net_dhcp_client
        copy_component "rete/net_dhcp_client" "net_dhcp_client_server"

        if (( NUM_SERVERS > 0 )); then
            local server_eth_id="${SERVER_IFACE_IDS[0]}"
            local dhcp_srv_file="./roles/net_dhcp_client_server/files/eth1dhcp"
            local new_dhcp_srv_file="./roles/net_dhcp_client_server/files/eth${server_eth_id}dhcp"

            cat > "$new_dhcp_srv_file" <<DHCPEOF
auto eth${server_eth_id}
iface eth${server_eth_id} inet dhcp
DHCPEOF
            if [[ "$dhcp_srv_file" != "$new_dhcp_srv_file" ]]; then
                rm -f "$dhcp_srv_file"
            fi

            # Aggiorna il task
            local srv_task="./roles/net_dhcp_client_server/tasks/main.yml"
            {
                echo "---"
                echo "- name: Copy a new network configuration \"interfaces\" file into place, after passing validation with ifup"
                echo "  ansible.builtin.copy:"
                echo "    src: eth${server_eth_id}dhcp"
                echo "    dest: /etc/network/interfaces.d/eth${server_eth_id}"
                echo "    validate: /usr/sbin/ifup --no-act -i %s eth${server_eth_id}"
                echo "  notify: Restart Networking"
            } > "$srv_task"
        fi
    fi

    # --- SNMP (condizionale) ---
    if [[ "$USE_SNMP" == true ]]; then
        log_info "  Configurazione SNMP..."

        # Copia agente SNMP per ogni host selezionato
        if (( ${#SNMP_AGENT_HOSTS[@]} > 0 )); then
            copy_component "snmp/snmp_agent" "snmp_agent"

            # Genera host_vars con gli extend per ogni agente SNMP
            mkdir -p ./host_vars
            local _sa_host
            for _sa_host in "${SNMP_AGENT_HOSTS[@]}"; do
                # Raccogli gli extend per questo host
                local _extends_yaml=""
                local _ext_entry
                for _ext_entry in "${SNMP_AGENT_EXTENDS[@]}"; do
                    # Formato: "host_name:nome_extend:comando"
                    local _ext_host _ext_name _ext_cmd
                    _ext_host="${_ext_entry%%:*}"
                    local _rest="${_ext_entry#*:}"
                    _ext_name="${_rest%%:*}"
                    _ext_cmd="${_rest#*:}"

                    if [[ "$_ext_host" == "$_sa_host" ]]; then
                        _extends_yaml+="  - name: \"${_ext_name}\"\n"
                        _extends_yaml+="    command: \"${_ext_cmd}\"\n"
                    fi
                done

                local _hv_file="./host_vars/${_sa_host}.yml"
                if [[ -f "$_hv_file" ]]; then
                    echo "" >> "$_hv_file"
                    echo "# SNMP agent configuration" >> "$_hv_file"
                else
                    {
                        echo "---"
                        echo "# Host vars per ${_sa_host} - generate da AMMSIS v${AMMSIS_VERSION}"
                    } > "$_hv_file"
                fi

                if [[ -n "$_extends_yaml" ]]; then
                    echo "snmp_extends:" >> "$_hv_file"
                    echo -e "$_extends_yaml" >> "$_hv_file"
                else
                    echo "snmp_extends: []" >> "$_hv_file"
                fi

                # Community e view custom
                if [[ -n "$SNMP_CUSTOM_COMMUNITY" ]]; then
                    echo "snmp_community: \"${SNMP_CUSTOM_COMMUNITY}\"" >> "$_hv_file"
                fi
                if [[ -n "$SNMP_CUSTOM_VIEW" ]]; then
                    echo "snmp_view_name: \"${SNMP_CUSTOM_VIEW}\"" >> "$_hv_file"
                fi

                log_info "  Generato/aggiornato host_vars/${_sa_host}.yml (SNMP)"
            done
        fi

        # Copia manager SNMP
        if (( ${#SNMP_MANAGER_HOSTS[@]} > 0 )); then
            copy_component "snmp/snmp_manager" "snmp_manager"
        fi
    else
        log_info "  SNMP non richiesto — componenti SNMP non copiati."
    fi

    # --- Logger / Rsyslog (condizionale) ---
    if [[ "$USE_LOGGER" == true ]]; then
        log_info "  Configurazione Logger (rsyslog)..."
        copy_component "syslog/rsyslog" "rsyslog"

        # Configura rsyslog_custom.conf con la regola definita dall'utente
        local _rsyslog_custom="./roles/rsyslog/files/rsyslog_custom.conf"
        {
            echo "# Generato da AMMSIS v${AMMSIS_VERSION}"
            echo "${LOGGER_FACILITY}    ${LOGGER_FILE_PATH}"
        } > "$_rsyslog_custom"
        log_info "  Configurato rsyslog_custom.conf: ${LOGGER_FACILITY} → ${LOGGER_FILE_PATH}"
    else
        log_info "  Logger non richiesto — componenti rsyslog non copiati."
    fi

    # --- Cron (condizionale, un ruolo per job) ---
    if [[ "$USE_CRON" == true ]]; then
        log_info "  Configurazione Cron..."
        local _cron_entry _cron_index=0
        for _cron_entry in "${CRON_JOBS[@]}"; do
            (( ++_cron_index ))
            IFS='|' read -ra _cron_parts <<< "${_cron_entry}"
            local _cron_role="cron_job_${_cron_index}"
            local _cron_task="./roles/${_cron_role}/tasks/main.yml"
            local _cron_cmd="${_cron_parts[7]}"
            local _cron_seconds="${_cron_parts[8]:-}"

            # Se è configurato un intervallo in secondi, genera il ruolo loop wrapper
            if [[ -n "$_cron_seconds" ]]; then
                local _cron_loop_role="cron_loop_${_cron_index}"
                copy_component "automazione/cron_loop" "${_cron_loop_role}"

                # Deriva il nome dello script wrapper dal basename del comando
                local _cron_script_basename
                _cron_script_basename="$(basename "${_cron_cmd}" .sh)"
                local _cron_loop_path="/usr/local/bin/${_cron_script_basename}_loop.sh"

                {
                    echo "---"
                    echo "cron_loop_script_path: \"${_cron_loop_path}\""
                    echo "cron_loop_target_command: \"${_cron_cmd}\""
                    echo "cron_loop_seconds: \"${_cron_seconds}\""
                } > "./roles/${_cron_loop_role}/vars/main.yml"
                log_info "  Configurato ruolo loop wrapper: ${_cron_loop_role} (${_cron_loop_path})"

                # Il cron job eseguirà il wrapper anziché il comando originale
                _cron_cmd="${_cron_loop_path}"
            fi

            copy_component "automazione/cron" "${_cron_role}"
            {
                echo "---"
                if [[ "${_cron_parts[2]}" == true ]]; then
                    echo "- name: Setup cron job periodico ${_cron_index}"
                    echo "  ansible.builtin.cron:"
                    echo "    name: \"cron_job_ammsis_${_cron_index}_periodico\""
                    echo "    minute: $(yaml_quote "${_cron_parts[3]}")"
                    echo "    hour: $(yaml_quote "${_cron_parts[4]}")"
                    echo "    weekday: $(yaml_quote "${_cron_parts[5]}")"
                    echo "    user: $(yaml_quote "${_cron_parts[6]}")"
                    echo "    job: $(yaml_quote "${_cron_cmd}")"
                fi
                if [[ "${_cron_parts[1]}" == true ]]; then
                    [[ "${_cron_parts[2]}" == true ]] && echo ""
                    echo "- name: Setup cron job al boot ${_cron_index}"
                    echo "  ansible.builtin.cron:"
                    echo "    name: \"cron_job_ammsis_${_cron_index}_boot\""
                    echo "    special_time: reboot"
                    echo "    user: $(yaml_quote "${_cron_parts[6]}")"
                    echo "    job: $(yaml_quote "${_cron_cmd}")"
                fi
            } > "${_cron_task}"
        done
        log_info "  Configurati ${#CRON_JOBS[@]} cron job."
    else
        log_info "  Cron non richiesto — componente cron non copiato."
    fi

    # --- SSH Passwordless tra nodi omogenei (condizionale) ---
    if [[ "$USE_SSH_PASSWORDLESS_CLIENTS" == true ]] && (( NUM_CLIENTS > 1 )); then
        log_info "  Configurazione SSH passwordless per i client..."
        copy_component "ssh/ssh_keys" "ssh_keys_clients"
        copy_component "ssh/ssh_authkeys" "ssh_authkeys_clients"

        local _c_home="/root"
        if [[ "$SSH_PASSWORDLESS_CLIENT_USER" != "root" ]]; then
            _c_home="/home/${SSH_PASSWORDLESS_CLIENT_USER}"
        fi

        {
            echo "---"
            echo "ssh_user: \"${SSH_PASSWORDLESS_CLIENT_USER}\""
            echo "home_dir: \"${_c_home}\""
        } > "./roles/ssh_keys_clients/vars/main.yml"

        {
            echo "---"
            echo "ssh_user: \"${SSH_PASSWORDLESS_CLIENT_USER}\""
        } > "./roles/ssh_authkeys_clients/vars/main.yml"

        log_info "  Configurati ruoli ssh_keys_clients e ssh_authkeys_clients (user: ${SSH_PASSWORDLESS_CLIENT_USER})"
    fi

    if [[ "$USE_SSH_PASSWORDLESS_SERVERS" == true ]] && (( NUM_SERVERS > 1 )); then
        log_info "  Configurazione SSH passwordless per i server..."
        copy_component "ssh/ssh_keys" "ssh_keys_servers"
        copy_component "ssh/ssh_authkeys" "ssh_authkeys_servers"

        # Se abilitato anche per i client (o per totale indipendenza), genera una coppia
        # di chiavi dedicata per i server, garantendo la separazione (mai cross client<->server)
        if command -v ssh-keygen &>/dev/null; then
            rm -f "./roles/ssh_keys_servers/files/id_rsa" "./roles/ssh_keys_servers/files/id_rsa.pub"
            ssh-keygen -q -t rsa -b 2048 -N "" -f "./roles/ssh_keys_servers/files/id_rsa"
            cp "./roles/ssh_keys_servers/files/id_rsa.pub" "./roles/ssh_authkeys_servers/files/id_rsa.pub"
            log_info "  Generata coppia di chiavi SSH dedicata e indipendente per i server."
        fi

        local _s_home="/root"
        if [[ "$SSH_PASSWORDLESS_SERVER_USER" != "root" ]]; then
            _s_home="/home/${SSH_PASSWORDLESS_SERVER_USER}"
        fi

        {
            echo "---"
            echo "ssh_user: \"${SSH_PASSWORDLESS_SERVER_USER}\""
            echo "home_dir: \"${_s_home}\""
        } > "./roles/ssh_keys_servers/vars/main.yml"

        {
            echo "---"
            echo "ssh_user: \"${SSH_PASSWORDLESS_SERVER_USER}\""
        } > "./roles/ssh_authkeys_servers/vars/main.yml"

        log_info "  Configurati ruoli ssh_keys_servers e ssh_authkeys_servers (user: ${SSH_PASSWORDLESS_SERVER_USER})"
    fi

    # ══════════════════════════════════════════════════════════════════
    # B) GENERAZIONE site.yml — SOLO RUOLI CONFIGURATI
    # ══════════════════════════════════════════════════════════════════

    # Se i client sono in modalità statica, creiamo prima i ruoli net_wksX
    if [[ "$CLIENT_NET_MODE" == "static" ]]; then
        for (( i = 0; i < NUM_CLIENTS; i++ )); do
            local cnum=$((i+1))
            local role_name="net_wks${cnum}"
            copy_component "rete/net_server" "$role_name"

            IFS=';' read -ra cli_ip_arr <<< "${CLIENT_IPS[$i]}"
            IFS=';' read -ra cli_net_arr <<< "${CLIENT_NETS[$i]}"
            IFS=';' read -ra cli_id_arr <<< "${CLIENT_IFACE_IDS[$i]}"

            # Rimuovi il file template
            rm -f "./roles/${role_name}/files/eth1"

            local eth_list=""
            for (( j = 0; j < ${#cli_ip_arr[@]}; j++ )); do
                local eth_num="${cli_id_arr[$j]}"
                local eth_ip="${cli_ip_arr[$j]}"
                local eth_file="./roles/${role_name}/files/eth${eth_num}"

                # Trova l'IP del router sulla stessa rete
                local router_gw_ip=""
                local cli_intnet="${cli_net_arr[$j]}"
                local ri rj
                for (( ri = 0; ri < NUM_ROUTERS; ri++ )); do
                    IFS=';' read -ra r_nets <<< "${ROUTER_NETS[$ri]}"
                    IFS=';' read -ra r_ips <<< "${ROUTER_IPS[$ri]}"
                    for (( rj = 0; rj < ${#r_nets[@]}; rj++ )); do
                        if [[ "${r_nets[$rj]}" == "$cli_intnet" ]]; then
                            router_gw_ip="${r_ips[$rj]}"
                            break 2
                        fi
                    done
                done

                # Calcola la rete dei server per la rotta statica
                local server_net_route=""
                if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
                    server_net_route="${SERVER_DHCP_NETWORK}"
                elif (( NUM_SERVERS > 0 )); then
                    IFS=';' read -ra s_ip_arr <<< "${SERVER_IPS[0]}"
                    # Calcola l'indirizzo di rete corretto via bitwise AND
                    local s_net_prefix
                    s_net_prefix=$(calculate_network_address "${s_ip_arr[0]}" "$SERVER_SUBNET_CIDR")
                    server_net_route="${s_net_prefix}/${SERVER_SUBNET_CIDR}"
                fi

                {
                    echo "auto eth${eth_num}"
                    echo "iface eth${eth_num} inet static"
                    echo "    address ${eth_ip}"
                    echo "    netmask ${CLIENT_SUBNET_MASK}"
                    if [[ -n "$server_net_route" ]] && [[ -n "$router_gw_ip" ]]; then
                        echo "    up ip r add ${server_net_route} via ${router_gw_ip}"
                    fi
                } > "$eth_file"

                log_info "    Configurato: ${role_name}/files/eth${eth_num} → ${eth_ip}/${CLIENT_SUBNET_MASK}"

                if [[ -z "$eth_list" ]]; then
                    eth_list="eth${eth_num}"
                else
                    eth_list="${eth_list};eth${eth_num}"
                fi
            done

            # Aggiorna il tasks/main.yml
            local task_file="./roles/${role_name}/tasks/main.yml"
            {
                echo "---"
                echo "- name: Copy a new configuration \"interfaces\" files into place, after passing validation with ifup"
                echo "  ansible.builtin.copy:"
                echo "    src: \"{{ item }}\""
                echo "    dest: \"/etc/network/interfaces.d/{{ item }}\""
                echo "    owner: root"
                echo "    group: root"
                echo "    mode: '0644'"
                echo "    validate: /usr/sbin/ifup --no-act -i %s  \"{{ item }}\""
                echo "  loop:"
                IFS=';' read -ra eth_items <<< "$eth_list"
                for eth_item in "${eth_items[@]}"; do
                    echo "    - ${eth_item}"
                done
                echo "  notify: Restart Networking"
            } > "$task_file"
        done
    fi

    # --- Generazione site.yml pulito ---
    local site_file="./site.yml"
    {
        echo "---"

        # ── Play 1: Configurazione comune ──
        echo "- name: Configurazione comune a tutte le VM"
        echo "  hosts: all"
        echo "  become: true"
        echo "  roles:"
        echo "    - common"
        if [[ "$USE_PROXY_LAB" == true ]]; then
            echo "    - proxy_lab"
        fi

        # ── Play 2+: Router (uno per router) ──
        for (( i = 0; i < NUM_ROUTERS; i++ )); do
            local rnum=$((i+1))
            echo ""
            echo "- name: Router ROU${rnum}"
            echo "  hosts: ROU${rnum}"
            echo "  become: true"
            echo "  roles:"
            echo "    - net_rou${rnum}"
            if (( NUM_ROUTERS > 1 )); then
                echo "    - net_dhcp_server_rou${rnum}"
            else
                echo "    - net_dhcp_server"
            fi
            echo "    - net_ipforward"
        done

        # ── Play LDAP Server (se abilitato) ──
        if [[ "$USE_LDAP" == true ]]; then
            echo ""
            echo "- name: LDAP Server (${LDAP_SERVER_HOST})"
            echo "  hosts: ${LDAP_SERVER_HOST}"
            echo "  become: true"
            echo "  roles:"
            echo "    - ldap_utils"
            echo "    - ldap_creds"
            echo "    - ldap_server"

            # Ruoli per i gruppi (prima degli utenti)
            local _g_entry
            declare -A _site_group_emitted=()
            for _g_entry in "${LDAP_GROUPS[@]}"; do
                IFS=';' read -ra _gp <<< "$_g_entry"
                local _gname="${_gp[0]}"
                if [[ -z "${_site_group_emitted[$_gname]:-}" ]]; then
                    echo "    - ldap_group_${_gname}"
                    _site_group_emitted[$_gname]=1
                fi
            done
            for _g_entry in "${LDAP_STANDALONE_GROUPS[@]}"; do
                IFS=';' read -ra _gp <<< "$_g_entry"
                echo "    - ldap_group_${_gp[0]}"
            done

            # Ruoli per gli utenti
            local _u_entry
            for _u_entry in "${LDAP_USERS[@]}"; do
                IFS=';' read -ra _up <<< "$_u_entry"
                echo "    - ldap_user_${_up[0]}"
            done
        fi

        # ── Play utenti locali (uno per configurazione, anche sullo stesso host) ──
        local _site_local_user _site_local_index=0
        for _site_local_user in "${LOCAL_USERS[@]}"; do
            (( ++_site_local_index ))
            IFS='|' read -ra _site_local_parts <<< "${_site_local_user}"
            echo ""
            echo "- name: Utente locale ${_site_local_parts[1]} su ${_site_local_parts[0]}"
            echo "  hosts: ${_site_local_parts[0]}"
            echo "  become: true"
            echo "  roles:"
            echo "    - local_user_${_site_local_index}"
        done

        # ── Play: rete server individuali ──
        for (( i = 0; i < NUM_SERVERS; i++ )); do
            local snum=$((i+1))
            echo ""
            echo "- name: Rete SRV${snum}"
            echo "  hosts: SRV${snum}"
            echo "  become: true"
            echo "  roles:"
            if [[ "$SERVER_NET_MODE" == "static" ]]; then
                echo "    - net_srv${snum}"
            else
                echo "    - net_dhcp_client_server"
            fi
        done

        # ── Play: rete client individuali (se statico) ──
        if [[ "$CLIENT_NET_MODE" == "static" ]]; then
            for (( i = 0; i < NUM_CLIENTS; i++ )); do
                local cnum=$((i+1))
                echo ""
                echo "- name: Rete WKS${cnum}"
                echo "  hosts: WKS${cnum}"
                echo "  become: true"
                echo "  roles:"
                echo "    - net_wks${cnum}"
            done
        fi

        # ── Play: tutti i client ──
        echo ""
        echo "- name: Client - configurazione"
        local wks_hosts=""
        for (( i = 1; i <= NUM_CLIENTS; i++ )); do
            if [[ -z "$wks_hosts" ]]; then
                wks_hosts="WKS${i}"
            else
                wks_hosts="${wks_hosts}:WKS${i}"
            fi
        done
        echo "  hosts: ${wks_hosts}"
        echo "  become: true"
        echo "  roles:"
        if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
            echo "    - net_dhcp_client"
        fi

        # ── Play SNMP Agent (se abilitato) ──
        if [[ "$USE_SNMP" == true ]] && (( ${#SNMP_AGENT_HOSTS[@]} > 0 )); then
            local _snmp_agent_hosts_str=""
            local _sah
            for _sah in "${SNMP_AGENT_HOSTS[@]}"; do
                if [[ -z "$_snmp_agent_hosts_str" ]]; then
                    _snmp_agent_hosts_str="$_sah"
                else
                    _snmp_agent_hosts_str="${_snmp_agent_hosts_str}:${_sah}"
                fi
            done
            echo ""
            echo "- name: SNMP Agent"
            echo "  hosts: ${_snmp_agent_hosts_str}"
            echo "  become: true"
            echo "  roles:"
            echo "    - snmp_agent"
        fi

        # ── Play LDAP Client (se abilitato) ──
        if [[ "$USE_LDAP" == true ]] && (( ${#LDAP_CLIENT_HOSTS[@]} > 0 )); then
            local _ldap_client_hosts_str=""
            local _lch
            for _lch in "${LDAP_CLIENT_HOSTS[@]}"; do
                if [[ -z "$_ldap_client_hosts_str" ]]; then
                    _ldap_client_hosts_str="$_lch"
                else
                    _ldap_client_hosts_str="${_ldap_client_hosts_str}:${_lch}"
                fi
            done
            echo ""
            echo "- name: LDAP Client"
            echo "  hosts: ${_ldap_client_hosts_str}"
            echo "  become: true"
            echo "  roles:"
            echo "    - ldap_login"
            echo "    - ldap_utils"
        fi

        # ── Play LDAP Lettura/Scrittura (se abilitato) ──
        if [[ "$USE_LDAP" == true ]] && (( ${#LDAP_RW_HOSTS[@]} > 0 )); then
            local _ldap_rw_hosts_str=""
            local _lrwh
            for _lrwh in "${LDAP_RW_HOSTS[@]}"; do
                if [[ -z "$_ldap_rw_hosts_str" ]]; then
                    _ldap_rw_hosts_str="$_lrwh"
                else
                    _ldap_rw_hosts_str="${_ldap_rw_hosts_str}:${_lrwh}"
                fi
            done
            echo ""
            echo "- name: LDAP Read/Write Client"
            echo "  hosts: ${_ldap_rw_hosts_str}"
            echo "  become: true"
            echo "  roles:"
            echo "    - ldap_utils"
            echo "    - ldap_creds"
        fi

        # ── Play LDAP Admin Credential File (se abilitato) ──
        if [[ "$USE_LDAP" == true ]] && [[ "$LDAP_CRED_SEPARATE" == true ]] && (( ${#LDAP_CRED_HOSTS[@]} > 0 )); then
            local _ldap_cred_hosts_str=""
            local _lcrh
            for _lcrh in "${LDAP_CRED_HOSTS[@]}"; do
                if [[ -z "$_ldap_cred_hosts_str" ]]; then
                    _ldap_cred_hosts_str="$_lcrh"
                else
                    _ldap_cred_hosts_str="${_ldap_cred_hosts_str}:${_lcrh}"
                fi
            done
            echo ""
            echo "- name: LDAP Admin Credential File"
            echo "  hosts: ${_ldap_cred_hosts_str}"
            echo "  become: true"
            echo "  roles:"
            echo "    - ldap_admin_cred_file"
        fi

        # ── Play SNMP Manager (se abilitato) ──
        if [[ "$USE_SNMP" == true ]] && (( ${#SNMP_MANAGER_HOSTS[@]} > 0 )); then
            local _snmp_mgr_hosts_str=""
            local _smh
            for _smh in "${SNMP_MANAGER_HOSTS[@]}"; do
                if [[ -z "$_snmp_mgr_hosts_str" ]]; then
                    _snmp_mgr_hosts_str="$_smh"
                else
                    _snmp_mgr_hosts_str="${_snmp_mgr_hosts_str}:${_smh}"
                fi
            done
            echo ""
            echo "- name: SNMP Manager"
            echo "  hosts: ${_snmp_mgr_hosts_str}"
            echo "  become: true"
            echo "  roles:"
            echo "    - snmp_manager"
        fi

        # ── Play Logger (se abilitato) ──
        if [[ "$USE_LOGGER" == true ]] && (( ${#LOGGER_HOSTS[@]} > 0 )); then
            local _logger_hosts_str=""
            local _lh
            for _lh in "${LOGGER_HOSTS[@]}"; do
                if [[ -z "$_logger_hosts_str" ]]; then
                    _logger_hosts_str="$_lh"
                else
                    _logger_hosts_str="${_logger_hosts_str}:${_lh}"
                fi
            done
            echo ""
            echo "- name: Logger (rsyslog)"
            echo "  hosts: ${_logger_hosts_str}"
            echo "  become: true"
            echo "  roles:"
            echo "    - rsyslog"
        fi

        # ── Play Cron (se abilitato, un play per job) ──
        if [[ "$USE_CRON" == true ]]; then
            local _site_cron_entry _site_cron_index=0
            for _site_cron_entry in "${CRON_JOBS[@]}"; do
                (( ++_site_cron_index ))
                IFS='|' read -ra _site_cron_parts <<< "${_site_cron_entry}"
                # Converti gli host separati da virgola in formato Ansible (separati da :)
                local _site_cron_hosts="${_site_cron_parts[0]//,/:}"
                local _site_cron_seconds="${_site_cron_parts[8]:-}"
                echo ""
                echo "- name: Cron job ${_site_cron_index}"
                echo "  hosts: ${_site_cron_hosts}"
                echo "  become: true"
                echo "  roles:"
                # Se ha intervallo in secondi, include prima il ruolo loop wrapper
                if [[ -n "$_site_cron_seconds" ]]; then
                    echo "    - cron_loop_${_site_cron_index}"
                fi
                echo "    - cron_job_${_site_cron_index}"
            done
        fi

        # ── Play SSH Passwordless Client (se abilitato) ──
        if [[ "$USE_SSH_PASSWORDLESS_CLIENTS" == true ]] && (( NUM_CLIENTS > 1 )); then
            local _ssh_c_hosts=""
            for (( i = 1; i <= NUM_CLIENTS; i++ )); do
                if [[ -z "$_ssh_c_hosts" ]]; then
                    _ssh_c_hosts="WKS${i}"
                else
                    _ssh_c_hosts="${_ssh_c_hosts}:WKS${i}"
                fi
            done
            echo ""
            echo "- name: SSH Passwordless Client"
            echo "  hosts: ${_ssh_c_hosts}"
            echo "  become: true"
            echo "  roles:"
            echo "    - ssh_keys_clients"
            echo "    - ssh_authkeys_clients"
        fi

        # ── Play SSH Passwordless Server (se abilitato) ──
        if [[ "$USE_SSH_PASSWORDLESS_SERVERS" == true ]] && (( NUM_SERVERS > 1 )); then
            local _ssh_s_hosts=""
            for (( i = 1; i <= NUM_SERVERS; i++ )); do
                if [[ -z "$_ssh_s_hosts" ]]; then
                    _ssh_s_hosts="SRV${i}"
                else
                    _ssh_s_hosts="${_ssh_s_hosts}:SRV${i}"
                fi
            done
            echo ""
            echo "- name: SSH Passwordless Server"
            echo "  hosts: ${_ssh_s_hosts}"
            echo "  become: true"
            echo "  roles:"
            echo "    - ssh_keys_servers"
            echo "    - ssh_authkeys_servers"
        fi

    } > "$site_file"

    log_success "Ambiente Ansible creato con tutti i componenti configurati."
    log_info "  Ruoli copiati in: ./roles/"
    log_info "  Playbook generato: ./site.yml"
}
