#!/usr/bin/env bash
# =============================================================================
#  AMMSIS — Automated Multi-Machine System Infrastructure Setup
# =============================================================================
#  Entrypoint modulare. La logica è suddivisa nei moduli sotto lib/.
#
#  Utilizzo:
#    ./ammsis.sh                   → Wizard interattivo (setup completo)
#    ./ammsis.sh --maketar [opts]  → Modalità consegna (raccolta file + archivio)
#    ./ammsis.sh --help            → Mostra l'aiuto
#
#  Autore: AMMSIS Contributors
#  Versione: 5.0.0
# =============================================================================

set -euo pipefail

# Risolvi la directory dello script indipendentemente da dove viene lanciato
readonly _AMMSIS_ENTRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly _AMMSIS_LIB_DIR="${_AMMSIS_ENTRY_DIR}/lib"

# Verifica che la directory lib/ esista
if [[ ! -d "${_AMMSIS_LIB_DIR}" ]]; then
    echo "[ERRORE] Directory lib/ non trovata in ${_AMMSIS_ENTRY_DIR}" >&2
    exit 1
fi

# Carica tutti i moduli nell'ordine corretto di dipendenza
source "${_AMMSIS_LIB_DIR}/constants.sh"
source "${_AMMSIS_LIB_DIR}/logging.sh"
source "${_AMMSIS_LIB_DIR}/validation.sh"
source "${_AMMSIS_LIB_DIR}/network.sh"
source "${_AMMSIS_LIB_DIR}/state.sh"
source "${_AMMSIS_LIB_DIR}/prompt.sh"
source "${_AMMSIS_LIB_DIR}/wizard_topology.sh"
source "${_AMMSIS_LIB_DIR}/wizard_ldap.sh"
source "${_AMMSIS_LIB_DIR}/wizard_users.sh"
source "${_AMMSIS_LIB_DIR}/wizard_snmp.sh"
source "${_AMMSIS_LIB_DIR}/wizard_logger.sh"
source "${_AMMSIS_LIB_DIR}/wizard_cron.sh"
source "${_AMMSIS_LIB_DIR}/wizard_ssh.sh"
source "${_AMMSIS_LIB_DIR}/wizard_main.sh"
source "${_AMMSIS_LIB_DIR}/generate_vagrantfile.sh"
source "${_AMMSIS_LIB_DIR}/generate_ansible.sh"
source "${_AMMSIS_LIB_DIR}/generate_maketar.sh"
source "${_AMMSIS_LIB_DIR}/vagrant.sh"
source "${_AMMSIS_LIB_DIR}/maketar_mode.sh"
source "${_AMMSIS_LIB_DIR}/help.sh"
source "${_AMMSIS_LIB_DIR}/choices.sh"
source "${_AMMSIS_LIB_DIR}/orchestrator.sh"

# ─── Entrypoint ──────────────────────────────────────────────────────────────

main() {
    check_components_integrity
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --maketar)
            shift
            run_maketar_mode "$@"
            ;;
        "")
            run_setup
            ;;
        *)
            if [[ -f "$1" ]]; then
                run_setup "$1"
            else
                log_error "Opzione o file sconosciuto: $1"
                echo "Usa './ammsis.sh --help' per visualizzare le opzioni disponibili."
                exit 1
            fi
            ;;
    esac
}

# Avvia lo script solo se eseguito direttamente (non se importato con source)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
