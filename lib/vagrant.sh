# =============================================================================
#  AMMSIS — lib/vagrant.sh
#  Function to start virtual machines
# =============================================================================

start_virtual_machines() {
    log_step "3" "Avvio delle macchine virtuali e provisioning (Vagrant + Ansible)..."

    log_info "Esecuzione di 'vagrant up'..."
    if vagrant up; then
        log_success "Macchine virtuali avviate e configurate correttamente."
    else
        log_error "Errore durante l'avvio delle macchine virtuali."
        exit 1
    fi
}
