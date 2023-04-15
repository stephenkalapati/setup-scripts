#!/usr/bin/env bash
# This is the initial script to run on first boot.

echo "*** setup.sh - Begin ***"

source config
if [[ -z $1 ]]; then
    echo "Requires name of host, e.g. ./setup.sh media-vm"
    exit 1
fi

ENV_DEVICE=$1
if [[ "${ENV_DEVICE}" =~ ^env\..*$ ]]; then
    source ${ENV_DEVICE}
else
    source env.${ENV_DEVICE}
fi

if [[ -z ${SETUP_GROUPS} ]]; then
    SETUP_GROUPS="all" 
else
    SETUP_GROUPS+=( "all" )
fi

if [[ " ${SETUP_GROUPS[*]} " =~ " headless " ]]; then
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
fi

echo "OS = $OSNAME"

if [[ $(sudo dmidecode -s system-manufacturer) == 'QEMU' ]]; then
    IS_VM=true
else
    IS_VM=false
fi

echo "IS_VM=${IS_VM}"

echo "Updating system before proceeding"
if [ $OSNAME = "Fedora Linux" ]; then
    sudo dnf upgrade --refresh -y
    sudo dnf install ${FEDORA_PACKAGES} -y
fi

if [ $OSNAME = "Ubuntu" ] || [ $OSNAME = "Pop!_OS" ]; then
    sudo apt update
    sudo apt dist-upgrade -y
    sudo apt autoremove -y
    sudo apt install -y ${UBUNTU_PACKAGES[@]}
fi

if [[ IS_VM == true ]]; then
    echo -e "\n--- installing vm tools ---\n"
    sudo apt install -y qemu-guest-agent spice-vdagent
    systemctl enable qemu-guest-agent
    systemctl start qemu-guest-agent
fi

echo -e "\n--- Setting up Code directories ---\n"
[[ ! -d ${CODEDIR}/personal ]] && mkdir -p ${CODEDIR}/personal
[[ ! -d ${CODEDIR}/public ]] && mkdir -p ${CODEDIR}/public

echo "Run setup scripts"
mkdir -p ${TMPDIR}
SETUP_SCRIPTS=()

echo "Gather scripts for the following groups - ${SETUP_GROUPS}"
# Get list of all scripts for device groups
for group in ${SETUP_GROUPS[@]}; do
    chmod +x ./scripts/${group}/*
    for script in $(find ./scripts/${group}/ -type f -name '*.sh'|sort); do
        SETUP_SCRIPTS+=("$script")
    done
done

echo -e "Setup scripts -\n${SETUP_SCRIPTS[@]}"
IFS=$'\n' SORTED_SCRIPTS=($(sort -t/ -k4 <<<"${SETUP_SCRIPTS[*]}"))
unset IFS
echo -e "\nSorted -\n${SORTED_SCRIPTS[@]}\n"

for i in ${SORTED_SCRIPTS[@]}; do
    echo -e "START ${i} - $(date)\n"
    FILENAME=$(basename -- "$i")

    ${i} | tee -a ${TMPDIR}/${FILENAME}.log

    echo -e "\nEND ${i} - $(date)"
    echo -e "\n##########\n"
done

echo "*** setup.sh - End ***"
