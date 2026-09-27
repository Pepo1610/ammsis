# =============================================================================
#  AMMSIS — lib/generate_maketar.sh
#  Function to generate maketar.sh script
# =============================================================================

generate_maketar_script() {
    log_step "4" "Generazione dello script di consegna (maketar.sh)..."

    local outfile="maketar.sh"

    # Costruisci il blocco dichiarativo dell'array associativo VM_IPS
    local vm_ips_block=""
    local i first_ip

    # Router
    for (( i = 0; i < NUM_ROUTERS; i++ )); do
        IFS=';' read -ra _tmp_ips <<< "${ROUTER_IPS[$i]}"
        first_ip="${_tmp_ips[0]}"
        vm_ips_block+="    [\"ROU$((i+1))\"]=\"${first_ip}\""$'\n'
    done

    # Client
    for (( i = 0; i < NUM_CLIENTS; i++ )); do
        if [[ "$CLIENT_NET_MODE" == "dhcp" ]]; then
            vm_ips_block+="    # [\"WKS$((i+1))\"]=\"DHCP — IP dinamico, usa 'vagrant ssh WKS$((i+1)) -c ip addr' per scoprirlo\""$'\n'
        else
            IFS=';' read -ra _tmp_ips <<< "${CLIENT_IPS[$i]}"
            first_ip="${_tmp_ips[0]}"
            vm_ips_block+="    [\"WKS$((i+1))\"]=\"${first_ip}\""$'\n'
        fi
    done

    # Server
    for (( i = 0; i < NUM_SERVERS; i++ )); do
        if [[ "$SERVER_NET_MODE" == "dhcp" ]]; then
            vm_ips_block+="    # [\"SRV$((i+1))\"]=\"DHCP — IP dinamico, usa 'vagrant ssh SRV$((i+1)) -c ip addr' per scoprirlo\""$'\n'
        else
            IFS=';' read -ra _tmp_ips <<< "${SERVER_IPS[$i]}"
            first_ip="${_tmp_ips[0]}"
            vm_ips_block+="    [\"SRV$((i+1))\"]=\"${first_ip}\""$'\n'
        fi
    done

    # Genera il file maketar.sh completo
    cat <<'MAKETAR_HEADER' > "$outfile"
#!/bin/bash
# =============================================================================
# MAKETAR — Script di Consegna AMMSIS
# =============================================================================
# Generato automaticamente da ammsis.sh
# Raccoglie file dalle VM via SCP e crea un archivio tar per la consegna.
# =============================================================================

# Colori ANSI
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Valori di default
ARCHIVE_NAME="ammsis.tar.gz"
TARGET_DIR="esame"
DRY_RUN=false
VERBOSE=false

# ==========================================
# FUNZIONE DI USAGE
# ==========================================
usage() {
    echo -e "${BLUE}=================================================================${NC}"
    echo -e "USO: $0 [OPZIONI]"
    echo -e "${BLUE}=================================================================${NC}"
    echo "Opzioni disponibili:"
    echo "  -h, --help           Mostra questo aiuto ed esce."
    echo "  -d, --dry-run        Simula l'esecuzione senza scaricare file."
    echo "  -v, --verbose        Attiva il debug avanzato (mostra l'output di scp)."
    echo "  -n, --name NOME      Specifica il nome dell'archivio (Default: ammsis.tar.gz)."
    echo ""
    echo "Esempi:"
    echo "  $0 -v                Esegue lo script mostrando i dettagli di rete."
    echo "  $0 -d                Verifica la struttura senza scaricare file."
    echo -e "${BLUE}=================================================================${NC}"
    exit 1
}

# ==========================================
# PARSING DEGLI ARGOMENTI
# ==========================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -n|--name)
            if [[ -n "$2" && "$2" != -* ]]; then
                ARCHIVE_NAME="$2"
                shift 2
            else
                echo -e "${RED}[!] Errore: L'opzione --name richiede un valore.${NC}"
                usage
            fi
            ;;
        *)
            echo -e "${RED}[!] Opzione sconosciuta: $1${NC}"
            usage
            ;;
    esac
done

MAKETAR_HEADER

    # Inietta la mappa IP dinamica
    cat <<MAKETAR_IPS >> "$outfile"
# Mappa delle VM — generata dinamicamente da ammsis.sh
declare -A VM_IPS=(
${vm_ips_block})

MAKETAR_IPS

    # Corpo delle funzioni e logica di esecuzione
    cat <<'MAKETAR_BODY' >> "$outfile"
# ==========================================
# FUNZIONE DI COPIA CON CONTROLLO ERRORI
# ==========================================
fetch_file() {
    local vm="$1"
    local remote_path="$2"
    local dest_subfolder="$3"
    local ip="${VM_IPS[$vm]}"

    # Gestione Dry-Run
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Mappatura: ${vm} (${ip}) -> ${remote_path}"
        return 0
    fi

    echo -e "${YELLOW}[...] Elaborazione host [${vm}] (${ip})...${NC}"

    # Pre-flight Check: La VM è raggiungibile su SSH?
    ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o PasswordAuthentication=no \
        "root@${ip}" "true" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "    ${RED}[X] ERRORE RETE:${NC} Impossibile connettersi via SSH a ${vm} (${ip})."
        echo -e "        -> Verifica: La VM è accesa? L'IP è corretto? Hai distribuito le chiavi?"
        return 1
    fi

    # Configurazione verbosità SCP
    local scp_opts="-o StrictHostKeyChecking=no"
    if [ "$VERBOSE" = true ]; then
        scp_opts="${scp_opts} -v"
        echo -e "    ${BLUE}[DEBUG] Avvio scp in modalità verbosa per: ${remote_path}${NC}"
    else
        scp_opts="${scp_opts} -q"
    fi

    # Creazione cartella locale e download
    mkdir -p "${TARGET_DIR}/${dest_subfolder}"
    scp $scp_opts "root@${ip}:${remote_path}" \
        "${TARGET_DIR}/${dest_subfolder}/$(basename "$remote_path")"
    local scp_status=$?

    if [ $scp_status -eq 0 ]; then
        echo -e "    ${GREEN}[✓] SUCCESS:${NC} ${remote_path} scaricato correttamente."
        return 0
    else
        echo -e "    ${RED}[X] ERRORE SCP (Codice: $scp_status):${NC} Fallito il download di ${remote_path}."
        echo -e "        -> Verifica: Il file esiste sul server remoto?"
        return 1
    fi
}

# ==========================================
# LOGICA DI ESECUZIONE PRINCIPALE
# ==========================================
echo -e "${BLUE}=== AVVIO SCRIPT DI CONSEGNA (Verbosità: ${VERBOSE} | DryRun: ${DRY_RUN}) ===${NC}"

if [ "$DRY_RUN" = false ]; then
    rm -rf "$TARGET_DIR" "$ARCHIVE_NAME"
    mkdir -p "$TARGET_DIR"
fi

# --- AREA DI DOWNLOAD ---
# Modifica i percorsi qui sotto in base alla traccia d'esame:
# Esempio:
#   fetch_file "WKS1" "/etc/network/interfaces" "attivita1/WKS1/etc/network"
#   fetch_file "SRV1" "/etc/network/interfaces" "attivita1/SRV1/etc/network"
#   fetch_file "ROU1" "/etc/dnsmasq.conf"       "attivita2/ROU1/etc"

echo -e "${YELLOW}[NOTA] Nessun file configurato per il download.${NC}"
echo -e "${YELLOW}       Modifica la sezione 'AREA DI DOWNLOAD' in maketar.sh${NC}"
echo -e "${YELLOW}       per specificare i file da raccogliere dalle VM.${NC}"

# --- CREAZIONE ARCHIVIO ---
if [ "$DRY_RUN" = false ]; then
    if [ -d "$TARGET_DIR" ] && [ "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}[...] Compilazione dell'archivio ${ARCHIVE_NAME}...${NC}"
        cd "$TARGET_DIR" || exit 1

        if [[ "$ARCHIVE_NAME" == *.tar.gz || "$ARCHIVE_NAME" == *.tgz ]]; then
            tar -czf "../$ARCHIVE_NAME" *
        else
            tar -cf "../$ARCHIVE_NAME" *
        fi

        cd ..
        echo -e "${GREEN}=== OPERAZIONE COMPLETATA! Archivio [${ARCHIVE_NAME}] pronto. ===${NC}"
    else
        echo -e "${YELLOW}[NOTA] La cartella di stage è vuota. Nessun archivio creato.${NC}"
        echo -e "${YELLOW}       Configura prima i download nella sezione 'AREA DI DOWNLOAD'.${NC}"
    fi
else
    echo -e "${BLUE}=== FINE SIMULAZIONE DRY-RUN ===${NC}"
fi
MAKETAR_BODY

    chmod +x "$outfile"
    log_success "Script di consegna '${outfile}' generato con la mappa IP dinamica."
}
