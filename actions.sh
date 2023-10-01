#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

VERSION="1.0.0"

main() {
    local action="${args[0]}"

    if [[ $(type -t "cli_command_${action}") == function ]]; then
        cli_command_${action}
        exit
    fi

    msg "${RED}ERROR: Action not found${NOFORMAT}"
}

actions_description=$'Available actions:\n'

actions_description+=$'  001_copy_ssh_key  \n'
cli_command_001_copy_ssh_key() {
    # On the first connection we use -k to connect by password
    ansible-playbook --ask-pass "playbooks/001-install-ssh-public-key.ansible.yml"
}

actions_description+=$'  002_update_packages  \n'
cli_command_002_update_packages() {
    # Provide password for SUDO command
    ansible-playbook --ask-become-pass "playbooks/002-apt-upgrade.ansible.yml"
}

actions_description+=$'  003_debug_messages  \n'
cli_command_003_debug_messages() {
    ansible-playbook "playbooks/003-debug-show-vault-var.ansible.yml"
}

actions_description+=$'  004_install_docker          Install docker\n'
cli_command_004_install_docker() {
    ansible-playbook --ask-become-pass "playbooks/004-install-docker.yml"
}


actions_description+=$'  005_install_portainer          Install portainer\n'
cli_command_005_install_portainer() {
    ansible-playbook --ask-become-pass "playbooks/005-install-portainer.yml"
}

actions_description+=$'  encrypt_group_vault       Run one time only\n'
cli_command_encrypt_group_vault() {
    # Run one time when you create the group var
    ansible-vault encrypt inventory/group_vars/ubuntu/vault
}

actions_description+=$'  edit_group_vault          Run each time you want to add or update variables\n'
cli_command_edit_group_vault() {
    # Run each time you want to add or update variables
    ansible-vault edit inventory/group_vars/ubuntu/vault
}


# 
# 
# template from: https://gist.github.com/m-radzikowski/53e0b39e9a59a1518990e76c2bff8038
# 
# 

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] action
Tool to run one the ansible playbooks.
Used to document the needed parameters for each run.

Available options:
  -h, --help         Print this help and exit
  --verbose          Print script debug info
  --version          Print the version of the script

${actions_description}
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    --version) msg $VERSION; exit ;;
    --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -f | --flag) flag=1 ;; # example flag
    -p | --param) # example named parameter
      param="${2-}"
      shift
      ;;
    -?*) die "${RED}Unknown option: $1${NOFORMAT}" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  #   [[ -z "${param-}" ]] && die "Missing required parameter: param"

  [[ ${#args[@]} -eq 0 ]] && msg "\n${RED}ERROR: Missing action parameter${NOFORMAT}\n\n" && usage

  return 0
}

setup_colors
parse_params "$@"

# script logic here
main "$@"


# On the first connection we use -k to connect by password
# ansible-playbook -k playbooks/001-install-ssh-public-key.ansible.yml



