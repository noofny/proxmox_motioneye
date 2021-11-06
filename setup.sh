#!/bin/bash -e


# functions
function error() {
    echo -e "\e[91m[ERROR] $1\e[39m"
}
function warn() {
    echo -e "\e[93m[WARNING] $1\e[39m"
}
function info() {
    echo -e "\e[36m[INFO] $1\e[39m"
}
function cleanup() {
    popd >/dev/null
    rm -rf $TEMP_FOLDER_PATH
}


TEMP_FOLDER_PATH=$(mktemp -d)
export TEMP_FOLDER_PATH=${TEMP_FOLDER_PATH}
pushd $TEMP_FOLDER_PATH >/dev/null


# prompts/args
DEFAULT_HOSTNAME='motioneye-0'
DEFAULT_PASSWORD='motioneye'
read -p "Enter a hostname (${DEFAULT_HOSTNAME}) : " HOSTNAME
read -s -p "Enter a password (${DEFAULT_PASSWORD}) : " HOSTPASS
echo -e "\n"
HOSTNAME="${HOSTNAME:-${DEFAULT_HOSTNAME}}"
HOSTPASS="${HOSTPASS:-${DEFAULT_PASSWORD}}"
CONTAINER_OS_TYPE='debian'
CONTAINER_OS_VERSION='10'
CONTAINER_OS_STRING="${CONTAINER_OS_TYPE}-${CONTAINER_OS_VERSION}"
info "Using OS: ${CONTAINER_OS_STRING}"
CONTAINER_ARCH=$(dpkg --print-architecture)
mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($CONTAINER_OS_STRING.*\)/\1/p" | sort -t - -k 2 -V)
TEMPLATE="${TEMPLATES[-1]}"
TEMPLATE_STRING="local:vztmpl/${TEMPLATE}"
info "Using template: ${TEMPLATE_STRING}"


# storage location
STORAGE_LIST=( $(pvesm status -content rootdir | awk 'NR>1 {print $1}') )
if [ ${#STORAGE_LIST[@]} -eq 0 ]; then
    warn "'Container' needs to be selected for at least one storage location."
    die "Unable to detect valid storage location."
elif [ ${#STORAGE_LIST[@]} -eq 1 ]; then
    STORAGE=${STORAGE_LIST[0]}
else
    info "More than one storage locations detected."
    PS3=$"Which storage location would you like to use? "
    select storage_item in "${STORAGE_LIST[@]}"; do
        if [[ " ${STORAGE_LIST[*]} " =~ ${storage_item} ]]; then
            STORAGE=$storage_item
            break
        fi
        echo -en "\e[1A\e[K\e[1A"
    done
fi
info "Using '$STORAGE' for storage location."


# Get the next guest VM/LXC ID
CONTAINER_ID=$(pvesh get /cluster/nextid)
info "Container ID is $CONTAINER_ID."


# Create the container
info "Creating LXC container..."
pct create "${CONTAINER_ID}" "${TEMPLATE_STRING}" \
    -arch "${CONTAINER_ARCH}" \
    -cores 1 \
    -onboot 1 \
    -features nesting=1 \
    -unprivileged 1 \
    -hostname "${HOSTNAME}" \
    -net0 name=eth0,bridge=vmbr0,ip=dhcp \
    -ostype "${CONTAINER_OS_TYPE}" \
    -password ${HOSTPASS} \
    -storage "${STORAGE}" \
    >/dev/null


# Start container
info "Starting LXC container..."
pct start "${CONTAINER_ID}"


# Setup OS
info "Fetching setup script..."
wget --no-cache -qL https://raw.githubusercontent.com/noofny/proxmox_motioneye/master/setup_os.sh
info "Executing script..."
pct push "${CONTAINER_ID}" ./setup_os.sh /setup_os.sh -perms 755
pct exec "${CONTAINER_ID}" -- bash -c "/setup_os.sh"
pct reboot "${CONTAINER_ID}"


# Setup motioneye
info "Fetching setup script..."
wget --no-cache -qL https://raw.githubusercontent.com/noofny/proxmox_motioneye/master/setup_motioneye.sh
info "Executing script..."
pct push "${CONTAINER_ID}" ./setup_motioneye.sh /setup_motioneye.sh -perms 755
pct exec "${CONTAINER_ID}" -- bash -c "/setup_motioneye.sh"


# Done - reboot!
rm -rf ${TEMP_FOLDER_PATH}
info "Container and app setup - container will restart!"
pct reboot "${CONTAINER_ID}"
