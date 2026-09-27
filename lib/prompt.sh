# =============================================================================
#  AMMSIS — lib/prompt.sh
#  Interactive prompt utilities
# =============================================================================

# ---------------------------------------------------------------------------
# Prompt interattivo con validazione e valore di default
# Argomenti: $1 = messaggio, $2 = nome variabile risultato, $3 = default (opzionale)
# ---------------------------------------------------------------------------

prompt_input() {
    local message="$1"
    local -n result_ref="$2"
    local default="${3:-}"
    local input

    if [[ -n "$default" ]]; then
        read -rp "$(echo -e "${CLR_BOLD}${message}${CLR_RESET} [${default}]: ")" input
        result_ref="${input:-$default}"
    else
        read -rp "$(echo -e "${CLR_BOLD}${message}${CLR_RESET}: ")" input
        result_ref="$input"
    fi
}

# ---------------------------------------------------------------------------
# Prompt di conferma Sì/No
# Argomenti: $1 = messaggio
# Ritorna: 0 se Sì, 1 se No
# ---------------------------------------------------------------------------

prompt_confirm() {
    local message="$1"
    local answer

    read -rp "$(echo -e "${CLR_BOLD}${message}${CLR_RESET} [S/n]: ")" answer
    case "${answer,,}" in
        ""|s|si|sì|y|yes) return 0 ;;
        *)                return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Prompt per scelta DHCP/Statico
# Argomenti: $1 = tipo nodo (es. "client", "server")
# Stampa su stdout: "dhcp" o "static"
# ---------------------------------------------------------------------------

prompt_net_mode() {
    local node_type="$1"
    local choice

    echo "" >&2
    echo -e "  ${CLR_BOLD}Modalità di rete per i ${node_type}:${CLR_RESET}" >&2
    echo -e "    ${CLR_CYAN}1)${CLR_RESET} DHCP  — IP assegnato dinamicamente dal router" >&2
    echo -e "    ${CLR_CYAN}2)${CLR_RESET} Statico — IP configurato manualmente" >&2

    while true; do
        prompt_input "  Scegli [1/2]" choice "1"
        case "$choice" in
            1|dhcp|DHCP)   echo "dhcp";   return 0 ;;
            2|statico|static|STATIC) echo "static"; return 0 ;;
            *) log_error "Scelta non valida. Inserisci 1 o 2." ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Costruisce l'elenco di tutti gli host definiti nella topologia
# Popola l'array globale ALL_HOSTS ("ROU1" "ROU2" ... "SRV1" ... "WKS1" ...)
# ---------------------------------------------------------------------------

declare -a ALL_HOSTS=()

_build_all_hosts_list() {
    ALL_HOSTS=()
    local i
    for (( i = 1; i <= NUM_ROUTERS; i++ )); do
        ALL_HOSTS+=("ROU${i}")
    done
    for (( i = 1; i <= NUM_SERVERS; i++ )); do
        ALL_HOSTS+=("SRV${i}")
    done
    for (( i = 1; i <= NUM_CLIENTS; i++ )); do
        ALL_HOSTS+=("WKS${i}")
    done
}

# ---------------------------------------------------------------------------
# Prompt multi-select: l'utente sceglie uno o più host da una lista
# Argomenti:
#   $1 = messaggio
#   $2 = nome array risultato (nameref)
#   $3 = nome array opzioni (nameref)
#   $4 = elenco host da escludere (opzionale, separati da spazio)
# ---------------------------------------------------------------------------

prompt_multi_select_hosts() {
    local message="$1"
    local -n result_ref="$2"
    local -n options_ref="$3"
    local exclude="${4:-}"

    result_ref=()

    # Mostra le opzioni disponibili
    echo ""
    echo -e "  ${CLR_BOLD}${message}${CLR_RESET}"
    local idx=1
    local -a available=()
    local opt
    for opt in "${options_ref[@]}"; do
        # Escludi host se specificato
        local is_excluded=0
        if [[ -n "$exclude" ]]; then
            local ex
            for ex in $exclude; do
                if [[ "$opt" == "$ex" ]]; then
                    is_excluded=1
                    break
                fi
            done
        fi
        if (( is_excluded == 0 )); then
            echo -e "    ${CLR_CYAN}${idx})${CLR_RESET} ${opt}"
            available+=("$opt")
            (( idx++ ))
        fi
    done

    if (( ${#available[@]} == 0 )); then
        log_warn "Nessun host disponibile per questa selezione."
        return
    fi

    echo -e "  ${CLR_DIM}Inserisci i numeri separati da spazio (es. '1 3'), oppure 'tutti' per selezionarli tutti.${CLR_RESET}"
    local prompt_ms_input
    prompt_input "  Selezione" prompt_ms_input

    if [[ "${prompt_ms_input,,}" == "tutti" || "${prompt_ms_input,,}" == "all" ]]; then
        result_ref=("${available[@]}")
    else
        local num
        for num in $prompt_ms_input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#available[@]} )); then
                result_ref+=("${available[$((num-1))]}")
            else
                log_warn "Indice '$num' non valido, ignorato."
            fi
        done
    fi
}

# ---------------------------------------------------------------------------
# Prompt single-select: l'utente sceglie un singolo host da una lista
# Argomenti:
#   $1 = messaggio
#   $2 = nome variabile risultato (nameref)
#   $3 = nome array opzioni (nameref)
# ---------------------------------------------------------------------------

prompt_single_select_host() {
    local message="$1"
    local -n result_ref="$2"
    local -n options_ref="$3"

    echo ""
    echo -e "  ${CLR_BOLD}${message}${CLR_RESET}"
    local idx=1
    local opt
    for opt in "${options_ref[@]}"; do
        echo -e "    ${CLR_CYAN}${idx})${CLR_RESET} ${opt}"
        (( idx++ ))
    done

    while true; do
        local choice
        prompt_input "  Scegli il numero" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options_ref[@]} )); then
            result_ref="${options_ref[$((choice-1))]}"
            return 0
        else
            log_error "Scelta non valida. Inserisci un numero tra 1 e ${#options_ref[@]}."
        fi
    done
}
