# =============================================================================
#  AMMSIS — lib/constants.sh
#  Global configuration and constants
# =============================================================================

readonly AMMSIS_VERSION="5.0.0"
readonly VAGRANTFILE_NAME="Vagrantfile"
readonly DEFAULT_ARCHIVE_NAME="ammsis.tar.gz"
readonly DEFAULT_TARGET_DIR="esame"
readonly DEFAULT_BOX="debian/bookworm64"

# Risoluzione posizione dello script e dell'utente
# Permette di lanciare ammsis.sh da qualsiasi directory
readonly USER_CWD="$(pwd)"
readonly AMMSIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly COMPONENTI_DIR="${AMMSIS_SCRIPT_DIR}/componenti"
readonly ROLE_GENERATOR="${AMMSIS_SCRIPT_DIR}/genera_roles.sh"

# Catalogo canonico delle componenti Ansible disponibili. Il controllo
# all'avvio considera non disponibile anche una componente con file corrotti.
declare -a EXPECTED_COMPONENTS=(
    "automazione/at_atd" "automazione/cron" "automazione/cron_loop" "automazione/systemd_service"
    "filesystem/create_dir" "filesystem/create_user" "filesystem/proxy_lab"
    "filesystem/sudoers" "installa_script"
    "ldap/create_ldap_user" "ldap/ldap_admin_cred_file" "ldap/ldap_create_group" "ldap/ldap_creds"
    "ldap/ldap_login" "ldap/ldap_server" "ldap/ldap_utils"
    "rete/net_dhcp_client" "rete/net_dhcp_server" "rete/net_ipforward"
    "rete/net_router" "rete/net_server"
    "snmp/snmp_agent" "snmp/snmp_manager"
    "ssh/ssh_authkeys" "ssh/ssh_keys" "syslog/rsyslog"
)

# Colori ANSI per output strutturato
readonly CLR_GREEN='\033[0;32m'
readonly CLR_RED='\033[0;31m'
readonly CLR_YELLOW='\033[1;33m'
readonly CLR_BLUE='\033[0;34m'
readonly CLR_CYAN='\033[0;36m'
readonly CLR_BOLD='\033[1m'
readonly CLR_DIM='\033[2m'
readonly CLR_RESET='\033[0m'

# Mappa CIDR prefix → subnet mask (popolata in init)
declare -A CIDR_TO_NETMASK=()

# Funzione di inizializzazione per la mappa CIDR
_init_cidr_map() {
    CIDR_TO_NETMASK[1]="128.0.0.0"
    CIDR_TO_NETMASK[2]="192.0.0.0"
    CIDR_TO_NETMASK[3]="224.0.0.0"
    CIDR_TO_NETMASK[4]="240.0.0.0"
    CIDR_TO_NETMASK[5]="248.0.0.0"
    CIDR_TO_NETMASK[6]="252.0.0.0"
    CIDR_TO_NETMASK[7]="254.0.0.0"
    CIDR_TO_NETMASK[8]="255.0.0.0"
    CIDR_TO_NETMASK[9]="255.128.0.0"
    CIDR_TO_NETMASK[10]="255.192.0.0"
    CIDR_TO_NETMASK[11]="255.224.0.0"
    CIDR_TO_NETMASK[12]="255.240.0.0"
    CIDR_TO_NETMASK[13]="255.248.0.0"
    CIDR_TO_NETMASK[14]="255.252.0.0"
    CIDR_TO_NETMASK[15]="255.254.0.0"
    CIDR_TO_NETMASK[16]="255.255.0.0"
    CIDR_TO_NETMASK[17]="255.255.128.0"
    CIDR_TO_NETMASK[18]="255.255.192.0"
    CIDR_TO_NETMASK[19]="255.255.224.0"
    CIDR_TO_NETMASK[20]="255.255.240.0"
    CIDR_TO_NETMASK[21]="255.255.248.0"
    CIDR_TO_NETMASK[22]="255.255.252.0"
    CIDR_TO_NETMASK[23]="255.255.254.0"
    CIDR_TO_NETMASK[24]="255.255.255.0"
    CIDR_TO_NETMASK[25]="255.255.255.128"
    CIDR_TO_NETMASK[26]="255.255.255.192"
    CIDR_TO_NETMASK[27]="255.255.255.224"
    CIDR_TO_NETMASK[28]="255.255.255.240"
    CIDR_TO_NETMASK[29]="255.255.255.248"
    CIDR_TO_NETMASK[30]="255.255.255.252"
    CIDR_TO_NETMASK[31]="255.255.255.254"
    CIDR_TO_NETMASK[32]="255.255.255.255"
}
