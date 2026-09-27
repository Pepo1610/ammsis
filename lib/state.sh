# =============================================================================
#  AMMSIS — lib/state.sh
#  Global state and data structures for network topology
# =============================================================================

# Array paralleli per memorizzare la topologia raccolta dal wizard.
# Ogni tipo di nodo (client, server, router) ha:
#   - Un array di IP per interfaccia (separati da ";", es. "172.21.0.10;172.22.0.10")
#   - Un array di nomi di segmento intnet per interfaccia (separati da ";")
#   - Un array del numero di interfacce

declare -a CLIENT_IPS=()
declare -a CLIENT_NETS=()
declare -a CLIENT_IFACES=()
declare -a CLIENT_IFACE_IDS=()
declare -a SERVER_IPS=()
declare -a SERVER_NETS=()
declare -a SERVER_IFACES=()
declare -a SERVER_IFACE_IDS=()
declare -a ROUTER_IPS=()
declare -a ROUTER_NETS=()
declare -a ROUTER_IFACES=()
declare -a ROUTER_IFACE_IDS=()

NUM_CLIENTS=0
NUM_SERVERS=0
NUM_ROUTERS=0

# Modalità rete per client e server: "dhcp" o "static"
CLIENT_NET_MODE="static"
SERVER_NET_MODE="static"

# Subnet CIDR (numero 1-32) per la rete client e server
CLIENT_SUBNET_CIDR=""
SERVER_SUBNET_CIDR=""
CLIENT_SUBNET_MASK=""
SERVER_SUBNET_MASK=""

# Dati DHCP per la rete client (se DHCP) — usati con 1 solo router
CLIENT_DHCP_NETWORK=""       # es. "192.168.2.0/24"
CLIENT_DHCP_NET_ADDR=""      # es. "192.168.2.0"
CLIENT_DHCP_RANGE_START=""
CLIENT_DHCP_RANGE_END=""
CLIENT_DHCP_SERVER_ROUTE=""  # rete+subnet dei server o IP di un altro router

# Dati DHCP per la rete server (se DHCP) — usati con 1 solo router
SERVER_DHCP_NETWORK=""
SERVER_DHCP_NET_ADDR=""
SERVER_DHCP_RANGE_START=""
SERVER_DHCP_RANGE_END=""
SERVER_DHCP_CLIENT_ROUTE=""

# Dati DHCP per-router (usati con 2+ router sulla stessa rete)
# Ogni posizione nell'array corrisponde al router con lo stesso indice
declare -a ROUTER_DHCP_CLIENT_NETWORK=()      # es. "172.21.64.0/18"
declare -a ROUTER_DHCP_CLIENT_NET_ADDR=()     # es. "172.21.64.0"
declare -a ROUTER_DHCP_CLIENT_RANGE_START=()
declare -a ROUTER_DHCP_CLIENT_RANGE_END=()
declare -a ROUTER_DHCP_SERVER_NETWORK=()      # DHCP server-side per-router
declare -a ROUTER_DHCP_SERVER_NET_ADDR=()
declare -a ROUTER_DHCP_SERVER_RANGE_START=()
declare -a ROUTER_DHCP_SERVER_RANGE_END=()

# Flag per proxy lab
USE_PROXY_LAB=false

# === DATI LDAP ===
USE_LDAP=false
LDAP_SERVER_HOST=""          # nome host scelto come server LDAP (es. "ROU1")
LDAP_DOMAIN=""               # es. "labammsis"
LDAP_ORG=""                  # es. "Unibo"
LDAP_ADMIN_PASSWORD=""       # es. "gennaio.marzo"
LDAP_BASE_DN=""              # derivato: "dc=labammsis"
LDAP_ADMIN_DN=""             # derivato: "cn=admin,dc=labammsis"
declare -a LDAP_CLIENT_HOSTS=()   # hosts client LDAP (login centralizzato)
declare -a LDAP_RW_HOSTS=()       # hosts con accesso lettura/scrittura al server LDAP

# Array per utenti LDAP — ogni entry è una stringa serializzata:
# "uid;cn;sn;uidNumber;gidNumber;group;home;shell;pass;description;gecos"
declare -a LDAP_USERS=()

# Array per gruppi LDAP già creati — ogni entry: "nome;gid"
declare -a LDAP_GROUPS=()

# Array per gruppi standalone (senza utenti associati) — "nome;gid;membri_separati_da_virgola"
declare -a LDAP_STANDALONE_GROUPS=()

# File credenziali LDAP admin separato
LDAP_CRED_SEPARATE=false               # true se le credenziali vanno su file a parte
LDAP_CRED_FILENAME="ldap.admin.cred"   # nome del file (default)
LDAP_CRED_PATH="/etc/"                 # percorso di destinazione (default)
LDAP_CRED_ADMIN_USER="admin"           # nome utente admin LDAP (default)
declare -a LDAP_CRED_HOSTS=()          # macchine su cui deployare il file

# === DATI UTENTI LOCALI ===
# Ogni voce: host|nome|commento|uid|gruppo|gid|gruppi_secondari|shell|home|
#             crea_home|password|sudo_abilitato|sudo_nopasswd
declare -a LOCAL_USERS=()

# === DATI SNMP ===
USE_SNMP=false
declare -a SNMP_AGENT_HOSTS=()     # hosts agenti SNMP
# Array extend per agente: "host_name:nome_extend:comando"
declare -a SNMP_AGENT_EXTENDS=()
declare -a SNMP_MANAGER_HOSTS=()   # hosts manager SNMP
SNMP_CUSTOM_COMMUNITY=""           # community string custom (vuoto = default 'public')
SNMP_CUSTOM_VIEW=""                # view name custom (vuoto = default 'all')

# === DATI LOGGER ===
USE_LOGGER=false
declare -a LOGGER_HOSTS=()         # hosts che ricevono e archiviano i log
LOGGER_FACILITY=""                 # es. "local1.info"
LOGGER_FILE_PATH=""                # es. "/var/log/nome-file"

# === DATI CRON ===
USE_CRON=false
# Ogni voce: hosts(separati da virgola)|boot|periodico|minuto|ora|giorni|utente|comando|secondi
declare -a CRON_JOBS=()
# Variabili legacy mantenute solo per ricaricare scelte generate da v3.x.
CRON_HOST=""
CRON_AT_REBOOT=false
CRON_MINUTE=""
CRON_HOUR=""
CRON_DOW=""
CRON_USER=""

# === DATI SSH PASSWORDLESS ===
USE_SSH_PASSWORDLESS_CLIENTS=false
USE_SSH_PASSWORDLESS_SERVERS=false
SSH_PASSWORDLESS_CLIENT_USER="root"   # utente SSH per accesso tra client
SSH_PASSWORDLESS_SERVER_USER="root"   # utente SSH per accesso tra server
