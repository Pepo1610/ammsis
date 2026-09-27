# =============================================================================
#  AMMSIS — lib/maketar_mode.sh
#  Function to run maketar mode
# =============================================================================

run_maketar_mode() {
    local maketar_script="./maketar.sh"

    if [[ ! -f "$maketar_script" ]]; then
        log_error "maketar.sh non trovato! Esegui prima './ammsis.sh' per generare l'ambiente."
        exit 1
    fi

    log_info "Invocazione dello script di consegna..."
    exec "$maketar_script" "$@"
}
