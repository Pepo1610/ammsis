#!/bin/bash

# Include calculate_adapters from ammsis.sh
source ammsis.sh

run_test() {
    local name="$1"
    local input="$2"
    local expected="$3"
    
    local actual
    actual=$(calculate_adapters "$input")
    
    # Rimuovi spazi extra e newline
    actual=$(echo "$actual" | tr '\n' ' ' | sed 's/ *$//')
    expected=$(echo "$expected" | tr '\n' ' ' | sed 's/ *$//')
    
    if [[ "$actual" == "$expected" ]]; then
        echo "[PASS] $name"
    else
        echo "[FAIL] $name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
    fi
}

echo "Running tests for calculate_adapters..."
run_test "(a) nessun buco (eth1, eth2 richieste)" "1;2" "real 1 real 2"
run_test "(b) un buco singolo (solo eth2, eth3)" "2;3" "dummy 1 real 2 real 3"
run_test "(c) buchi multipli (solo eth3, eth5) in ordine sparso" "5;3" "dummy 1 dummy 2 real 3 dummy 4 real 5"
run_test "(d) nessuna interfaccia oltre eth0 (max_id=0)" "" ""
run_test "interfacce duplicate" "2;2" "dummy 1 real 2" # Just to test it handles it gracefully, even though collect_node_type prevents it
run_test "spazi al posto di punto e virgola" "2 3" "dummy 1 real 2 real 3"

echo "Done."
