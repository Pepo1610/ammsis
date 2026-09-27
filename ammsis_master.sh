#!/usr/bin/env bash
# Compatibilità con il nome storico richiesto per lo script principale.
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/ammsis.sh" "$@"
