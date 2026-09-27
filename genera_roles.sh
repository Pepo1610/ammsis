#!/usr/bin/env bash
# =============================================================================
# AMMSIS v4.1.0 â€” ripristino deterministico dei componenti Ansible
#
# Il payload e il manifest qui sotto sono la copia canonica della struttura e
# del contenuto dei componenti distribuiti con questa versione.
# =============================================================================
set -euo pipefail

readonly GENERATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_TARGET_DIR="${GENERATOR_DIR}/componenti"

usage() {
    echo "Uso: $0 [--verify|--restore] [directory-componenti] [componenti...]"
}

declare -a EXPECTED_COMPONENTS=()
declare -A EXPECTED_COMPONENT_SEEN=()

register_component() {
    local component="$1"
    if [[ -z "${EXPECTED_COMPONENT_SEEN[$component]:-}" ]]; then
        EXPECTED_COMPONENTS+=("$component")
        EXPECTED_COMPONENT_SEEN[$component]=1
    fi
}

load_manifest() {
    local role rel checksum
    while IFS='|' read -r role rel checksum; do
        [[ -n "$role" ]] || continue
        register_component "$role"
    done <<'MANIFEST'
automazione/at_atd|automazione/at_atd/tasks/main.yml|c4e57d82964646099e501fa06843a9b95d472672d0f39cd37f22047535235de9
automazione/cron|automazione/cron/tasks/main.yml|ec76e78dfb8c6d9ccf5c0d84b13f4686feb92a199c845bde4b43293aad6566d2
automazione/cron_loop|automazione/cron_loop/tasks/main.yml|d3279995ee70c8c34b66c44a68baa682e5cad7e4e0fb327319b89a576035f9b9
automazione/systemd_service|automazione/systemd_service/files/printd.service|279292962d57399fbe4d50c5fd01b9df1a8c81c28360cf7cabb592b1f90cfd91
automazione/systemd_service|automazione/systemd_service/handlers/main.yaml|b5b7ef4123d73ac19b790db16c6ca994e81f86ad2d96dfd60101c25c9e44c65f
automazione/systemd_service|automazione/systemd_service/tasks/main.yaml|2fe6197be5a4d940e2e6ea80bac482ddbf419e6e36846a929d8969e14ea0dda3
automazione/systemd_service|automazione/systemd_service/vars/main.yaml|6dc4fdec6a2b5db47c71586a26afd18e4d2d55300ca29821a96441841b90549a
filesystem/create_dir|filesystem/create_dir/tasks/main.yml|9d4b26f18f3c7e55051f0772531e9e45aa2ac51724d0c1e0f8ec694db2e2a898
filesystem/create_user|filesystem/create_user/tasks/main.yml|d7701591709c6b27773d1fc1547e9889dd87e02142a9a55494bedff4fd89d8ec
filesystem/create_user|filesystem/create_user/templates/sudoers_user.j2|f5671e471718aa4373ba0ca6f919268a7bb13e5b46cf0528ba21e416589db75d
filesystem/create_user|filesystem/create_user/vars/main.yml|1bce4e54c28dfbb8844ef486ba0430cba7f4ef125381e99b9630a2c0fc641f03
filesystem/proxy_lab|filesystem/proxy_lab/tasks/main.yml|979fa21a442044ccd926b16a382d52c0eb0d6f61f220d1b220240cd4d864f019
filesystem/proxy_lab|filesystem/proxy_lab/vars/main.yml|648ad36faa26016c172b8df410daecca2539fc7949d0d52744e816e9810dda08
filesystem/sudoers|filesystem/sudoers/tasks/main.yml|66d52198c4259119d0561de62c4d3ffb0a4aa333f346dc673676f65c5f1d9ae8
installa_script|installa_script/tasks/main.yaml|233cb7cfc301d7399a9e05a42b20011062fc9142b7321942d55b7ecb0da92abc
ldap/create_ldap_user|ldap/create_ldap_user/tasks/main.yml|65da9a9c86c4401eb8d855b14a3d948f5ad365a2344dce9095484206aba76a07
ldap/create_ldap_user|ldap/create_ldap_user/vars/main.yml|2795a41efd54a76dca7de7efbe24b2de1c6586a5ed6d4c248a9ae3872adb6492
ldap/ldap_admin_cred_file|ldap/ldap_admin_cred_file/tasks/main.yml|72f3bfb882c07f28a611aea7fd82e8018e09e31da1cfa364d3e4d7530063fd70
ldap/ldap_create_group|ldap/ldap_create_group/tasks/main.yml|bf2d9796f9c86ae6f5b5fe8db1471374570027df7e6ce5a45e6dd13e0846c0a9
ldap/ldap_create_group|ldap/ldap_create_group/vars/main.yml|b0e3b5e0e8773785e1da33d946cd557558f1b9ac2e60480ec940eb3374b069d5
ldap/ldap_creds|ldap/ldap_creds/tasks/main.yml|dad26509eb1b55686f74c62733df916ff5a5b0b9f4b92d3d10b8adbaf4f77b9e
ldap/ldap_creds|ldap/ldap_creds/templates/ldap.admin.cred.j2|94ceb5f6edd32451a0147b4879c404515194e117d94c0745a260db031202c605
ldap/ldap_login|ldap/ldap_login/handlers/main.yml|41a38c3763222a1dc27c3c638385bb87c85d22ee60df75a7076169cd6bc18788
ldap/ldap_login|ldap/ldap_login/tasks/main.yml|030fc02f0447322e831588aaf3846a3a12b259d01d4efa71e70437ad02d68014
ldap/ldap_login|ldap/ldap_login/vars/main.yml|9cc7d167227be5e01124d10d4d04b787bdec78ef55dfdcea29aa549929fb9096
ldap/ldap_server|ldap/ldap_server/handlers/main.yml|fb05e532ef522fcb693e6fc7e7a37e3907a1889103ee1067e31cdffb42480825
ldap/ldap_server|ldap/ldap_server/tasks/main.yml|b4727cda108e4146c1d2e7066a84e238f178f1ab9520cfa967cc9458d49d605f
ldap/ldap_server|ldap/ldap_server/templates/groups.ldif.j2|69b70dfc1a480334e12c332cfc377226c498bf598455cbc129d38d03181bedea
ldap/ldap_server|ldap/ldap_server/templates/people.ldif.j2|bd84de7c7d079307dc3eda31b221b098eaa29c55714c526648b75f3f7fbf34ed
ldap/ldap_server|ldap/ldap_server/vars/main.yml|a26298639d9fb6198fa78827d77aa8586c54ceeb51ad5be0cf300f35a680a682
ldap/ldap_utils|ldap/ldap_utils/tasks/main.yml|0f1cf46aa8e7d5b9cd925bf17a0cc7a040110fd0849ae4bb154e226704e06182
rete/net_dhcp_client|rete/net_dhcp_client/files/eth1dhcp|e0684d1c6d1dc92247ba3c69ac2315f62cff3a73206527862ca1de95dee11929
rete/net_dhcp_client|rete/net_dhcp_client/handlers/main.yml|c788a2e73a2d09e8ef2f4d4ffe7297a8a0c6ed8fdbde01b4f9efb47d3b518059
rete/net_dhcp_client|rete/net_dhcp_client/tasks/main.yml|19abacfc26071b673480b9210917a788d350e40e86de130be53ed7201c26996e
rete/net_dhcp_server|rete/net_dhcp_server/files/dnsmasq.conf|becd032411effbf650f32076953ed2154842b4c082694075d405d0a1f2b19fb8
rete/net_dhcp_server|rete/net_dhcp_server/handlers/main.yml|c0607366b8769dff806a1933ac5cd4c1be706bdf8f7c16a3bfb88e4b5fa9df97
rete/net_dhcp_server|rete/net_dhcp_server/tasks/main.yml|4667d66dd602cd35dadb0eebb6d755f41208b421adf37c288cb3628f0b96693b
rete/net_ipforward|rete/net_ipforward/handlers/main.yml|86f4ff0184323291acb2d5f40baccb58fb08a8a307ea73cf989c6bafccec1f6b
rete/net_ipforward|rete/net_ipforward/tasks/main.yml|2c0e24941e2986547bf23227522a440b4fd5bccdce35ad99649be7dcde51fd94
rete/net_router|rete/net_router/files/eth1|9e3e3a8319f26ff6319ce84b3ff22926b75c2b56aea4c1379a5713ce35bd6677
rete/net_router|rete/net_router/files/eth2|e0f2a662ba561625727b1b6d27fa2bbd60b6d29bf14a0302a04a2bf57aa84015
rete/net_router|rete/net_router/handlers/main.yml|c788a2e73a2d09e8ef2f4d4ffe7297a8a0c6ed8fdbde01b4f9efb47d3b518059
rete/net_router|rete/net_router/tasks/main.yml|60d612b20389c37ab935f7b560e71080f7cdee3b835da77c948577829f079986
rete/net_server|rete/net_server/files/eth1|2debf67f5f00694d698aa5fc74d673d09a47467bc1b61082e6f46b65150779c2
rete/net_server|rete/net_server/handlers/main.yml|c788a2e73a2d09e8ef2f4d4ffe7297a8a0c6ed8fdbde01b4f9efb47d3b518059
rete/net_server|rete/net_server/tasks/main.yml|40460799017d86b1c0272a3d14067fd998eba61e86e42b02e6f9432a8c3bf00f
snmp/snmp_agent|snmp/snmp_agent/handlers/main.yml|b3402ba9658dcad06b1e6ad8c37b7b60031dfa9e4f17f662939e3acc13e5b964
snmp/snmp_agent|snmp/snmp_agent/tasks/main.yml|aa95268f1392b0fe9789002379ea3a5f396f5f96abf6a1fd7a24ffaa2d3c8447
snmp/snmp_agent|snmp/snmp_agent/templates/snmpd.conf.j2|babb19886289a3817344427e29fdde58bbc2e34472c355e4df97052898b0e9b8
snmp/snmp_manager|snmp/snmp_manager/tasks/main.yml|22c3fd1daaf5b21e328186bcd51cacfda721b2f783848bdbea05415995346c98
ssh/ssh_authkeys|ssh/ssh_authkeys/files/id_rsa.pub|2717c2a452e7af82ac0ad9d31a518bc94c3e472df9651b50fccc16b453017af4
ssh/ssh_authkeys|ssh/ssh_authkeys/tasks/main.yml|589b694738be632357a4abce808182bdb92c775629295ab9f0ccd268f6eb12c8
ssh/ssh_authkeys|ssh/ssh_authkeys/vars/main.yml|9c69f15e44ad94cdaa19f1855a950891bac433dbbc2687eddf0a6d5d71662d34
ssh/ssh_keys|ssh/ssh_keys/files/id_rsa|56f24424d9b42664a8d0172b6ec12a5b893a99c752c665eec70b1149ef3770ac
ssh/ssh_keys|ssh/ssh_keys/files/id_rsa.pub|2717c2a452e7af82ac0ad9d31a518bc94c3e472df9651b50fccc16b453017af4
ssh/ssh_keys|ssh/ssh_keys/tasks/main.yml|6c4746b49a3e2b57d0dcf87969f7dffaa1214f294ad34f8ab73a3918cd11c4b2
ssh/ssh_keys|ssh/ssh_keys/vars/main.yml|64d58f1bb67f6105c141631206ea195a39d86c21331d4bc9ea48a04d4822e9f7
syslog/rsyslog|syslog/rsyslog/files/rsyslog_custom.conf|c330aff974d0804a40c7eed7961bed965065b6651b504cdf244b0f68e8ba7fb2
syslog/rsyslog|syslog/rsyslog/files/rsyslog.conf|eafe79ac6b14c8c89957705e1361168b8e145d6b2470aba8de4029539faae842
syslog/rsyslog|syslog/rsyslog/handlers/main.yml|0d0b24d6f0f7e3ca069f075d70bf4564dfd5e485d9ab829aa45a3cae19a5e7a6
syslog/rsyslog|syslog/rsyslog/tasks/main.yml|67201a044914b822f61662a6a4487265433dd9d803cf38605023b3cca5dbbc4c
MANIFEST
}

invalid_components() {
    local target_dir="$1"
    local role rel checksum actual
    declare -A invalid=()

    while IFS='|' read -r role rel checksum; do
        [[ -n "$role" ]] || continue
        if [[ ! -f "${target_dir}/${rel}" ]]; then
            invalid["$role"]=1
            continue
        fi
        actual="$(sha256sum "${target_dir}/${rel}" | awk '{print $1}')"
        [[ "$actual" == "$checksum" ]] || invalid["$role"]=1
    done <<'MANIFEST'
automazione/at_atd|automazione/at_atd/tasks/main.yml|c4e57d82964646099e501fa06843a9b95d472672d0f39cd37f22047535235de9
automazione/cron|automazione/cron/tasks/main.yml|ec76e78dfb8c6d9ccf5c0d84b13f4686feb92a199c845bde4b43293aad6566d2
automazione/cron_loop|automazione/cron_loop/tasks/main.yml|d3279995ee70c8c34b66c44a68baa682e5cad7e4e0fb327319b89a576035f9b9
automazione/systemd_service|automazione/systemd_service/files/printd.service|279292962d57399fbe4d50c5fd01b9df1a8c81c28360cf7cabb592b1f90cfd91
automazione/systemd_service|automazione/systemd_service/handlers/main.yaml|b5b7ef4123d73ac19b790db16c6ca994e81f86ad2d96dfd60101c25c9e44c65f
automazione/systemd_service|automazione/systemd_service/tasks/main.yaml|2fe6197be5a4d940e2e6ea80bac482ddbf419e6e36846a929d8969e14ea0dda3
automazione/systemd_service|automazione/systemd_service/vars/main.yaml|6dc4fdec6a2b5db47c71586a26afd18e4d2d55300ca29821a96441841b90549a
filesystem/create_dir|filesystem/create_dir/tasks/main.yml|9d4b26f18f3c7e55051f0772531e9e45aa2ac51724d0c1e0f8ec694db2e2a898
filesystem/create_user|filesystem/create_user/tasks/main.yml|d7701591709c6b27773d1fc1547e9889dd87e02142a9a55494bedff4fd89d8ec
filesystem/create_user|filesystem/create_user/templates/sudoers_user.j2|f5671e471718aa4373ba0ca6f919268a7bb13e5b46cf0528ba21e416589db75d
filesystem/create_user|filesystem/create_user/vars/main.yml|1bce4e54c28dfbb8844ef486ba0430cba7f4ef125381e99b9630a2c0fc641f03
filesystem/proxy_lab|filesystem/proxy_lab/tasks/main.yml|979fa21a442044ccd926b16a382d52c0eb0d6f61f220d1b220240cd4d864f019
filesystem/proxy_lab|filesystem/proxy_lab/vars/main.yml|648ad36faa26016c172b8df410daecca2539fc7949d0d52744e816e9810dda08
filesystem/sudoers|filesystem/sudoers/tasks/main.yml|66d52198c4259119d0561de62c4d3ffb0a4aa333f346dc673676f65c5f1d9ae8
installa_script|installa_script/tasks/main.yaml|233cb7cfc301d7399a9e05a42b20011062fc9142b7321942d55b7ecb0da92abc
ldap/create_ldap_user|ldap/create_ldap_user/tasks/main.yml|65da9a9c86c4401eb8d855b14a3d948f5ad365a2344dce9095484206aba76a07
ldap/create_ldap_user|ldap/create_ldap_user/vars/main.yml|2795a41efd54a76dca7de7efbe24b2de1c6586a5ed6d4c248a9ae3872adb6492
ldap/ldap_admin_cred_file|ldap/ldap_admin_cred_file/tasks/main.yml|72f3bfb882c07f28a611aea7fd82e8018e09e31da1cfa364d3e4d7530063fd70
ldap/ldap_create_group|ldap/ldap_create_group/tasks/main.yml|bf2d9796f9c86ae6f5b5fe8db1471374570027df7e6ce5a45e6dd13e0846c0a9
ldap/ldap_create_group|ldap/ldap_create_group/vars/main.yml|b0e3b5e0e8773785e1da33d946cd557558f1b9ac2e60480ec940eb3374b069d5
ldap/ldap_creds|ldap/ldap_creds/tasks/main.yml|dad26509eb1b55686f74c62733df916ff5a5b0b9f4b92d3d10b8adbaf4f77b9e
ldap/ldap_creds|ldap/ldap_creds/templates/ldap.admin.cred.j2|94ceb5f6edd32451a0147b4879c404515194e117d94c0745a260db031202c605
ldap/ldap_login|ldap/ldap_login/handlers/main.yml|41a38c3763222a1dc27c3c638385bb87c85d22ee60df75a7076169cd6bc18788
ldap/ldap_login|ldap/ldap_login/tasks/main.yml|030fc02f0447322e831588aaf3846a3a12b259d01d4efa71e70437ad02d68014
ldap/ldap_login|ldap/ldap_login/vars/main.yml|9cc7d167227be5e01124d10d4d04b787bdec78ef55dfdcea29aa549929fb9096
ldap/ldap_server|ldap/ldap_server/handlers/main.yml|fb05e532ef522fcb693e6fc7e7a37e3907a1889103ee1067e31cdffb42480825
ldap/ldap_server|ldap/ldap_server/tasks/main.yml|b4727cda108e4146c1d2e7066a84e238f178f1ab9520cfa967cc9458d49d605f
ldap/ldap_server|ldap/ldap_server/templates/groups.ldif.j2|69b70dfc1a480334e12c332cfc377226c498bf598455cbc129d38d03181bedea
ldap/ldap_server|ldap/ldap_server/templates/people.ldif.j2|bd84de7c7d079307dc3eda31b221b098eaa29c55714c526648b75f3f7fbf34ed
ldap/ldap_server|ldap/ldap_server/vars/main.yml|a26298639d9fb6198fa78827d77aa8586c54ceeb51ad5be0cf300f35a680a682
ldap/ldap_utils|ldap/ldap_utils/tasks/main.yml|0f1cf46aa8e7d5b9cd925bf17a0cc7a040110fd0849ae4bb154e226704e06182
rete/net_dhcp_client|rete/net_dhcp_client/files/eth1dhcp|e0684d1c6d1dc92247ba3c69ac2315f62cff3a73206527862ca1de95dee11929
rete/net_dhcp_client|rete/net_dhcp_client/handlers/main.yml|c788a2e73a2d09e8ef2f4d4ffe7297a8a0c6ed8fdbde01b4f9efb47d3b518059
rete/net_dhcp_client|rete/net_dhcp_client/tasks/main.yml|19abacfc26071b673480b9210917a788d350e40e86de130be53ed7201c26996e
rete/net_dhcp_server|rete/net_dhcp_server/files/dnsmasq.conf|becd032411effbf650f32076953ed2154842b4c082694075d405d0a1f2b19fb8
rete/net_dhcp_server|rete/net_dhcp_server/handlers/main.yml|c0607366b8769dff806a1933ac5cd4c1be706bdf8f7c16a3bfb88e4b5fa9df97
rete/net_dhcp_server|rete/net_dhcp_server/tasks/main.yml|4667d66dd602cd35dadb0eebb6d755f41208b421adf37c288cb3628f0b96693b
rete/net_ipforward|rete/net_ipforward/handlers/main.yml|86f4ff0184323291acb2d5f40baccb58fb08a8a307ea73cf989c6bafccec1f6b
rete/net_ipforward|rete/net_ipforward/tasks/main.yml|2c0e24941e2986547bf23227522a440b4fd5bccdce35ad99649be7dcde51fd94
rete/net_router|rete/net_router/files/eth1|9e3e3a8319f26ff6319ce84b3ff22926b75c2b56aea4c1379a5713ce35bd6677
rete/net_router|rete/net_router/files/eth2|e0f2a662ba561625727b1b6d27fa2bbd60b6d29bf14a0302a04a2bf57aa84015
rete/net_router|rete/net_router/handlers/main.yml|c788a2e73a2d09e8ef2f4d4ffe7297a8a0c6ed8fdbde01b4f9efb47d3b518059
rete/net_router|rete/net_router/tasks/main.yml|60d612b20389c37ab935f7b560e71080f7cdee3b835da77c948577829f079986
rete/net_server|rete/net_server/files/eth1|2debf67f5f00694d698aa5fc74d673d09a47467bc1b61082e6f46b65150779c2
rete/net_server|rete/net_server/handlers/main.yml|c788a2e73a2d09e8ef2f4d4ffe7297a8a0c6ed8fdbde01b4f9efb47d3b518059
rete/net_server|rete/net_server/tasks/main.yml|40460799017d86b1c0272a3d14067fd998eba61e86e42b02e6f9432a8c3bf00f
snmp/snmp_agent|snmp/snmp_agent/handlers/main.yml|b3402ba9658dcad06b1e6ad8c37b7b60031dfa9e4f17f662939e3acc13e5b964
snmp/snmp_agent|snmp/snmp_agent/tasks/main.yml|aa95268f1392b0fe9789002379ea3a5f396f5f96abf6a1fd7a24ffaa2d3c8447
snmp/snmp_agent|snmp/snmp_agent/templates/snmpd.conf.j2|babb19886289a3817344427e29fdde58bbc2e34472c355e4df97052898b0e9b8
snmp/snmp_manager|snmp/snmp_manager/tasks/main.yml|22c3fd1daaf5b21e328186bcd51cacfda721b2f783848bdbea05415995346c98
ssh/ssh_authkeys|ssh/ssh_authkeys/files/id_rsa.pub|2717c2a452e7af82ac0ad9d31a518bc94c3e472df9651b50fccc16b453017af4
ssh/ssh_authkeys|ssh/ssh_authkeys/tasks/main.yml|589b694738be632357a4abce808182bdb92c775629295ab9f0ccd268f6eb12c8
ssh/ssh_authkeys|ssh/ssh_authkeys/vars/main.yml|9c69f15e44ad94cdaa19f1855a950891bac433dbbc2687eddf0a6d5d71662d34
ssh/ssh_keys|ssh/ssh_keys/files/id_rsa|56f24424d9b42664a8d0172b6ec12a5b893a99c752c665eec70b1149ef3770ac
ssh/ssh_keys|ssh/ssh_keys/files/id_rsa.pub|2717c2a452e7af82ac0ad9d31a518bc94c3e472df9651b50fccc16b453017af4
ssh/ssh_keys|ssh/ssh_keys/tasks/main.yml|6c4746b49a3e2b57d0dcf87969f7dffaa1214f294ad34f8ab73a3918cd11c4b2
ssh/ssh_keys|ssh/ssh_keys/vars/main.yml|64d58f1bb67f6105c141631206ea195a39d86c21331d4bc9ea48a04d4822e9f7
syslog/rsyslog|syslog/rsyslog/files/rsyslog_custom.conf|c330aff974d0804a40c7eed7961bed965065b6651b504cdf244b0f68e8ba7fb2
syslog/rsyslog|syslog/rsyslog/files/rsyslog.conf|eafe79ac6b14c8c89957705e1361168b8e145d6b2470aba8de4029539faae842
syslog/rsyslog|syslog/rsyslog/handlers/main.yml|0d0b24d6f0f7e3ca069f075d70bf4564dfd5e485d9ab829aa45a3cae19a5e7a6
syslog/rsyslog|syslog/rsyslog/tasks/main.yml|67201a044914b822f61662a6a4487265433dd9d803cf38605023b3cca5dbbc4c
MANIFEST

    for role in "${EXPECTED_COMPONENTS[@]}"; do
        [[ -n "${invalid[$role]:-}" ]] && printf '%s\n' "$role"
    done
    return 0
}

restore_components() {
    local target_dir="$1"
    shift
    local -a components=("$@")
    local temp_dir archive_file component

    if (( ${#components[@]} == 0 )); then
        components=("${EXPECTED_COMPONENTS[@]}")
    fi
    for component in "${components[@]}"; do
        [[ -n "${EXPECTED_COMPONENT_SEEN[$component]:-}" ]] || {
            echo "Componente non riconosciuto: $component" >&2
            return 2
        }
    done

    temp_dir="$(mktemp -d)"
    archive_file="${temp_dir}/componenti.tar.gz"
    trap 'rm -rf "$temp_dir"' RETURN
    base64 --decode > "$archive_file" <<'PAYLOAD'
H4sIAAAAAAAAA+w923LbOJZ5XVXlHzDKziqpsi6kbt2aOFVeW5PWVmJrbKd7Z7u7NDQJS0hThJoXO+5OtvYj9gP2N/Z5/mS/ZA8AkiJpSqRkGZokOFWJRRAAARwA5+DcYNL5gjrY8UnzyWNBC6Df77O/Wr/bSv6N4InW1dv9dq/X1yCfpuv9zhPUfbQWJSDwfMNF6Mnc8H2yJl/R+88UzCX+jcCnc+M3Ao+7nQsl8d/t6K12i6VrnV5LV/iXASvwb/gTw7d2NA02W/89wH+v1VP4lwLr8e8b3i/eg2fB5vjv662+wr8MKIP/uUGcxt3c3vYbRfjXgNgD/ju9fkfrMfzrrV4X8N/aZUdXwVeO/3q9/rRSR44xxwM0cmAwbBsZPrIMPKcOMhwL+ZTa3tMKggePXNm4cRUQ24cpYSz8AUtHYXHDF09QiQ+PCxd7MLFEWrCwIHFiGuYMXvlugJ9W9t13BSvXv+lSZ2dM4Ob7f7fbU/u/FFiH/91Q/634v76mzn9SoBj/D6X+xfjv9O7Rf5gJiv7LgBT9v8B+sEAM93nknqWn6H315enZ2yE6Gb5Bx2dvj05PztDJERpeDF+/G10O0Xh4Pjo7GR0fvR2eXg5fVUXRZ+jXgCCCLOz7xtQmyAts5GOYhcgiC+xY1KFIZJ0TJ2CMRLUVlp3RwIXHdvgYeJg9vnx3yT6AjlDcnL+8O3ozRKNEu4bfD8OWncdNeU+vWPHx0eV36Oji4uzNu8uzbG9eDy8uoQgknaLj87NTVnbfONslrFn/E5vSxS6YgM3lP8D+q/1fChTifwdMwOb47/d1TeFfBpTE/4OYgGL6r6Xxr2tttv4V/X98APofk/8TvLDpHaf/iOEe3brGYoFd5JkuWfh5LAFd3A04LbWw5wMx/f13FE+diSg2WRj+DH36VOX5TOr4MNsG6CN/BH7gD80r4jSvDG9WCZNuZ8TGXEaA/hQmWTT88U+pLwDqptifwCSeM0nFp09RLs/GeIHSrcHwbctbZgJOA/Of9NZhjIRLqc+fpy4NFonnObU4F9LvdqtfFPF/snL9e3ce8GQWDJp7Q8wH6oM2Pv/pLTgAqP1fBpTE/zWsyK25gM3xr2mdlsK/DNgI/wuXOL7VCBNLf6OQ/sNiD/HfbvU6gP9Oi/F/iv4/Pvz4ziH+z5UTLIg1IP9wzLDMcAyU/9cAAxUWyoDK0bWP3UMH+7fU/aUhaG+l8uOFmA4/Vy7vFvjQI/OFjSvDD9i8gCz+YTPw3KZNTcNueozSR5NoVjnHHs9h2LfGnRc9XmDzsFt5Bw045BQYanEsw7XOAn8R+IfvaeA6hh0nD12XunFq5cdQh/Fz5QcDOA3rX+8O5wHwKnUmLIja/Ax9jz6gdqShwAi4DWg7MCeMjaDw13UxoPtLI/Y5UHL9z2BcbOxuRwK22P97iv7LgU3xLw6CxkYnwSL86/3k/t8G/Lc7HSX/lQLR2e8c29SwUIj3A4QdAw56XP/Ld2UUzoScQ2BmrgwSEuIanMDCZDh31cRJkROTics/KFTBPF18MZkS6pFdQRewFe7bWrxvfwX782NDyfX/ICngNvw/bANq/5cAG+F/m83/SQn+X+9k9n+gCGr/lwJJ+d8xXdwhdh5gpz10TV3kz/CajX8p/fNcM7vZR6fEWkI8WGti34zmVvi3uaZUOcFcDc6MHVbAoT65DltUL0/RvmqqUnL93xhb8v4Mttj/W5rS/0iBTfC/5fZfjP+unt3/e5qS/0gBtv9HjDsSopl4Q3TonMlEsPvV7YpfDyTWP5fxCpq822+U3P+7egc4QdgLWloHQO3/MiAf/6aLmbW2RVyJ9j9J+89uT+l/pEAh/uXZ/yT9f/qtrsK/DCiJ/0e1/2m3+xn7X63dVed/KZCy/x06XuDCERkB4rHpU/cO4Q/E83O9f9h0Cc2BmYXPAGUMac9Hx9+NhheXZ69SXkFx1U+TR/yXZz+cDs8vvhuN43JHYbnw0P/y9fm78fh+taEM4OV4eP52eHExijOMXtW+LFPdR4G165/pTOX5fwj+r6Vz/w9l/yEHivH/cAZgE/wzwQ+z/+op+Y8UKIv/hzAABfjX220u/+m2YQIwwy+g/9228v+VAin5P2AdERsobrBYUCYNmhsuocjCtl0LfG4p89zDyKEOwh7wBfhFDl8g6HXSTej335GDb/lsmvC3sTXwlFjZ98RCH+GL10Zg+8/pnPgHXCH8Ii6T9i6uMHNh7AyyX/iIbOxM/Rl6hVqVdA/xDZQLDJuIjhIkLIOhq8gl5oxgzyfpflKHlu4pgfWzuq3MEjlvRLywSF5fvHWdiRHDLazytDTcS2oVOlhSwjZ7Pue22aksYWoCK6nSS8QE95AZFCIzZO7WTRE+BPlj9hG9p8R5XjuovUDkeu2wIWwDRlkT4pqZbbuTsjeYwUTPfImnxUVm9N4IsqTlCIp9Mydb4k2ce2F43i11s6MWJUP7o5+TmeHNnte8mdHV9NrKtZDQ5DkmtjBaYHeOPY852VkUzYlrhFM7mui585p549ms4qVuj5XHrscb2HivJ03+hU5PvG9YzZWzq6wyr9NpCe3fDSxRi/evekN4B+rmNfqjl7NO2NtJaEACw3ZFqa1Y/1JQgv6Hs+HR9X9J/q/fVvF/pMAm+M9sAqW/USj/0bL4b/dbSv4jBZ6hPzNjjymGzdnwKRJKYJ+YxpyzFZaBjgR5QM/dgNoUJebGC/R///XfnE2CzZtcQyEuPZobDm1UcggBOnrz5vA5/PeCuWbVTs/GRxcXP5wMainqzTdzh3LaZwm6XatB6RRZZnlCty/u0rXvcfxcoXj9P8j0g8PG+z+T/6v4L1KgJP4fU/6vd7v9zP6vtfu62v9lADv/P0OHuwSoLzF/OImAOUSMK2KzsB82iuccs717lzy+otOz0/qbk6Mxem6YJg3g2GnB4YWJGuYGECk4mQONAprEDx2CQhyIBzgbWfT2xc47AxXCGKETdnJi9jEmWRiiH/HRm41hitTFoVHCyCRLnUW1kj1Xs7wnw4vj89F/jM5O4yLPgQAvKHo9PD67eHGAsNdAp+zseEynzCwnWVF0bI39qBPvwpNok/3NP5rlnVDDMzHDzugEvr2wickG/vm1YVIbzpzkhr5ooDeGZxJG8m8Cyt5Wqy/YiRNdGy7wCYAcPHXgNVRzn6uwI6w2KklxAbS1Gg3564wYSkzVC5wQUS0lUeiGAAsjJh5NNC0lWFq2EyrKaWm2nYm2RYIKgddQFzU+H709Oh+d5SN4mtOdpLApNZph74YecNuEDtCPVcbiVA9QlRtlAdtd/TnRLRv6bPD+GCiUVDErLsoYr4wYBOr6OWrDOBItiK/Fj8RB5gwqhg+H40iugR00EODphjF9DixbJghm/vts/IFW+C5F/0ac94YONf1thaTibwe8bTeMKYS+G/YNq3VK/v4/8Sd+DUiizQmZyEvOHZ6dn6DRKYLxPTo/SygH43Ed58o47o1trqxgADMA+MtKPl8JbQBetSrCFPAlWOXOjGydCUJp+nbknhIaz1Ur+XxsuKT2vd3fg3z6v3Dph7uJbVztxBJsC/ufTlf5/0mBIvzvIgbgFvY/vZby/5EC5fD/sBiABfjXtE434/+v6R2l/5MCaf8f55pMA1f4AAi22lj47F8D6P51wxITgz9UELoCViZmFu+rEWziYOJwM6GElVBtfbW1hB4loZrZ0BMoR/OGEGvPPR0dV8iFHkO1IxOYERcPBjPfXwwGY9YqXkCsh8BlmqBm9U+13ALe2hKrRvk/mw3Gs7vm9gPKmfsbY+oajh/V9oBRwB8WFPiZ7y4vx5Px+dm///Uw26FqLSfvxerM+57kClZC0f7/cOnfVvS/01b2P1KgFP4fGAK4CP9aq5Ol/62eov9SgNF/wPPECeYD9G0l3riBrnAi2Gxq3+oNrfdNQ9NhYw+zMk9dvfPt4JvWNy21vX/OkL/+Q03v/u7/0Trq/CcF1uN/f/f/9JX9txQog//Hvv+n3dKy8f/77Zai/zIg5f8jYgAySfYNzIUpMXya5/mTOIcm/X+ShoCrLwIS58/aCb4ihlP3nPlCWIWwo/wLFJuEoJdREP6L8fB49OfRMQ/N/6bGovifHzNlGfPvUR4+D4TE+icicqIRxm3enRP45vt/t9NT8n8psAb/D4r5m4Qt+L+uov9yYA3+d3X90zb472mK/5cChfjfNuhPAorw30vF/2Hyn1ZHV/ZfUuBe/De+6zODEBasuTjo2z2XJ+EVwkyaLkenR8KmiTFuwMgdn4/Gl69Sbt/j87Px+Wh4ya1okhkyXt8r84V3M8Tu36+y6ozQYkeUYTc6jd6Oz86hoiE3IaE3N0QY+xwwQxqTII9dQBVywha5AWaWHCCL3rjMgAWSIQWjBfn7/wqDGJEFStOpEzgGN5CxoSLDhQmDXeL5xJxhphEBthpzu7Go+koYaanLB53hwBMDI3rP+/bYsagT69+2jJ1c93QPSu7/ift/2pq6/1EOZPEfWgGy37ty/9+K/1P3P8qBQvzvJ/5Pr6P0f1KgJP4f0/5f62si/k+rDWyfzv3/9X5b8X8yIMn/HXkeMQMXeBhgWGhw+Fq4UfPfY0wXwNZ4xADuaEqMGhfuEUTmzAAEfgG7Nce+MUDXduDNJtGFAWl3dWHyEprNMzv/XAaTW98OkGDw2Ew0LAvVP6D6d/xp0GSW7HyGiltKJmQR3epVP+EcKX9pWHPiTCyHsaaofpt9EbtZC87VcKdeyNf6FnGWF5RZ8Dsg1iGUjp3aP306iMfkIKr2yvCw+FxYkl69x6Z/bMOHBsBRY//MnY5hTKiTl2FBPfLhSHg95L0XDg7pDCa0LWqXmfiyl0j3Euncwj7dkeWb02B+xZjyxHuHJy1zTe/nmt7PxeyRTqIwT8ucoe97mMmmU+JcCNeFuKmhs3008stLaZZ5EomJ1sObcWw5/vvx+V/Hl58+LOfeCGYpM5i3jdilvtzMC50QH3vyQVkv7iF7F1W56cTbeP0X7v87MADagv53FP8vB8rh/1Htf1uA9QT95/Y/mtL/yQHhCPSXAHMfqthN7wY7Uy4HYXIPtuH6wmsrll0gYz73iMeu8XqGrICZnmK2vQpHckHnuY+cMb8iwpfqWWbbPEjvlAd5++NBaodjXlsujdpmGUJOMuFTFNrGZiiiQH48n6c1Kku3MuwBIaiEhHKAhstHL/0YU70BqmlsdtYqaTqXTReCqkT9KZ87nl6tJB31lvedxtv9YEmWskQOPhfySxaBr3D3sB2aXGXXfwIHsBVYEyaZkmT/mbz/We8q+b8UKIX/B8oANsa/3uq0lP5PCmyA/62ZgKLzP2A9g3+YAOr+bymQc/83v/2HIR87vxHm686nw+rj+v0rwPkkiqfPigvA0xnFlOMBAz59+snJeZc4Mv3kbBJSrMp2k2qOA04yLEHMp6CpTa9Yr3kYAv7pEr0W8QhcyvrbsBKriDFIqW5HYoXQc4Z9ZXJ08nZ0Onl3MTw/XDMq1ZySwloqt9S9I+ZGo7XvealADuTu/+EhkE8QefGf+flP6wv7D+X/LQeK8S8t/nOIf27/ATkU/mVAWfw/avznlh7hv8PugmjpWqer9D9SQJ7+53vs8hCBzMxmGcEnjN7Daiwnkfew4ZqzshL5K1Q1HSZBF5KiMOrRQdy5HBl6LI9nSfDbxVPWROCcRB0wOOYvkH5tAK9nTUQkWhFGBtg86Pc0k5qjAQs7/xlpwDYdxTwNlk8XKxVfvKK0Viv1sVwFlMgxjfRYYtATWGq4JvrDYTJm9tF0SgJnSmCuslreQVEjnossMLK3wCafpj7JC42cgxoe+vLus8SOmK3+3QJGRnQjfAHTbbAcojAxfuZjHxr9pWKaiwaIfF4i8vePP0chq5MoivIRj2UkDrb45azZShKhz3MX3b530M8bium/tPifCf6/31P+/3KgJP4f9f4vXcT/WeJf19otJf+TAtL0f5UldQJiESqyqpWYhEMiV6tFSSEB4NEL9z1IXzCsWv/Wrpz/n2y4/7fZ/V9dXdl/yIE1+Jft/8fw39b0PpP/tftK/icF1uB/n/5/HXX/nxwoxP9Dgz88KcH/9fsJ/k/c/9dX8Z+kQI7+d6n4DLXAPoGDNrp26RxFl8GUuzWKTaaGUIOymtIXR3GVaSbHJnpKpabcBaxb/w+++CmEzfm/vt5T939LgVL4v7+ON/pGIf67vTT+db3T1dT+LwNyhNGVlXJotd1+cZC7/rlvzl7j/7R1Zf8rBdbgP1Lh7iP+n6bwLwfK4P+x4/9p7W42/h+P/6To/+NDKv7feXiVjeOZVl7gP6bOJmYU9U+UifLG0f7C+3CwpWLzfQawZv3vVf7XVfI/KVCI/8eX/2ks2H9m/9e0rtr/ZUBq/x+JCHDIwlfsLhZujhP+rgc+sb08omAs/CRBeBpaC9WjkvcSllUhFCzYDe8T0zBn4b0nLKZr1J4L7AeLuDXX1EU2uXI8r85maS6FCvOmKFS2DEK/MnU3962Mwpc1oiRmp/Q0un4+SNyU0uDPidfCbGr5mj1Hr5cmUeLj3J/aEm/Xdc/x7HzKm9evOLPUDvGvZnsSTRzWTYHeA9bzhTHnw84nUgING02jZZ3LtETXeZblp9KpGbznzTb4HvXJ9V2W+9n3wpQEa/b/XVz9wmEL+q8r/a8cKML/Dsh/cfyHVjL+Q5/f/91W9l9SgN//ws3qmaVywiszabpcrSTJGFPw1RMkJ7nPNk0bG84Enm+Jb86SdCe+yy0kNFeUsrzrKsurJrr0mWsFD8KoSMl6Pd8lzrRS4TQi21ae2BQkxSVeii6mbbdF//ntbTm1r6w1dBpIUdtcB4N0fXvDf+76F33fmQB4I/2f1ubx3/sq/qMUWIf/XRmAbYD/yP6r11L4lwLr8L8rBcAW8v+2ruz/pUAp/D/u/X8acIDL/b/X5vf/dJX8Xwok7b+iA7BnA/O1RvyfkEFEWe9L/9PBF6FW2yLXIrp8XtUiNNbHep6f5xWqrnXYjJw10SvUtPBN0wlsG+mv/kVDHyMnufs+lARYvea2/niofo2a/nzR5Fyo12B9q6xu+sp4jfts+oI3SjR937NQwb5g3f6/KwXQFvKfXkfJf6RAMf4fLgEqov96N2H/3eXxP9otpf+RAkn6X6j+WSG2X/IDWVVPvupnhSy+skYxsoolifQiuSxJgVZkvVJkvU4kpRLhXwxTs8oE0Zp7Q7yqP+nhTPRl3XCFdvtLBittq5+Hthxj/RU3+VQ5sxC9+8jCYeAPExc+aZj4ee2nnxrv9X+uHaBa7UVcMrTQ73U62dt4EvxS5A1QRwlORCRGg3ifc9z3cvniYO3+vyMHgI3kf3qXx//uK/t/KVAO/+llu+k3ivCvdfpp+a+ua8r+Tw6w6DFrI8WkQvVQd2o45DeDkVAglA7xKzQYIFG6kopaLW6SDjd8tW//o0K59Z+m0Jt+o3j999L7P6z/tvL/lALh+l99o0iZ9S9K565/FrtWLf9/XFi3/ndlALSF/EfpfyVBIf4l2P+2uon4Tz0e/1/Tlf2PFGDyHy5lyFrK8MSmQydmFC6dpSdlJlHMywKLHlGRRdlEyrWMEa9WGMZk6poZLraaSTKUWyVkKFcfb1ukHtFy61oRTb18tfqOqw3cKRBnwzeytkblLKxELXN6gyfUtjaqaN+TVcHOIXf/51La/fr/qvt/5MAa/O/T/6ur7v+RA4X4lxH/KYz/nvT/6ij5nxTI9f/iEaBMm8XtRD7Q/jJ+X/f8dEKDoIWLPahntQPOvkfg64bE+nex/+Cr/nJhs/2f2f+29bai/1Igi38H+xNrZi4mYvnvwf9LxP/sKv2fFCjC/y58ADbHf7/TVfF/pUA5/GN/prHU7b5RiP9ejP92i9t/ay2l/5UDRuBTxNBbIdeGiflPRGAWIIbvyjP0PfqAtIiLU7dtfGlQtP534QO08f4P5z9F/+VAafw/QA5QhH+tm43/An+U/l8K5Mb/OsX+LXV/Ic60dBSwVAkVC+yzgaL1vwsh8Bb8f7elq/1fBpTD/8OEwEX47+i97P6vqfjPciC1/x/TxR0yYDO/jTZ0lNL+oyqBM4DLDgpeVdwTDwkUcV+AA2Rcw0seoAPoANMlE0sUuyX+DJHrIDfwE79K/enSDyE6az7N3hUQNqm5bEPD4ifTOLwV+x50oxl4btO7Ik6TfRPV6w6tG6aP6gT90UNRiaynRpLo7Rsr8mDl+t9hDJAt5H+dluL/pUAR/vck/+u2lPxPCpTDv+V4c8P7tcGowebfKMC/BgfAjPxPb2nq/m8p8Ay5xKSuZSCLiDuAiWm4+P/Zu9LlxJFs3b+J4B0yqu+Eu4eyQRIgcPR0jAABYhH7OjPXIZAQAiEJbQh66n3uK9zf82I3UwKzGBvbRcnVt/RFGIOU28mT68mT54BPcJrsf4LTu2eegJNlDhjjqeAFRE3F9RIOK0/arxEUXg2FHqfnv6EkQiHUmm515GjYffD5N4ZlhkwNNCm2QAOm/vvn3/IMSx/+bnUyLN0GObpSoUCTbtO/f8bwaSj0M1yWGIal7BwLAxHO9ysOTuKSDLLeeTUv2AIqEVxaWIgQDlgG+g/LD7OPodJ3ORH5q/RKprr66l7RCJSFrpomB2DbN1QUySWVFyRQ1yFlW6tgsC3onBekiZ2mg8HCYp9/Q+UGEfBICwNadLNLNyF9TB00a5023QQOYNhCk261ai6dIFthaLb9+1O56+MDmLsqKpAFqEZhfcBlEKRPUgGiWoelNdUzgV2avCICWLp9PG4fj/uBlj0Btrg0/n+Q/BcP1n/+4NX8/5by3zjxRP4b2H/yB2flv9vl3muFvwfBA8nvnwyX+v9HyX+JQP7rC17H/28r/yXIU/1fDG4Ag/HfD5z3//D8+H+q9Xtu7L+o8nsocfa2jsJLeZ5KiA+lEU+kxKcvT8W8j/l8dM1/HzjX/yVtouorTuevpA38DvlvLLD/7w9e5v91LAC/Y/5PBvz3B6/k/1ctAC7u/7D46fxPBPY//MHJ/k9WOR6Z7hib8vmZeLGATeLwiNULDG61YEb9M+Ll/n+dK6DvGP/xwP+rP3gN/7+1/1c8eSr/i8F2EIz/fuBo/KcVA23FdNUykQaPZKBzP3UlnHVJJ0uKICnofHi7N9M4c7rdhHmTwsEG7dzOECVwD25gi7uTNDsOPx627e5v2M3x1u1oWvroKvt/hXP9H/H/iu5/3jH+J+KB/w9/8AL/r+X+5z37/0Qw//uDi/xHCg1fmcfF+T+GHev/wPUfiQfzvx94/v4fmrKlsTtTczwPJ24D/MawOabJDIe1vf4K3S5iv3sCYcFcwPUi2Knv1OF7762nj4IDSXsMtNU5kYLZ/GPxmv7/ZoOvJ7go/yHJ0/5PxAL5jy/Y9X983//xt/Z//Hz/370Lev93jBf6/7Xc/71P/hOs/33Ba/j/reU/T+//xpLJQP/bFwT3f39svND/P8j+o7f/D/y/+YOL/PfB/mOCfDL+4/BfMP77gOfu/16492t8g4u/hw7IDtW6Pj1/+/dJDHWlCDqcd1R1e8jg+p85fOD5JruJJePxm7ddHH5SQNexWXjrxGx/Edn9jv9Jrhif6/9XvPrr4j3y/+D+pz94gf8fKv/Hgv2fL7jIfx/k/wSZfCr/D/y/+oI3yv/r6FLu7iLrWanf6Xs4j0oa0FEa4Mmd2MruwiuwJe6MeDFbpEGLAVQ+T2WzDAUjgibdpB8zeEm0uHvn3X31qIH/D+7MBhdeX+z/Hyr/C+Z/f/Aa/n+E/C+w/+QPAvnfj40X+v+Hyv+IwP+fL7jIfz/kf1v/f4fyv1gg//MFgfzvyvK/P4HM7xAH/d9QFtp34/8lEch/fMEp/9HHAydey/WLi1fy3/P/Cid+5P8vGfDfF7zAf7/lv4j/BEYQrv3PZKD/7Qte4P/Hyn+C9b8veA3/v7n8J/5U/hMP5P++4Kz8BzWCs3f+zol+HgOfk/p8l2veAHu80P8/Vv4TrP98wUX++yD/Icj44/ofh4xHF8KSwf0vXwDH/yfmv9wR/RnbX6cD/5nb3c+Y/QqdMfrlJgEmuroAprDQZBjlTL67V/d7WZEb0b1ffjfDT02APTZkL8QZoYxX9I+u++8BL/X/bbV/9Rzw9v0/SQT+P/3Bq/h/1Nvenscl/sPZfsf/OEEkXPu/gf6PP3BZTW31eyxeu4c7sJAtCSvwxx/uMPmAfjyggRv8e2d3/5cbOE3c/Aq+fAGSMpYtXuDBHRbSVWQfylIkc/0Ye//kILZmjWRp7CWwM+V/231djqHQH38BE1UHgmMi9wRuDPhdUHjjIPw//vUr+MuX0M8oUfj2zk3uC3qwtAR97c0gogDzrS1tcGsDDNyOX1/q/2LqgKXbty22Wr+l+22azd1Wmcz9vWLQbllqlqlZZt6S5bt/fjouwz8/hbzynpRt93NrZAuVFpIKwyFqIS3fhP9n+z/MHraLq2kAv339nyDxWDD++4EX+X+lHeA75H+xeGD/3xe8gv9fvQO8OP8nT/3/xRJ4sP/zBefsfymqcjvRBQGgWQi50tGlEUA+dASFg/uys5JBuDd80AVNNSRT1XfH+ujBPZxAR2BqmppxH43C73fwT+KUO1UXo95XMFLV+UrVFwA1tcccd8U4b0HsqdVqNBe7Ra5KI+M1tqv/4U72n93P2wWMdMurKwXZGhN08K+3ma+Gk3/rzVbSdh3uwFCaLoiCo92Dm/9GBbo5op0b7Ui/Hv8P+78x/SbH/+85/4+RgfzPF5zwH/49cJY5nQvrq4h+Xbxj/ZeMBee/vuAl/l9LAeAd8n8y8P/kDy7zX+IfdIO7g7vf9+Zxcf0XP7H/Fuj/+wbI8FvIXkBBZAh2w2Wx9Rin0c8c1aAy6DHVyImjdGlU2UStEjdtMayDlbp8bVJWCmIPxzZsdyqv2fxMM7pdJj8brcSs2ZJsJhWjjcLcTA0WUXOQa1tlvIBzjYw4TfKdREOaF6J6Xo0YnWxW6eI8XVdWGSE+Lw3bTrVe6C2ISLRWiJItbqmIXYZUNr3NxJivKnhdNzGDm3M2bg6nm0QnVpbFcbZj0wW2W1klVZyrJTvESqAqg2KLwFJjpdBn21U2HZ9r67KdrAyj5bY5GE7YTJ8XywNjtVFm0eWiKyYjjoO3OjmHwQ0jMnfmRGSyKq9tsyEy3fmslIgasFT8tIsVHCKRXGlSsU+XdSwam+TSdLYT44exCMH1DIU0hJJktTYRgnZYnm6I0rw0mJEsV8kvCY2W5WkX2J4jyr97vtbDT7w++nB+/lL/v9YB8HvGfyKQ//iCy/z/+gPgS/wnkk/0/+OB/yd/cKT6b04F4Em5AWwAwFTdJ6g9qLq0EfgH1Cxc/X9XAm8ZcJ+MROaw0bjfv3wBPyMHvKqiAsGQDFOAO2PLREMZEMBUXQhnt+VH6W+3ySg970rAQeqfnjcmjmK6wWVVnVvaLzeolDefwc1++eJK7j8FOklHeKn/29wVlD9/ep/+TyKw/+QLLvLfB/0fON4/tf8U2P/zBbvRdXdF6qPLE8BfnOn/V5X9Ibx9/I+Tgf1Xf/Ac/692+een9/l/DPw/+IOX+e8tnr82jwv8J3DP/++R/adYoP/lC24RMnSBYUGzRYF6k+lSbRqU6YH7JhyqMgytikyGospZqkFT8UK01VunoqTUUztSbsy3uv22stYcNW+a4013MBzPmoPkKN9tZQZ4igmHKL2j6us6m6lktMqkULLJHhUjJXNqLubUgBGUbq3DaBk76XB1PU+JGsYrzVwiRfWtUrbXSYVD7Zwja2bU3kztSGyx1OL5Vi2RwgyCLFWz6VmS5EcFraCn9d5gHOmyWW1QpOSKk5l1W6nakl2EQzNLZlNFMYtnYmZ6Uiw58qazyU2EUnks6REJn6znZK/Q3zS6xCC7qFSriXg0qcmDmm2M+blMhUOpFqtX6lp1yEaVVNbQyQ6TzQ+ZtTAh2ahNDLp80+AjglEeTDEnu0xP0sVVtEnJbLHH101cDof0UoQsSgN9bkRNp9ruN2mG0bI9JrLpSQ5nJpul4aDbYDyxqwprPFNNdKr9pmGUZScjieHQ2s73N/WBJBcZDGMxvsDZ/IqMa9G8NSPYdCeS7ujSbNWqEP0FUWBTs0I3jtetkqzyGClMhuFQ2aJn5GrTIboyVZjwrTRJs5ZIG6Q9JiWHGA/j+XKl2W4uNLM4TMxy/VZ2NhqIy745TbWTKh4OMdmVVWCT5rjXEHuKndQ2JpXumSqlpeV1c0RVmqPuVMhFhpitjuprJyKS+SnWn0kaYzWstAFr0mk1NJpkzQ5R6Je6CjfWE0N9XLE2WiLCFVbRLl6YFwVnY9aM9rIeaZl9zNK5dVOvKjGRT4RDWKUrwdJn1PkmGh3UqMmsWitFNnV+LEwqjaadG3bLclzIjrHVPKKbVavsjArL1HKe6yy46KgbDi2XsOFS1aw4oKmURij9ft2akSWBWSrUOJ2J9aSi6RTnlq612sRarJlr0i4vyHmvtUxEKp11OBTlUtUaiUWpqp6qzdeTLK7w/eZ8hscUu9oR+3YaGxYEtpOA7bNWa+VZMSsVdU7Oyi2CtNt2OCTNG2Uxk25bTUNlR70p3ywbWbGG2bRQbQwLdHPAmuQoWZxJ2Vm8SmbpDOUUJmO3zCRLr8Ihw6o3CDmZXibzsUGlT/QaEm6TM8dp0kWBZhPFPG1ouYIYaSx6kcZyYmSzK6aJtad5tpXa2LBf6IP5kOiu4ljDqczZVXNQKeL1xqA1JsoWpqyrdkUbZRtzMZbHKtKGGrCLXL4zk+KxSmKV0wt8ONSJL4cFnDZKQnpKFdebulTq15tZNVNl25GNOVI5U6k0UU1n8IZaL3GVuF5eYQltMuLqjU0pHEovlME4g7UKI9ESeikO77cH8RZZaUXkzlwfytVEVUvH+e5csxNLa1GcjPpctWAvU04RWywF2DfJrlEoFbTErDzP9fNSb+gkJ9nosKqkZ6kOPSg4Ck7GKLnXz/Krkd6dOqVOoleIwMGipkbniU44xEbm8ZlurSW9ieObfDJdX5RLq3JGzETUAV7FjVimh0UZy5zNK4Jc0pdVLcKPrUovh5UnaToZDjWrw2Q/Wis7XFtnk0IyYWfxTmTWV3RVGZhMIWNT00Wd5YoLe53D1osNFxPN5DrRWIlKk+5I4ZBYrBDOYhXrlxTHsfVuxNInJL3ZCPmuNV2VB9GElBymujhPik4Kp/BMo5dbD0qZyaLWGpkZ2B5Si1iOUgsUE28kqD7LbKb00BAZPkFPqoo8STlOXicndhdTGlyt3FgsVEOZdh0thsub/qgHW7UmcjiP1dd0h54rCz3WTurVfmLl5Mg600tMxZzczfC9EVHki5kIF80MpLaYbCTMiW3Mq0ZZD4dWw5xVisgFzEh37So/ya/G6rxdkmbroVhcjsY5PruIU5Myx9BdQ+0XzY76t3DInWxoNvfMJPQBByM/CF6z/vuas1+EN5//YiSZDPz/+ILg/Dc4/z3X/692+fen9+3/A/8P/uBl/l9B+P/TRf7jOHHi/xm+DeT//uCc/jc6qAW8pAtjpMv97FGv4EiGeVbR+om6MzqYRak+wFSfnOM+5nRkwu380e/WnNv5lzvTbrBt3RxqaW/JuoMxDsjyiv8cde8hK4py+Na0xY5pc8/tNV2yYXbuof0b6Dk1wOet9o5M750hcLsoPClX0i3X+2k8pWivhfDVBKHl6yuJQkFPCXu0E/i1hFHjsaCZrkqFCj90xDbF9IxtwgIZpksuMpmoWiZ8CUdm8xkTvAeEotsScPi+B//2fgNQREn9dfcLoWXq0thEz8vCOjsVxsgcIVDUwzAdWJCyAmlEwYw80vGI8oIdVSxZvlh7nrXIKzeJjx4afwg8N/9fS/cD4e3rvwRcCgTrPz/wIv+vs/y7zP9T+18YSSD7z8H679vjVP9jN7Tfg2igEPID4LD/m7plmpbOPRiSKdyZjnmlPC6d/xLEqf+fJEYE57++4PQmK7eRYHOAq8qFBf9xwIRNQgBwMditwtUaWqUa94CTZfhjJMBQO+NOAI4fsmDcb61hIxsWqgIO8DOYSA7YuRuKhX72AsJlrrN+kLnRQUDVtiVYKKQ1bKiyinz2SAqAYVSdg3spSYU/RUGEa0qJ21uVarpeKz8DZMYewJjIVOFGgjsw98m+8E3sQtm3LjCxfdkPXvDTsbY1kH/8QtLgRmXF6fxhDJnntAfLlGTj8MFYF/ijB156u6rTBXTj2IuKFsNgTyOiZB96S1Crj7SuVVsAffCf/wGSDBRrIeiw3jRhLE2ksQqX7jJ4jHaJdkO3+/ssD/L564XIe2r3vHTNteuquG1XiI+CO8hEjbEuud9Q6WRuv1V+UlX71NBPQdlInOwydiQpPErSvU2Nwt9x/AJtj2CwbSq6sTZkVTxqiHAzJHjF0YWFaqKsAQxjHDMA7W8eo6D1UNTQVFWOuru2mToyopqg8LAlbqPtLSftowkGGlxh0wWypYhTYbPZUTtWeW4X0eJVQTeOiqjAzqOphgFZB0cnDbYCA230YPMHY7h/zLn35m9RloAbwe+AGyOnVirssZYCs4CVDisCBXe19WEsZJATZrzLc7vOO6oWON8DQ0I7StgMYCdCJnc42UQtyWvwv8CeCCtvKsGdIOzGj3JqoEn/+V9Ui5ai/nqQw06T+CgH4QY2IrjXFmVJfawMmKNhuCzhH3PdJsSZD5zJHw8lGqQetextq9qlAh+7/V3iVYXnlM2OWsmzEPCAmpy282+BkoGf23e7lFwagBcQpqsg6rmDzuOStjZMYcE/bK2heiWCSU0gq1D9QQYdJGIg7qARzXRTGrl1ABNcwNqDRd2+emx7x6PmLmmZU8YSMsFwkDB8Lqk8rAR3qDwwr+eeJqC2fzTuZS9138fhzTuOOOyGsHdIyr5E3s8xqh3YE2GjhqQZloRGa2mb/WGn2JoT2cXeWV6CFQobrHQoBjnPL688aGJ4Nb+2JHz07Pr943D9546U38AExNv3/0QSC/b/vuAp//Wrt4N3yH8ILDj/8wXP8/96GuD/197V9iaOA+HP5FdYUKm7qEDZg1baXk/igFZo07ICequVTlrRxAdRCYkcul3+/c1jJ5CEsvS4LrcnzaOqbcb2xPb4bSb2eI/vvw32/3YY7JJ//KQ9FO37jl36//npWd7/w/k5n/89CEpGeUqLOXf31+q4bxzHKpHufkXPfqCg0FGQb2LGS7MkYsUNHO2PK5KSkpjLtaa0iK1RQC0VqTZd+LNa5q010uzktyoCLMsq5aEp4qbfubO7Q7GiZONYfuA+zuQbOPS6LHr+47cocB6Kb7GkVsFXz5URrVrDMFALXb5Z4GClrxf3WOJOoNvleDwQnTiINI8HqeakX8cpEpZWKZfUHyu8PJ2yUrlpDT5UKsLHhcQTSVpaOL73Zt5iSYVex7vrfBSxHks6sgxRQxulc8PiW8ubh4+LN4tlKBOaQGYui816g4LTTEftZ5jmM71wwLWUZQtilu1m7edldW33f2/ZotMbdNuj3h9bpZaWHxraHamcpGW4HrJH4ll4Pnx4k95r2l2V4oyC2DOdmHqTKbRSx4MyuY4cnWiLFLQIfFvFJ9i/gtkseILA4KKN2FhHLQcvwafPjvH5Ooo9IIvB8PPQ7l9/Ga1zgmhXOgsmo0Np+Cb+bENo4FqnNXsM0DFQ13pY1a8Dhz6+jGq92Dxf42OoGLu+eWxrU8RN4EpxetY4tY46nkrTzptN6+hO33uNfTQmJ5+mOHaf3M4ntNXC9EPsSTAZwPs/Beqhs9oOkbJwJB1dc+sZB786/6aLri4AzA4dbg1M4+jGnJiPUDb+2Deai2kig62d2eTkylMRqdPYnEIlIQVfuakaFcKm/++XpIU7ugehjmGAOMEv7JColguFgi4mpjdQqyhluVq+yMab04RYKFRWUZNxD8q5ZrLmokkIdMfSj0PXCWMiwjFImLTrYE1D4CxU+TCQEOSPvVk+TNMQCPNgPlDTVtKz40EJLRCtE0njIY5qbBhSRQn6oTYXwdkDNeYSnr1IyHGkPUA8KQ92WK1gR7pVjRX65FRGct2YdZYwF2xmFFQT/jRW881wUE24VCpdtwkt7l+Qe9EZL5xphdpiMduZytVLV94/Ti7+tAqbwgRVc8tLVqdBYmTygv7iogBH4j9kazs3yP0kFu933xCP7JEpRNeXaiLnjkf9B9YcWM9Qp/KrVMv7wF3qWUTCqGlKJZEAAn4f+DR/+tHkfXljm6j1L+wcL1z/fXFonRT4+y0Dd63/641Gbv337pcmf/89CH69arV7dm/0WXRF73Y4GrQ6rZvu7agvOt2eoDmP/tp2S7T7t8Pu9W3rt7j1vVuPs9QxAgVf6VJvEfLmq29ISkmqNLbC/cTY3v9f7fq/ffx/19n+cxi8QP4/3P93vbHh/6t5xvu/D4Jn7/+Lm8BLbwBMRec7AP9n2N7/X+8E0D723wb7/zgIdsn/NbaA7pJ/cv9Tavyv13n9fxBkxn999CLZMZO1AscGNr1hRootk0P+/EXaqpw+Q3C8YXPOHhQ4hkHsOHM8IE3KH83I3+63mo9yJXuuYP+gGGkdeHtp3NqPKst/3VQYDAaDwWAwGAwGg8FgMBgMBoPBYDAYDAaDwWD8pPgbi32qLAAIAgA=
PAYLOAD
    tar -xzf "$archive_file" -C "$temp_dir"

    mkdir -p "$target_dir"
    for component in "${components[@]}"; do
        rm -rf "${target_dir}/${component}"
        mkdir -p "$(dirname "${target_dir}/${component}")"
        cp -a "${temp_dir}/componenti/${component}" "${target_dir}/${component}"
        printf 'Ripristinato componente: %s\n' "$component"
    done
    trap - RETURN
    rm -rf "$temp_dir"
}

main() {
    local mode="--restore"
    if [[ "${1:-}" == "--verify" || "${1:-}" == "--restore" ]]; then
        mode="$1"
        shift
    elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        usage
        return 0
    fi

    local target_dir="${1:-$DEFAULT_TARGET_DIR}"
    [[ $# -gt 0 ]] && shift
    load_manifest

    case "$mode" in
        --verify) invalid_components "$target_dir" ;;
        --restore) restore_components "$target_dir" "$@" ;;
    esac
}
main "$@"

