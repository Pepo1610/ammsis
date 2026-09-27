# AMMSIS — Automated Multi-Machine System Infrastructure Setup

**Versione 5.0.0**

AMMSIS è uno strumento a riga di comando che automatizza la creazione e la configurazione di un ambiente distribuito **Vagrant + Ansible**, progettato per simulare scenari reali di amministrazione di sistema in ambito didattico.

---

## Indice

- [Panoramica](#panoramica)
- [Roadmap](#roadmap)
- [Prerequisiti](#prerequisiti)
- [Quick Start](#quick-start)
- [Utilizzo Dettagliato](#utilizzo-dettagliato)
  - [Modalità Setup (Wizard Interattivo)](#modalità-setup-wizard-interattivo)
  - [Modalità Consegna (--maketar)](#modalità-consegna---maketar)
  - [Help](#help)
- [Nomenclatura VM](#nomenclatura-vm)
- [Supporto DHCP](#supporto-dhcp)
- [Struttura dei File Generati](#struttura-dei-file-generati)
- [Componenti Ansible](#componenti-ansible)
- [Architettura dello Script](#architettura-dello-script)
- [Troubleshooting](#troubleshooting)

---

## Panoramica

AMMSIS permette di:

1. **Definire interattivamente** una topologia di rete composta da client (WKS), server (SRV) e router (ROU)
2. **Scegliere la modalità di rete** per client e server: **DHCP** o **IP statico** (con supporto a pool DHCP multipli per-router sulla stessa rete)
3. **Configurare componenti complessi** interattivamente: LDAP (con supporto lettura/scrittura, file credenziali separato, variabili d'ambiente protette e GECOS opzionale), utenti locali, SNMP, Logger (rsyslog), Cron jobs (multi-macchina e intervallo in secondi) e SSH passwordless tra nodi omogenei
4. **Generare automaticamente** un `Vagrantfile` parametrizzato con loop Ruby
5. **Generare `group_vars/all.yml` e `host_vars/`** con variabili dinamiche
6. **Copiare intelligentemente** solo i componenti Ansible necessari dalla cartella `componenti/` nella struttura `roles/`
7. **Avviare le VM** con `vagrant up`
8. **Generare un `site.yml` pulito**, contenente solo i play e i ruoli effettivamente richiesti dalla configurazione
9. **Salvare e riutilizzare** le scelte immesse per saltare il wizard alle esecuzioni successive
10. **Creare uno script di consegna** (`maketar.sh`) per raccogliere file dalle VM via SCP

Il progetto adotta un'architettura modulare: la logica è distribuita in moduli specifici all'interno della directory `lib/`, mantenendo il punto di ingresso in `ammsis.sh` leggero e facilmente manutenibile. Il launcher `ammsis_master.sh` è incluso come alias compatibile e inoltra tutti gli argomenti a `ammsis.sh`.

---

## Roadmap

| Versione | Data | Highlights |
|----------|------|------------|
| **5.0.0** | 2026-09-27 | Architettura modulare (`lib/`), fix sicurezza credenziali LDAP, licenza MIT |
| **4.1.0** | — | Credenziali LDAP su file separato, cronjob multi-macchina con intervallo secondi |
| **4.0.1** | — | Risoluzione collisioni IP, fix creazione utente locale |
| **4.0.0** | — | Utenti locali illimitati, sudo esplicito, cron job illimitati, componenti autoriparanti |
| **3.4.0** | — | DHCP multi-router, GECOS opzionale, client LDAP R/W, SSH passwordless |
| **3.3.1** | — | Rimozione commenti docente, site.yml pulito |
| **3.3.0** | — | Rotte statiche cross-subnet corrette, supporto 'ud' range DHCP |
| **3.2.1** | — | Fix caricamento scelte |
| **3.2.0** | — | Copia intelligente ruoli, site.yml pulito, logger rsyslog, cron, validazione DHCP |
| **3.1.1** | — | Fix SNMP template, fix LDAP flush_handlers |
| **3.1.0** | — | Fix percorsi componenti, LDAP interattiva, SNMP interattiva, group/host_vars |
| **3.0.0** | — | Supporto DHCP, Vagrantfile parametrizzato, rinomina VM |

> Per il dettaglio completo di ogni versione, consulta il [CHANGELOG](CHANGELOG.md).

---

## Prerequisiti

| Software     | Versione Minima | Note                                  |
|-------------|----------------|---------------------------------------|
| **Bash**     | 4.0+           | Necessario per array associativi      |
| **Vagrant**  | 2.3+           | Gestione delle macchine virtuali      |
| **VirtualBox** | 6.1+         | Provider di virtualizzazione          |
| **SSH**      | —              | Per la comunicazione con le VM        |

> **Nota**: Ansible verrà configurato come provisioner all'interno delle VM, non è richiesto sull'host.

---

## Quick Start

```bash
# 1. Clona o scarica il progetto
cd ammsis_master/

# 2. Rendi eseguibile lo script
chmod +x ammsis.sh

# 3. Avvia il wizard interattivo (la prima volta)
./ammsis.sh

# 4. Segui le istruzioni a schermo per configurare la topologia
# (A fine processo verrà generato un file `scelte.txt`)

# 5. Se devi rigenerare lo stesso ambiente senza rifare il wizard:
./ammsis.sh scelte.txt

# 6. Quando hai finito di lavorare, crea l'archivio di consegna
./ammsis.sh --maketar
```

---

## Utilizzo Dettagliato

### Modalità Setup (Wizard Interattivo)

```bash
./ammsis.sh
```

Lanciando lo script senza argomenti, si avvia un **wizard interattivo** che guida l'utente nella definizione dell'ambiente:

#### Passo 1 — Configurazione Router

```
──────────────────────────────────────────────────────────
  Configurazione ROUTER
──────────────────────────────────────────────────────────
  Quanti router vuoi creare?: 1

  ── ROU1 ──
    Numero di interfacce di rete per ROU1 [2]: 2
      Numero della scheda di rete per l'interfaccia 1 [1]: 1
    ── Interfaccia eth1 ──
      IP per eth1 di ROU1: 10.30.5.1
      Nome segmento intnet per eth1 [NET1]: NET1
      Numero della scheda di rete per l'interfaccia 2 [2]: 2
    ── Interfaccia eth2 ──
      IP per eth2 di ROU1: 192.168.77.1
      Nome segmento intnet per eth2 [NET2]: NET2
```

#### Passo 2 — Proxy Lab

```
  Sei in laboratorio ingegneria? (abilita proxy_lab) [S/n]: n
```

#### Passo 3 — Configurazione Client (DHCP)

```
──────────────────────────────────────────────────────────
  Configurazione RETE CLIENT
──────────────────────────────────────────────────────────
  Subnet della rete dei client (1-32, es. 24 per /24): 24
  [INFO]  Subnet mask client: 255.255.255.0

  Modalità di rete per i client:
    1) DHCP  — IP assegnato dinamicamente dal router
    2) Statico — IP configurato manualmente
  Scegli [1/2] [1]: 1

  Configurazione DHCP per la rete dei client:
    Rete e subnet dei client (es. 192.168.2.0/24): 10.30.5.0/24
    Inizio range IP DHCP (es. 192.168.2.100): 10.30.5.100
    Fine range IP DHCP (es. 192.168.2.200): 10.30.5.200

──────────────────────────────────────────────────────────
  Configurazione CLIENT (DHCP)
──────────────────────────────────────────────────────────
  Quanti client vuoi creare?: 1
  Segmento intnet per i client [NET1]: NET1
  Numero scheda di rete per i client (es. 1 per eth1) [1]: 1
```

#### Passo 4 — Configurazione Server (IP Statico)

```
──────────────────────────────────────────────────────────
  Configurazione RETE SERVER
──────────────────────────────────────────────────────────
  Subnet della rete dei server (1-32, es. 28 per /28): 28
  [INFO]  Subnet mask server: 255.255.255.240

  Modalità di rete per i server:
    1) DHCP  — IP assegnato dinamicamente dal router
    2) Statico — IP configurato manualmente
  Scegli [1/2] [1]: 2

──────────────────────────────────────────────────────────
  Configurazione SERVER (IP Statico)
──────────────────────────────────────────────────────────
  Quanti server vuoi creare?: 2

  ── SRV1 ──
    Numero di interfacce di rete per SRV1 [1]: 1
      IP per eth1 di SRV1: 192.168.77.2
      Nome segmento intnet per eth1 [NET1]: NET2

  ── SRV2 ──
    Numero di interfacce di rete per SRV2 [1]: 1
      IP per eth1 di SRV2: 192.168.77.3
      Nome segmento intnet per eth1 [NET1]: NET2
```

#### Passo 5 — Riepilogo e Conferma

```
  ╔═══════════════════════════════════════════════════════╗
  ║              RIEPILOGO TOPOLOGIA DI RETE             ║
  ╚═══════════════════════════════════════════════════════╝

  ROUTER (1):
    ROU1: 2 interfacce
      eth1: 10.30.5.1  [intnet: NET1]
      eth2: 192.168.77.1  [intnet: NET2]

  CLIENT (1) — Modalità: DHCP
    Rete DHCP: 10.30.5.0/24
    Range: 10.30.5.100 — 10.30.5.200
    Subnet: /24 (255.255.255.0)
    WKS1: DHCP [intnet: NET1]

  SERVER (2) — Modalità: STATICO
    Subnet: /28 (255.255.255.240)
    SRV1: 1 interfacce
      eth1: 192.168.77.2  [intnet: NET2]
    SRV2: 1 interfacce
      eth1: 192.168.77.3  [intnet: NET2]
──────────────────────────────────────────────────────────
  Confermi questa configurazione? [S/n]:
```

#### Passo 6 — Esecuzione Automatica

Dopo la conferma, lo script esegue in sequenza:

1. **Generazione Vagrantfile** — Crea il file Ruby parametrizzato con loop
2. **Setup Ansible** — Copia i componenti dalla cartella `componenti/` in `roles/`, configura i file di rete con i dati dell'utente, genera `site.yml`
3. **Vagrant Up** — Avvia tutte le macchine virtuali
4. **Generazione maketar.sh** — Crea lo script di consegna con la mappa VM

---

### Modalità Consegna (--maketar)

```bash
./ammsis.sh --maketar [opzioni]
```

Invoca lo script `maketar.sh` (generato durante il setup) per raccogliere file dalle VM via SCP e creare un archivio tar di consegna.

**Opzioni disponibili:**

| Flag | Descrizione |
|------|-------------|
| `-h`, `--help` | Mostra l'aiuto |
| `-d`, `--dry-run` | Simula l'esecuzione senza scaricare file |
| `-v`, `--verbose` | Attiva il debug avanzato (output SCP dettagliato) |
| `-n NOME`, `--name NOME` | Nome personalizzato per l'archivio (default: `ammsis.tar.gz`) |

**Esempi:**

```bash
# Esegui la consegna con output verboso
./ammsis.sh --maketar -v

# Simulazione senza download (verifica struttura)
./ammsis.sh --maketar -d

# Archivio con nome personalizzato
./ammsis.sh --maketar -n esame_2025.tar.gz
```

> **Nota**: Prima di usare `--maketar`, devi configurare i file da scaricare modificando la sezione **"AREA DI DOWNLOAD"** all'interno del file `maketar.sh` generato.

---

### Help

```bash
./ammsis.sh --help
```

Mostra una guida sintetica con tutte le modalità e opzioni disponibili.

---

## Nomenclatura VM

| Tipo | Prefisso | Esempio |
|------|----------|---------|
| Client (Workstation) | `WKS` | WKS1, WKS2, WKS3 |
| Router | `ROU` | ROU1, ROU2 |
| Server | `SRV` | SRV1, SRV2 |

---

## Supporto DHCP

### Flusso DHCP

1. Lo script configura prima i **router** con IP statici
2. Chiede la **subnet CIDR** della rete client (1-32) → convertita automaticamente in netmask
3. Chiede se i client usano **DHCP** o **IP statico**
4. Se DHCP, raccoglie:
   - Rete + subnet in notazione CIDR (es. `192.168.2.0/24`)
   - Estremo sinistro del range IP
   - Estremo destro del range IP
   - Rotta verso un'altra rete (solo se >1 router)
5. Ripete lo stesso procedimento per i server

### Cosa configura lo script

| File | Contenuto |
|------|-----------|
| `roles/net_dhcp_server/files/dnsmasq.conf` | Range DHCP, interfacce, rotte statiche (option 121) |
| `roles/net_dhcp_client/files/eth1dhcp` | Configurazione interfaccia DHCP per client |
| `roles/net_rouX/files/ethN` | IP statico e netmask per ogni interfaccia del router |
| `roles/net_srvX/files/ethN` | IP statico, netmask e rotta statica per server (se statico) |

### Tabella conversione CIDR

| CIDR | Netmask |
|------|---------|
| /8 | 255.0.0.0 |
| /16 | 255.255.0.0 |
| /24 | 255.255.255.0 |
| /25 | 255.255.255.128 |
| /26 | 255.255.255.192 |
| /27 | 255.255.255.224 |
| /28 | 255.255.255.240 |
| /29 | 255.255.255.248 |
| /30 | 255.255.255.252 |

---

## Struttura dei File Generati

Dopo il setup, la directory conterrà:

```
ammsis_master/
├── ammsis.sh              ← Script principale (questo file)
├── componenti/            ← Componenti Ansible sorgente (non modificati)
├── Vagrantfile            ← Configurazione VM parametrizzata (generato)
├── maketar.sh             ← Script di consegna (generato)
├── site.yml               ← Playbook Ansible principale (generato)
└── roles/                 ← Struttura Ansible (generata e configurata)
    ├── common/            ← Ruolo condiviso (fix auto eth0)
    ├── proxy_lab/         ← Proxy per lab ingegneria (se abilitato)
    ├── net_rou1/          ← Rete router 1 (configurato con IP)
    │   ├── files/
    │   │   ├── eth1       ← IP e netmask configurati
    │   │   └── eth2       ← IP e netmask configurati
    │   ├── handlers/
    │   │   └── main.yml
    │   └── tasks/
    │       └── main.yml
    ├── net_dhcp_server/   ← Server DHCP (dnsmasq configurato)
    │   ├── files/
    │   │   └── dnsmasq.conf  ← Range, interfacce, rotte configurati
    │   ├── handlers/
    │   └── tasks/
    ├── net_ipforward/     ← Abilitazione IP forwarding
    ├── net_dhcp_client/   ← Client DHCP (se client in DHCP)
    ├── net_srv1/          ← Rete server 1 statica (se statico)
    ├── net_srv2/          ← Rete server 2 statica (se statico)
    ├── ldap_utils/
    ├── ldap_creds/
    ├── ldap_server/
    ├── create_ldap_user/
    ├── ldap_login/
    ├── rsyslog/
    ├── create_dir/
    ├── snmp_agent/
    ├── snmp_manager/
    ├── sudoers/
    ├── ssh_keys/
    ├── ssh_authkeys/
    ├── at_atd/
    ├── systemd_service/
    ├── cron/
    ├── install_script_server/
    └── install_script_client/
```

---

## Componenti Ansible

Lo script copia automaticamente i componenti dalla cartella `componenti/` nella struttura `roles/`. I componenti che riguardano la rete vengono **configurati automaticamente** con i dati immessi dall'utente. Tutti gli altri componenti vengono copiati **così come sono**, pronti per essere personalizzati manualmente in base alla consegna d'esame.

### Componenti configurati automaticamente dallo script (in base al wizard)

| Componente | Ruolo | Configurazione Automatica |
|-----------|-------|----------------|
| `rete/net_router` | `net_rouX` | IP e netmask per ogni interfaccia del router |
| `rete/net_dhcp_server` | `net_dhcp_server` / `net_dhcp_server_rouX` | dnsmasq.conf con range, interfacce, rotte (per-router se multi-router) |
| `rete/net_dhcp_client` | `net_dhcp_client` | Interfaccia DHCP per client |
| `rete/net_server` | `net_srvX` | IP, netmask e rotta statica per server |
| `ldap/*` | `ldap_*`, `ldap_login`, `ldap_utils`, `ldap_creds` | Server, Dominio, Utenti (con GECOS opzionale), Gruppi, Client login e Client lettura/scrittura |
| `ldap/ldap_admin_cred_file` | `ldap_admin_cred_file` | File credenziali admin su macchine scelte (permessi 0400, 2 sole righe) e variabili env protette (`LDAP_ADMIN_USER`, `LDAP_PASSWD`) in `/etc/profile.d/ldap_admin.sh` |
| `snmp/*` | `snmp_agent`, `snmp_manager` | Community, View e Loop direttive `extend` |
| `syslog/rsyslog` | `rsyslog` | (Se Logger abilitato) regola facility → file |
| `filesystem/create_user` | `local_user_N` | Utenti locali, gruppi, home, shell, password e sudoers |
| `automazione/cron` | `cron_job_N` | Uno o più job su singola o più macchine contemporaneamente: comando, timing periodico e/o boot/reboot |
| `automazione/cron_loop` | `cron_loop_N` | Script wrapper bash `/usr/local/bin/<nome-script>_loop.sh` con ciclo while e sleep per esecuzione a intervallo in secondi |
| `ssh/*` | `ssh_keys_*`, `ssh_authkeys_*` | (Se SSH passwordless abilitato) accesso con chiavi dedicate tra client o tra server |

### Componenti da configurare manualmente (da aggiungere a mano in site.yml se non configurati dal wizard)

| Componente | Ruolo | Note |
|-----------|-------|------|
| `installa_script` | `install_script_server/client` | Aggiungere gli script in `files/` |
| `automazione/*` | `systemd_service`, `at_atd` | Configurare in base alla consegna |
| `ssh/*` | `ssh_keys`, `ssh_authkeys` | Configurati in automatico se abilitato SSH passwordless |
| `filesystem/*` | `create_dir`, `sudoers` | Configurare percorsi e permessi |

---

## Architettura dello Script

Il progetto è organizzato in modo modulare con 22 moduli sotto `lib/`:

| Modulo | Descrizione |
|--------|-------------|
| `constants.sh` | Costanti, colori e configurazioni |
| `logging.sh` | Funzioni per log formattati |
| `validation.sh` | Validazione IP, CIDR, ecc. |
| `network.sh` | Funzioni di calcolo e utilità di rete |
| `state.sh` | Stato globale e variabili del progetto |
| `prompt.sh` | Funzioni per gestire gli input utente |
| `wizard_topology.sh` | Configurazione topologia di rete |
| `wizard_ldap.sh` | Configurazione LDAP |
| `wizard_users.sh` | Configurazione utenti locali |
| `wizard_snmp.sh` | Configurazione SNMP |
| `wizard_logger.sh` | Configurazione rsyslog |
| `wizard_cron.sh` | Configurazione cron jobs |
| `wizard_ssh.sh` | Configurazione SSH passwordless |
| `wizard_main.sh` | Punti di unione e flusso generale |
| `generate_vagrantfile.sh` | Generazione del `Vagrantfile` parametrizzato |
| `generate_ansible.sh` | Generazione `site.yml` e ruoli |
| `generate_maketar.sh` | Creazione script `maketar.sh` |
| `vagrant.sh` | Gestione di `vagrant up` |
| `maketar_mode.sh` | Funzionalità di invio in modalità consegna |
| `help.sh` | Schermata di aiuto e uso |
| `choices.sh` | Caricamento e salvataggio scelte utente |
| `orchestrator.sh` | Main loop e coordinamento passaggi |

---

## Troubleshooting

### "vagrant up" fallisce

- Verifica che **VirtualBox** sia installato e funzionante
- Controlla che la box `debian/bookworm64` sia disponibile: `vagrant box list`
- Se manca, scaricala: `vagrant box add debian/bookworm64`

### maketar.sh non trovato

Questo file viene generato automaticamente durante il setup. Esegui prima:
```bash
./ammsis.sh
```

### Errore "declare -A: invalid option"

Il tuo Bash è troppo vecchio. AMMSIS richiede **Bash 4.0+** per gli array associativi.
Verifica con: `bash --version`

### Le VM non sono raggiungibili via SSH

1. Verifica che le VM siano accese: `vagrant status`
2. Controlla gli IP configurati: `vagrant ssh <nome_vm> -c "ip addr"`
3. Assicurati di aver distribuito le chiavi SSH: `ssh-copy-id root@<IP>`

### Nessun file scaricato con --maketar

Devi configurare manualmente la sezione **"AREA DI DOWNLOAD"** dentro `maketar.sh` con i percorsi dei file da raccogliere. Esempio:

```bash
fetch_file "WKS1" "/etc/network/interfaces" "attivita1/WKS1/etc/network"
fetch_file "SRV1" "/etc/bind/named.conf"    "attivita2/SRV1/etc/bind"
fetch_file "ROU1" "/etc/dnsmasq.conf"       "attivita3/ROU1/etc"
```

### I client DHCP non ricevono un IP

1. Verifica che il router sia acceso e che dnsmasq sia in esecuzione: `vagrant ssh ROU1 -c "systemctl status dnsmasq"`
2. Controlla il file di configurazione: `vagrant ssh ROU1 -c "cat /etc/dnsmasq.conf"`
3. Verifica che il client sia sulla stessa rete intnet del router

---

## Licenza

Distribuito sotto licenza [MIT](LICENSE).
