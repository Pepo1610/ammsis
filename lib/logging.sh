# =============================================================================
#  AMMSIS — lib/logging.sh
#  Logging and terminal output utilities
# =============================================================================

# ---------------------------------------------------------------------------
# Logging strutturato con livelli
# ---------------------------------------------------------------------------

log_info()    { echo -e "${CLR_BLUE}[INFO]${CLR_RESET}  $*"; }
log_success() { echo -e "${CLR_GREEN}[✓]${CLR_RESET}     $*"; }
log_warn()    { echo -e "${CLR_YELLOW}[WARN]${CLR_RESET}  $*"; }
log_error()   { echo -e "${CLR_RED}[ERROR]${CLR_RESET} $*"; }
log_step()    { echo -e "${CLR_CYAN}${CLR_BOLD}[STEP $1]${CLR_RESET} $2"; }

check_components_integrity() {
    local verification_output component
    local -a invalid_components=()

    if [[ ! -f "${ROLE_GENERATOR}" ]]; then
        log_error "Generatore componenti non trovato: ${ROLE_GENERATOR}"
        exit 1
    fi
    if ! verification_output="$(bash "${ROLE_GENERATOR}" --verify "${COMPONENTI_DIR}")"; then
        log_error "Impossibile verificare le componenti tramite genera_roles.sh."
        exit 1
    fi
    while IFS= read -r component; do
        [[ -n "${component}" ]] && invalid_components+=("${component}")
    done <<< "${verification_output}"
    if (( ${#invalid_components[@]} == 0 )); then
        return
    fi

    local present_count=$(( ${#EXPECTED_COMPONENTS[@]} - ${#invalid_components[@]} ))
    local missing_list
    missing_list="$(IFS=', '; echo "${invalid_components[*]}")"
    echo -e "${CLR_YELLOW}[WARNING]${CLR_RESET} componenti presenti: ${present_count} su ${#EXPECTED_COMPONENTS[@]}. Le seguenti componenti: ${missing_list} verranno generate dal generatore"
    if ! bash "${ROLE_GENERATOR}" --restore "${COMPONENTI_DIR}" "${invalid_components[@]}"; then
        log_error "Ripristino delle componenti non riuscito."
        exit 1
    fi
    if verification_output="$(bash "${ROLE_GENERATOR}" --verify "${COMPONENTI_DIR}")" && [[ -z "${verification_output}" ]]; then
        log_success "Componenti ripristinate e verificate."
    else
        log_error "Una o più componenti non hanno superato la verifica dopo il ripristino."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Stampa un separatore visuale
# ---------------------------------------------------------------------------

print_separator() {
    echo -e "${CLR_DIM}$(printf '─%.0s' {1..60})${CLR_RESET}"
}

# ---------------------------------------------------------------------------
# Stampa il banner di avvio
# ---------------------------------------------------------------------------

print_banner() {
    echo -e "${CLR_CYAN}${CLR_BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║     AMMSIS — Automated Multi-Machine System           ║"
    echo "  ║              Infrastructure Setup v${AMMSIS_VERSION}  ║"
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo -e "${CLR_RESET}"
}
