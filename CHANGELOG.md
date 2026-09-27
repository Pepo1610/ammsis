# Changelog

Tutte le modifiche rilevanti al progetto sono documentate in questo file.

## [5.0.0] 
### Changed
- Architettura modulare: lo script monolitico è stato suddiviso in 22 moduli sotto `lib/`
- README trasformato in roadmap con changelog separato

### Fixed
- File credenziali LDAP admin: le variabili d'ambiente non vengono più esposte in `/etc/profile.d/` (accessibile a tutti gli utenti). Ora risiedono in `/etc/ldap/ldap_admin_env.sh` con permessi `0400` e vengono caricate solo nella shell di root.

### Added
- Licenza MIT
- File `.gitignore` per file generati
- `CHANGELOG.md` dedicato

## [4.1.0] 
### Added
- **Credenziali LDAP di amministrazione su file separato**:
  - Subito dopo la conferma che la topologia richiede LDAP, il wizard chiede se le credenziali dell'amministratore debbano essere salvate su un file a parte.
  - In caso affermativo, richiede in sequenza:
    - Nome del file delle credenziali (default: `ldap.admin.cred`)
    - Percorso di salvataggio (default: `/etc/`)
    - Nome dell'amministratore (default: `admin`)
    - Password LDAP dell'amministratore
    - Macchine su cui distribuire il file
  - Viene creato e applicato il ruolo Ansible dedicato `ldap_admin_cred_file` (in `componenti/ldap/ldap_admin_cred_file`), che:
    1. Salva il file nel percorso specificato con permessi `0400` (sola lettura per `root`), privo di commenti e con 2 sole righe: lo username sulla prima riga e la password sulla seconda riga.
    2. Configura le variabili globali di ambiente `LDAP_ADMIN_USER` e `LDAP_PASSWD` in un file dedicato `/etc/profile.d/ldap_admin.sh` con gli stessi permessi protetti `0400`.
- **Cronjob multi-macchina con intervallo in secondi**:
  - Un singolo cron job può ora essere assegnato a più macchine contemporaneamente tramite selezione multipla.
  - Durante l'impostazione dei parametri temporali, viene chiesto se è previsto un intervallo in secondi:
    - Se **non serve**, la configurazione prosegue normalmente (richiedendo opzionalmente attivazione al boot e/o periodica con minuti, ore e giorni della settimana).
    - Se **serve**, viene richiesto l'intervallo in secondi, saltando le domande sui minuti e sulle ore (poiché l'esecuzione continua è prevista per l'intera giornata) e mantenendo la selezione dei giorni della settimana.
  - In presenza dell'intervallo in secondi, viene distribuito tramite il nuovo ruolo Ansible `cron_loop` (in `componenti/automazione/cron_loop`) uno script wrapper bash in `/usr/local/bin/<nome-script>_loop.sh` contenente il ciclo continuo:
    ```bash
    #! /bin/bash

    while true ;
    do
    	/path/assoluto/script/configurato/nel/cronjob.sh
    	sleep <numero secondi settati in precedenza>
    done
    ```
### Changed
- **Aggiornamento catalogo componenti e genera_roles.sh**:
  - Il catalogo canonico sale a 26 componenti, includendo `automazione/cron_loop` e `ldap/ldap_admin_cred_file`.
  - Aggiornato `genera_roles.sh` con i nuovi hash SHA-256 e il payload base64 rigenerato, garantendo verifica e ripristino automatico anche per le nuove componenti.

## [4.0.1] 
### Fixed
- **Risoluzione collisioni IP**: È stata aggiunta una funzione check_ip_not_assigned che garantisce l'univocità globale di qualsiasi IP assegnato all'interno del cluster (comparando il nuovo input con tutti gli IP registrati per router, client e server). Quando viene utilizzato il parametro ud (ultimo disponibile) per la configurazione del range DHCP, lo script itererà in modo decrescente (decrementando l'indirizzo) finché non trova un IP che non è mai stato assegnato, evitando così la collisione con il router. Il controllo di univocità è stato inserito anche nei prompt in cui l'utente può inserire IP statici in modo manuale.
- **Fix per la creazione Utente Locale**: È stato corretto l'errore di Ansible gid cannot be converted to int. Adesso, quando il valore di GID (o UID) viene lasciato vuoto dal prompt, lo script ammsis.sh omette direttamente il parametro in fase di generazione del file vars/main.yml. A livello del componente Ansible create_user, i filtri sono stati aggiornati a default(omit, true). Questo dice ad Ansible di ignorare esplicitamente il parametro anche qualora venisse rilevata una stringa vuota "". È stata migliorata la stabilità del ciclo di controllo dell'input per UID e GID all'interno del wizard bash per essere più chiara ed evitare bug o chiusure silenziose in caso di un input scorretto.

## [4.0.0] 
### Added
- **Utenti locali illimitati**: subito dopo LDAP il wizard consente di creare un numero arbitrario di utenti locali su qualunque VM. Per ciascun utente raccoglie host, nome, GECOS, UID/GID opzionali, gruppi, shell, home, password e appartenenza ai sudoers. Ogni configurazione genera un ruolo dedicato basato su `filesystem/create_user`, quindi più utenti possono convivere sulla stessa macchina.
- **Sudo esplicito**: per un utente sudoer viene chiesto se `sudo` debba richiedere la password; lasciando il campo vuoto viene generata la regola `NOPASSWD`, mentre un valore non vuoto richiede l'autenticazione standard.
- **Cron job illimitati**: il wizard ripete la raccolta finché non viene risposta negativa. Ogni job sceglie host, comando, utente e due attivazioni indipendenti: al boot/reboot e/o periodica. Un job senza pianificazione periodica viene quindi generato esclusivamente con `special_time: reboot`.
- **Componenti autoriparanti**: all'avvio `ammsis.sh` verifica 24 componenti, controllandone anche l'hash SHA-256. Se ne manca una o è corrotta stampa l'avviso richiesto e invoca `genera_roles.sh`, che contiene manifest, struttura e contenuto canonico e ripristina soltanto le componenti interessate. È possibile verificare o ripristinare manualmente con `bash genera_roles.sh --verify componenti` e `bash genera_roles.sh --restore componenti`.

## [3.4.0] 
### Added
- **DHCP Multi-Router sulla stessa rete**: Quando la topologia di rete include 2 o più router (ad es. ROU1 e ROU2 entrambi attestati sul medesimo segmento NET1), AMMSIS permette di configurare un pool DHCP per ciascun router specificando la sottorete CIDR (es. `172.21.64.0/18` per ROU1 e `172.21.128.0/18` per ROU2). Lo script calcola automaticamente il primo e l'ultimo indirizzo IP utilizzabile per ciascun pool e genera ruoli Ansible dedicati e indipendenti (`net_dhcp_server_rou1`, `net_dhcp_server_rou2`), ciascuno provvisto del rispettivo file `dnsmasq.conf`.
- **Campo GECOS opzionale per utenti LDAP**: Durante la creazione guidata degli utenti LDAP, dopo il prompt per la descrizione (`description`), viene offerta la possibilità di specificare il campo `gecos`. Qualora l'utente lasci il campo vuoto, l'attributo `gecos` viene completamente omesso dalla entry LDAP generata (`inetOrgPerson`), prevenendo errori di sintassi o campi vuoti non conformi.
- **Client LDAP con interrogazione in lettura e scrittura**: La fase iniziale di configurazione LDAP è stata riorganizzata per distinguere puntualmente i ruoli dei nodi:
  1. Quale macchina è il server LDAP
  2. Quali macchine partecipano al **login centralizzato** (ricevono i ruoli `ldap_login` e `ldap_utils`)
  3. Quali macchine possono **interrogare in lettura e scrittura** il server LDAP (ricevono `ldap_utils` e le credenziali di amministrazione `ldap_creds` posizionate in `/etc/ldap.admin.cred`)
- **Accesso SSH passwordless tra nodi omogenei**: Se sono definiti almeno 2 client o almeno 2 server, lo script propone di abilitare l'accesso SSH tramite chiavi asimmetriche senza richiesta di password tra i nodi dello stesso tipo. Viene richiesto l'utente desiderato (default `root`) e generati i ruoli `ssh_keys` e `ssh_authkeys`. La funzionalità è strettamente confinata tra soli client o tra soli server (mai cross client $\leftrightarrow$ server) grazie alla generazione di coppie di chiavi SSH distinte e dedicate per ciascun gruppo.

## [3.3.1] 
### Changed
- **Rimozione commenti di valutazione del docente**: I file `.yml` all'interno di `componenti/` contenevano annotazioni personali del docente (es. `# V x 1 presente`, `# V x 3 dettagli corretti`) usate come appunti di correzione. Questi commenti sono stati rimossi da tutti i file sorgente. Inoltre, la nuova funzione `strip_grading_comments()` sanitizza automaticamente ogni componente copiato in `roles/`, garantendo che eventuali annotazioni residue non finiscano mai nell'ambiente generato.
- **Site.yml senza commento di generazione**: Il file `site.yml` veniva generato con un'intestazione `# Generato automaticamente da AMMSIS...` con timestamp. Questo commento è stato rimosso per produrre un playbook più pulito e pronto all'uso.

## [3.3.0] 
### Fixed
- **Rotte statiche cross-subnet corrette**: Il calcolo dell'indirizzo di rete per le rotte statiche nei ruoli `net_srvX` e `net_wksX` (IP statico) e in `dnsmasq.conf` (DHCP option 121) utilizzava un'approssimazione euristica (`ultimo_ottetto → .0`) che falliva per subnet non allineate a /24 (es. `/28`, `/25`, `/27`). Ora viene utilizzata la nuova funzione `calculate_network_address()` che calcola correttamente la rete via bitwise AND con la maschera, garantendo rotte corrette per **qualsiasi combinazione di subnet**.
### Added
- **Supporto 'ud' nel range DHCP**: Durante la configurazione del range DHCP, nell'estremo finale è ora possibile digitare `ud` ("ultimo disponibile") al posto di un indirizzo IP. Lo script calcola automaticamente l'ultimo IP host usabile nella subnet dichiarata (broadcast - 1) tramite la nuova funzione `calculate_last_usable_ip()`. Es: per `10.30.5.0/24` → `10.30.5.254`, per `192.168.77.0/28` → `192.168.77.14`.
- **Nuove funzioni di utilità**:
  - `calculate_network_address(ip, cidr)`: calcola l'indirizzo di rete esatto via bitwise AND
  - `calculate_last_usable_ip(network, cidr)`: calcola l'ultimo IP host usabile (broadcast - 1)

## [3.2.1] 
### Fixed
- **Fix bug: caricamento scelte**: Corretto un bug per cui la funzione `load_choices` non riusciva a popolare correttamente le variabili globali (es. array `wks`, `srv`, `rou`, ecc.) a causa del modo in cui Bash interpreta `declare` all'interno di una funzione. Ora viene utilizzato un file temporaneo con `declare -g` per garantire che le variabili vengano impostate correttamente nell'ambiente globale.

## [3.2.0] 
### Changed
- **Copia intelligente dei ruoli**: Lo script non copia più tutti i componenti indiscriminatamente (come `sudoers`, `create_dir`, `at_atd`, ecc.). Vengono copiati **solo** i componenti che l'utente ha esplicitamente richiesto e configurato tramite il wizard.
- **Site.yml pulito**: Il file `site.yml` generato contiene esclusivamente i ruoli e i play configurati. Niente più codice commentato o placeholder inutilizzati.
- **Validazione DHCP rigorosa**: Durante l'impostazione DHCP, lo script ora estrae e valida rigorosamente che gli indirizzi IP iniziali e finali del range appartengano effettivamente alla subnet dichiarata.
- **Salvataggio e riutilizzo scelte**: A fine wizard le scelte vengono salvate nel file `scelte.txt`. È possibile lanciare `./ammsis.sh scelte.txt` per rigenerare tutto l'ambiente saltando completamente il wizard.
### Added
- **Sezione Logger (rsyslog)**: Aggiunta configurazione interattiva per definire host centralizzati di logging (ricevitori), facility, priority e percorso del file, con generazione automatica del file `rsyslog_custom.conf`.
- **Sezione Cron**: Aggiunta configurazione interattiva per creare task pianificati (host, utente, minuto, ora, giorni, reboot) generando un playbook `cron/tasks/main.yml` già configurato.
### Fixed
- **Fix di sicurezza (set -e)**: Risolti crash (bug bloccanti) legati a varibili contatori che restituivano 0 e all'uso di variabili non confinate.

## [3.1.1] 
### Fixed
- **Fix bug critico SNMP**: Corretto un bug silente nel template `snmpd.conf.j2` dove veniva usata la direttiva inesistente `extend-sh` al posto di `extend`.
- **Fix bug critico LDAP**: Aggiunto `meta: flush_handlers` in `ldap_create_group` per garantire che i contenitori base (`ou=Groups`, `ou=People`) siano importati prima di tentare la creazione di nuovi gruppi, evitando fallimenti del playbook.
### Changed
- **Aggiornamento documentazione**: Allineata la sezione "Componenti Ansible" per riflettere la configurazione automatica di LDAP e SNMP.

## [3.1.0] 
### Fixed
- **Fix percorsi componenti**:
  - Lo script ora funziona **da qualsiasi directory** del filesystem: `COMPONENTI_DIR` viene calcolato in base alla posizione reale di `ammsis.sh` tramite `BASH_SOURCE[0]`, non dalla CWD dell'utente
  - L'utente può ora fare `bash /path/to/ammsis.sh` da qualsiasi cartella e i componenti verranno trovati correttamente
### Added
- **Sezione LDAP interattiva**:
  Dopo la conferma della topologia di rete, il wizard chiede se l'esame richiede LDAP. Se sì:
  - **Server LDAP**: selezione singola tra gli host definiti nella topologia
  - **Dominio LDAP**: con derivazione automatica del `base_dn` (es. `labammsis` → `dc=labammsis`, `unibo.it` → `dc=unibo,dc=it`)
  - **Organizzazione e password admin**: inseriti una sola volta
  - **Client LDAP**: multi-select tra gli host rimanenti, con assegnazione automatica dei ruoli `ldap_login` + `ldap_utils`
  - **Utenti LDAP**: loop interattivo per aggiungere utenti con uid, cn, sn, uidNumber, gidNumber, gruppo, home, shell, password, descrizione
    - **Gestione gruppi idempotente**: alla prima occorrenza di un gruppo viene creato il ruolo `ldap_create_group`; alle occorrenze successive viene solo aggiunta la membership
  - **Gruppi standalone**: per gruppi senza utenti associati (es. `printers`)
  I file `groups.ldif`, `people.ldif` e `ldap.admin.cred` sono stati convertiti in **template Jinja2** (`ansible.builtin.template`), con valori dinamici da `group_vars/all.yml`.
- **Sezione SNMP interattiva**:
  - **Agenti SNMP**: multi-select, con possibilità di aggiungere valori `extend` custom per ciascun agente
  - **Extend personalizzati**: il template `snmpd.conf.j2` usa un loop Jinja2 per generare le righe `extend-sh`
  - **Community string e view**: personalizzabili (default: `public` / `all`)
  - **Manager SNMP**: multi-select per le macchine che eseguono query SNMP
- **Nuovi ruoli Ansible**:
  - **`ldap_create_group`**: creazione idempotente di un gruppo LDAP (verifica se esiste prima di crearlo)
  - **`ldap_user_<uid>`**: ruoli individuali per ogni utente LDAP, generati automaticamente
  - **`ldap_group_<nome>`**: ruoli individuali per ogni gruppo LDAP
- **Generazione `group_vars` e `host_vars`**:
  - `group_vars/all.yml`: variabili LDAP condivise (`ldap_domain`, `ldap_org`, `ldap_admin_password`, `ldap_base_dn`, `ldap_admin_dn`)
  - `host_vars/<host>.yml`: per ogni host, variabili specifiche (`ldap_server_ip`, `snmp_extends`, `snmp_community`, `snmp_view_name`)
### Changed
- **Generazione `site.yml` condizionale**:
  I ruoli LDAP e SNMP vengono inseriti nel `site.yml` **solo se l'utente li ha attivati**, e solo sugli host selezionati (non su tutti router/server/client indistintamente).

## [3.0.0] 
### Added
- **Supporto DHCP**:
  - Dopo la configurazione dei router, lo script chiede se i client e/o i server devono usare **DHCP** o **IP statico**
  - In entrambi i casi, viene chiesta la **subnet in notazione CIDR** (1-32), convertita automaticamente nella netmask corrispondente
  - Se DHCP: lo script raccoglie interattivamente rete, range IP e rotte, poi configura `dnsmasq.conf` e i file di interfaccia DHCP
- **Nuovo formato Vagrantfile**:
  - Il Vagrantfile usa il formato parametrizzato con **loop Ruby** (`(1..NUM_X).each`)
  - Tutte le interfacce usano `auto_config: false` — la rete è gestita esclusivamente da Ansible
  - Supporto per `vb.linked_clone = true` e provisioning Ansible globale
- **Generazione `site.yml` completa**:
  Il `site.yml` viene generato con tutti i ruoli Ansible necessari, copiati dalla cartella `componenti/`:
  - Configurazione comune (`common`, `proxy_lab`)
  - Rete e servizi router (`net_rouX`, `net_dhcp_server`, `net_ipforward`)
  - LDAP (`ldap_utils`, `ldap_creds`, `ldap_server`, `create_ldap_user`, `ldap_login`)
  - Rete server statica (`net_srvX`) o DHCP (`net_dhcp_client_server`)
  - Servizi server (rsyslog, SNMP, SSH, cron, systemd, at/atd, sudoers)
  - Rete client DHCP (`net_dhcp_client`) o statica (`net_wksX`)
  - Servizi client (SNMP manager, install_script_client)
- **Configurazione automatica dei file di rete**:
  Lo script modifica automaticamente i file copiati inserendo gli IP, netmask e rotte statiche immessi dall'utente durante il wizard.
### Changed
- **Rinomina VM**:
  - **Client**: `WKS1`, `WKS2`, ... (prima: `client1`, `client2`)
  - **Router**: `ROU1`, `ROU2`, ... (prima: `router`, `router1`)
  - **Server**: `SRV1`, `SRV2`, ... (prima: `server1`, `server2`)
