#!/usr/bin/env bash
# =============================================================================
# Helper script per rigenerare manifest e payload base64 in genera_roles.sh
# Uso: ./update_genera_roles.sh [directory_componenti]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-${SCRIPT_DIR}/componenti}"
GENERA_ROLES="${SCRIPT_DIR}/genera_roles.sh"

if [[ ! -d "${TARGET_DIR}" ]]; then
    echo "Directory componenti non trovata: ${TARGET_DIR}" >&2
    exit 1
fi

if [[ ! -f "${GENERA_ROLES}" ]]; then
    echo "Script genera_roles.sh non trovato: ${GENERA_ROLES}" >&2
    exit 1
fi

echo "Rigenerazione payload tar.gz da ${TARGET_DIR}..."
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

ARCHIVE="${TEMP_DIR}/componenti.tar.gz"
tar -czf "${ARCHIVE}" -C "${SCRIPT_DIR}" "$(basename "${TARGET_DIR}")"

PAYLOAD="$(base64 < "${ARCHIVE}" | tr -d '\r\n')"

echo "Aggiornamento payload in ${GENERA_ROLES}..."
python3 - "${GENERA_ROLES}" "${PAYLOAD}" <<'PY' || perl -i -0777 -pe 's/(base64 --decode > "\$archive_file" <<'\''PAYLOAD'\''\n).*?(\nPAYLOAD)/${1}'"$PAYLOAD"'$2/s' "${GENERA_ROLES}"
import sys, re
file_path, payload = sys.argv[1], sys.argv[2]
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

pattern = r'(base64 --decode > "\$archive_file" <<\'PAYLOAD\'\n).*?(\nPAYLOAD)'
new_content = re.sub(pattern, r'\g<1>' + payload + r'\2', content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)
PY

echo "Aggiornamento completato con successo."
"${GENERA_ROLES}" --verify "${TARGET_DIR}"
echo "Verifica completata con successo."
