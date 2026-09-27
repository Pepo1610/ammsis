# =============================================================================
#  AMMSIS — lib/validation.sh
#  Input validation utilities
# =============================================================================

# ---------------------------------------------------------------------------
# Validazione: controlla che una stringa sia un intero positivo
# Argomenti: $1 = valore, $2 = nome campo (per messaggi di errore)
# Ritorna: 0 se valido, 1 altrimenti
# ---------------------------------------------------------------------------

validate_positive_integer() {
    local value="$1"
    local field_name="$2"

    if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
        log_error "'${value}' non è un intero positivo valido per ${field_name}."
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Validazione: controlla che una stringa sia un IPv4 valido
# Argomenti: $1 = indirizzo IP
# Ritorna: 0 se valido, 1 altrimenti
# Note: rifiuta indirizzi che terminano con .0 (rete) o .255 (broadcast)
# ---------------------------------------------------------------------------

validate_ipv4() {
    local ip="$1"

    # Verifica formato base: 4 ottetti separati da punti
    if ! [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
        return 1
    fi

    # Verifica che ogni ottetto sia nel range 0-255
    local i
    for i in 1 2 3 4; do
        local octet="${BASH_REMATCH[$i]}"
        if (( octet > 255 )); then
            return 1
        fi
    done

    # Rifiuta indirizzi di rete (.0) e broadcast (.255)
    local last_octet="${BASH_REMATCH[4]}"
    if (( last_octet == 0 )); then
        log_error "L'indirizzo IP non può terminare con .0 (indirizzo di rete)."
        return 1
    fi
    if (( last_octet == 255 )); then
        log_error "L'indirizzo IP non può terminare con .255 (indirizzo di broadcast)."
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Validazione: controlla che un valore sia un CIDR valido (1-32)
# Argomenti: $1 = valore
# Ritorna: 0 se valido, 1 altrimenti
# ---------------------------------------------------------------------------

validate_cidr() {
    local value="$1"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "'${value}' non è un numero valido."
        return 1
    fi

    if (( value < 1 || value > 32 )); then
        log_error "Il valore CIDR deve essere compreso tra 1 e 32."
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Validazione: controlla che una stringa sia un indirizzo di rete IPv4
# (accetta ultimo ottetto .0)
# Argomenti: $1 = indirizzo di rete
# Ritorna: 0 se valido, 1 altrimenti
# ---------------------------------------------------------------------------

validate_network_address() {
    local ip="$1"

    if ! [[ "$ip" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
        return 1
    fi

    local i
    for i in 1 2 3 4; do
        local octet="${BASH_REMATCH[$i]}"
        if (( octet > 255 )); then
            return 1
        fi
    done

    return 0
}

# ---------------------------------------------------------------------------
# Validazione: controlla formato CIDR notation (es. 192.168.1.0/24)
# Argomenti: $1 = stringa in formato X.X.X.X/Y
# Ritorna: 0 se valido, 1 altrimenti
# ---------------------------------------------------------------------------

validate_cidr_notation() {
    local cidr_str="$1"

    if ! [[ "$cidr_str" =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]+)$ ]]; then
        log_error "Formato non valido. Usa il formato X.X.X.X/Y (es. 192.168.2.0/24)"
        return 1
    fi

    local network="${BASH_REMATCH[1]}"
    local prefix="${BASH_REMATCH[2]}"

    if ! validate_network_address "$network"; then
        log_error "Indirizzo di rete non valido: ${network}"
        return 1
    fi

    if ! validate_cidr "$prefix"; then
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Validazione: controlla che un IP appartenga alla stessa subnet di una rete
# Argomenti: $1 = IP da validare, $2 = indirizzo di rete, $3 = prefisso CIDR
# Ritorna: 0 se l'IP è nella stessa subnet, 1 altrimenti
# ---------------------------------------------------------------------------

validate_ip_in_subnet() {
    local ip="$1"
    local network="$2"
    local cidr="$3"

    # Converti IP in intero a 32 bit
    local -a ip_parts net_parts
    IFS='.' read -ra ip_parts <<< "$ip"
    IFS='.' read -ra net_parts <<< "$network"

    local ip_int=$(( (ip_parts[0] << 24) + (ip_parts[1] << 16) + (ip_parts[2] << 8) + ip_parts[3] ))
    local net_int=$(( (net_parts[0] << 24) + (net_parts[1] << 16) + (net_parts[2] << 8) + net_parts[3] ))

    # Calcola la maschera di rete
    local mask_int
    if (( cidr == 0 )); then
        mask_int=0
    else
        mask_int=$(( 0xFFFFFFFF << (32 - cidr) ))
    fi

    # Confronta la parte di rete
    if (( (ip_int & mask_int) != (net_int & mask_int) )); then
        log_error "L'indirizzo ${ip} non appartiene alla rete ${network}/${cidr}."
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Validazione: controlla che un IP non sia già stato assegnato a un altro nodo
# Argomenti: $1 = IP da validare
# Ritorna: 0 se l'IP non è assegnato, 1 altrimenti
# ---------------------------------------------------------------------------

check_ip_not_assigned() {
    local ip="$1"
    local assigned_ip

    # Controlla in ROUTER_IPS
    for ips_str in "${ROUTER_IPS[@]}"; do
        IFS=';' read -ra ips_arr <<< "$ips_str"
        for assigned_ip in "${ips_arr[@]}"; do
            if [[ "$ip" == "$assigned_ip" ]]; then
                log_error "L'indirizzo IP ${ip} è già stato assegnato a un router."
                return 1
            fi
        done
    done

    # Controlla in CLIENT_IPS
    for ips_str in "${CLIENT_IPS[@]}"; do
        IFS=';' read -ra ips_arr <<< "$ips_str"
        for assigned_ip in "${ips_arr[@]}"; do
            if [[ "$ip" == "$assigned_ip" ]]; then
                log_error "L'indirizzo IP ${ip} è già stato assegnato a un client."
                return 1
            fi
        done
    done

    # Controlla in SERVER_IPS
    for ips_str in "${SERVER_IPS[@]}"; do
        IFS=';' read -ra ips_arr <<< "$ips_str"
        for assigned_ip in "${ips_arr[@]}"; do
            if [[ "$ip" == "$assigned_ip" ]]; then
                log_error "L'indirizzo IP ${ip} è già stato assegnato a un server."
                return 1
            fi
        done
    done

    return 0
}
