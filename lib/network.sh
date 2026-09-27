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
    local cidr="$1"
    echo "${CIDR_TO_NETMASK[$cidr]}"
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
    local cidr="$2"

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
