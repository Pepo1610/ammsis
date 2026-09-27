# =============================================================================
#  AMMSIS — lib/wizard_ssh.sh
#  Interactive wizard for SSH Passwordless
# =============================================================================

collect_ssh_passwordless_config() {
    echo -e "\n${CLR_BOLD}=== Configurazione SSH Passwordless ===${CLR_RESET}"
    
    if (( NUM_CLIENTS > 1 )); then
        if prompt_confirm "Vuoi configurare l'accesso SSH passwordless tra i CLIENT?"; then
            USE_SSH_PASSWORDLESS_CLIENTS=true
            prompt_input "  Quale utente usare?" SSH_PASSWORDLESS_CLIENT_USER "root"
        else
            USE_SSH_PASSWORDLESS_CLIENTS=false
        fi
    fi
    
    if (( NUM_SERVERS > 1 )); then
        if prompt_confirm "Vuoi configurare l'accesso SSH passwordless tra i SERVER?"; then
            USE_SSH_PASSWORDLESS_SERVERS=true
            prompt_input "  Quale utente usare?" SSH_PASSWORDLESS_SERVER_USER "root"
        else
            USE_SSH_PASSWORDLESS_SERVERS=false
        fi
    fi
}
