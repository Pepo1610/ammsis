# =============================================================================
#  AMMSIS — lib/network.sh
#  Network calculation utilities
# =============================================================================

# ---------------------------------------------------------------------------
# Converte un prefisso CIDR (1-32) nella netmask corrispondente
# Argomenti: $1 = prefisso CIDR
# Stampa su stdout la netmask
# ---------------------------------------------------------------------------

cidr_to_netmask() {
    local cidr="${1:-24}"
    if (( ${#CIDR_TO_NETMASK[@]} == 0 )); then
        _init_cidr_map
    fi
    echo "${CIDR_TO_NETMASK[$cidr]:-255.255.255.0}"
}

# ---------------------------------------------------------------------------
# Calcola l'indirizzo di rete dato un IP host e un prefisso CIDR
# Applica la maschera di rete via bitwise AND per ottenere la rete corretta,
# anche per subnet non allineate a /24 (es. /28, /25, /27, ecc.)
# Argomenti: $1 = IP host (es. 192.168.77.5), $2 = prefisso CIDR (es. 28)
# Stampa su stdout l'indirizzo di rete (es. 192.168.77.0)
# ---------------------------------------------------------------------------

calculate_network_address() {
    local ip="$1"
    local cidr="${2:-24}"

    local -a octets
    IFS='.' read -ra octets <<< "$ip"

    local ip_int=$(( (octets[0] << 24) + (octets[1] << 16) + (octets[2] << 8) + octets[3] ))

    local mask_int
    if (( cidr == 0 )); then
        mask_int=0
    else
        mask_int=$(( 0xFFFFFFFF << (32 - cidr) ))
    fi

    local net_int=$(( ip_int & mask_int ))

    echo "$(( (net_int >> 24) & 0xFF )).$(( (net_int >> 16) & 0xFF )).$(( (net_int >> 8) & 0xFF )).$(( net_int & 0xFF ))"
}

# ---------------------------------------------------------------------------
# Normalizza e garantisce la presenza di subnet CIDR e Netmask per reti
# client e server, sia dopo il wizard sia dopo il caricamento da file.
# ---------------------------------------------------------------------------
normalize_network_config() {
    if (( ${#CIDR_TO_NETMASK[@]} == 0 )); then
        _init_cidr_map
    fi

    # Subnet Client
    if [[ -z "${CLIENT_SUBNET_CIDR:-}" ]]; then
        if [[ -n "${CLIENT_DHCP_NETWORK:-}" ]]; then
            CLIENT_SUBNET_CIDR="${CLIENT_DHCP_NETWORK##*/}"
        elif (( ${#ROUTER_DHCP_CLIENT_NETWORK[@]} > 0 )) && [[ -n "${ROUTER_DHCP_CLIENT_NETWORK[1]:-}" ]]; then
            CLIENT_SUBNET_CIDR="${ROUTER_DHCP_CLIENT_NETWORK[1]##*/}"
        else
            CLIENT_SUBNET_CIDR="24"
        fi
    fi
    if [[ -z "${CLIENT_SUBNET_MASK:-}" ]]; then
        CLIENT_SUBNET_MASK="$(cidr_to_netmask "$CLIENT_SUBNET_CIDR")"
    fi

    # Subnet Server
    if [[ -z "${SERVER_SUBNET_CIDR:-}" ]]; then
        if [[ -n "${SERVER_DHCP_NETWORK:-}" ]]; then
            SERVER_SUBNET_CIDR="${SERVER_DHCP_NETWORK##*/}"
        elif (( ${#ROUTER_DHCP_SERVER_NETWORK[@]} > 0 )) && [[ -n "${ROUTER_DHCP_SERVER_NETWORK[1]:-}" ]]; then
            SERVER_SUBNET_CIDR="${ROUTER_DHCP_SERVER_NETWORK[1]##*/}"
        else
            SERVER_SUBNET_CIDR="24"
        fi
    fi
    if [[ -z "${SERVER_SUBNET_MASK:-}" ]]; then
        SERVER_SUBNET_MASK="$(cidr_to_netmask "$SERVER_SUBNET_CIDR")"
    fi
}

# ---------------------------------------------------------------------------
# Calcola l'ultimo indirizzo IP host usabile in una subnet
# (indirizzo di broadcast - 1)
# Argomenti: $1 = indirizzo di rete (es. 192.168.77.0), $2 = prefisso CIDR
# Stampa su stdout l'ultimo IP host usabile (es. 192.168.77.14 per /28)
# ---------------------------------------------------------------------------

calculate_last_usable_ip() {
    local network="$1"
    local cidr="$2"

    local -a octets
    IFS='.' read -ra octets <<< "$network"

    local net_int=$(( (octets[0] << 24) + (octets[1] << 16) + (octets[2] << 8) + octets[3] ))

    # Numero di host nella subnet: 2^(32-cidr)
    local host_bits=$(( 32 - cidr ))
    local num_hosts=$(( 1 << host_bits ))

    # Broadcast = network + num_hosts - 1; ultimo host = broadcast - 1
    local last_host_int=$(( net_int + num_hosts - 2 ))

    echo "$(( (last_host_int >> 24) & 0xFF )).$(( (last_host_int >> 16) & 0xFF )).$(( (last_host_int >> 8) & 0xFF )).$(( last_host_int & 0xFF ))"
}

# ---------------------------------------------------------------------------
# Risolve l'indice dell'interfaccia Linux (es. 1 per eth1, 2 per eth2)
# a partire dall'ID specificato (adapter Vagrant 2-8 o indice eth 1-7).
#
# In Vagrant / VirtualBox:
#   Adapter 1 = eth0 (riservato per NAT / SSH)
#   Adapter 2 = eth1 (prima interfaccia privata)
#   Adapter 3 = eth2 (seconda interfaccia privata)
#
# Se raw_id >= 2 e la convenzione usata sul nodo è basata sui numeri adapter
# (primo adapter >= 2), mappa adapter N a eth$((N - 1)).
# Se l'utente ha inserito direttamente la numerazione eth (es. 1 per eth1),
# mantiene il valore.
# In assenza di ID, usa la posizione sequenziale (iface_idx + 1).
# ---------------------------------------------------------------------------
resolve_eth_num() {
    local raw_id="${1:-}"
    local iface_idx="${2:-0}"
    local first_id="${3:-$raw_id}"

    if [[ -z "$raw_id" ]]; then
        echo "$(( iface_idx + 1 ))"
    elif [[ "$raw_id" =~ ^[0-9]+$ ]] && [[ "$first_id" =~ ^[0-9]+$ ]] && (( first_id >= 2 )); then
        echo "$(( raw_id - 1 ))"
    elif [[ "$raw_id" =~ ^[0-9]+$ ]]; then
        echo "$raw_id"
    else
        echo "$(( iface_idx + 1 ))"
    fi
}

# ---------------------------------------------------------------------------
# Calcola il primo indirizzo IP host usabile in una subnet (rete + 1)
# Argomenti: $1 = indirizzo di rete (es. 172.21.64.0), $2 = prefisso CIDR
# Stampa su stdout il primo IP host usabile (es. 172.21.64.1)
# ---------------------------------------------------------------------------

calculate_first_usable_ip() {
    local network="$1"
    local cidr="$2"

    local -a octets
    IFS='.' read -ra octets <<< "$network"

    local net_int=$(( (octets[0] << 24) + (octets[1] << 16) + (octets[2] << 8) + octets[3] ))

    # Primo host = network + 1
    local first_host_int=$(( net_int + 1 ))

    echo "$(( (first_host_int >> 24) & 0xFF )).$(( (first_host_int >> 16) & 0xFF )).$(( (first_host_int >> 8) & 0xFF )).$(( first_host_int & 0xFF ))"
}
