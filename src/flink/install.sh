#!/usr/bin/env bash

FLINK_VERSION="${VERSION:-"latest"}"
SCALA_VERSION="${SCALAVERSION:-"2.12"}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

# Comma-separated list of java versions to be installed
# alongside JAVA_VERSION, but not set as default.
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
MAJOR_VERSION_ID=$(echo ${VERSION_ID} | cut -d . -f 1)
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

# Setup INSTALL_CMD & PKG_MGR_CMD
if type apt-get > /dev/null 2>&1; then
    PKG_MGR_CMD=apt-get
    INSTALL_CMD="${PKG_MGR_CMD} -y install --no-install-recommends"
else
    echo "(Error) Unable to find a supported package manager."
    exit 1
fi

# Clean up
clean_up() {
    local pkg
    case ${ADJUSTED_ID} in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
    esac
}
clean_up

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

getFile() {
  if [ $# -ne 2 ]; then
    echo "getFile takes 2 arguments, $# argument(s) given"
    echo 'Usage: getFile https://example.com file_name'
    exit 1;
  elif command -v wget &> /dev/null; then
    wget "$1" -O "$2"
  elif command -v curl &> /dev/null; then
    curl -s "$1" -o "$2"
  else
    echo 'Please install wget or curl to continue'
    exit 1;
  fi
}


# Install Flink
# https://archive.apache.org/dist/flink/flink-1.19.0/flink-1.19.0-bin-scala_2.12.tgz
# https://archive.apache.org/dist/flink/flink-1.14.0/flink-1.14.0-bin-scala_2.12.tgz
if [ -n "${FLINK_VERSION}" ]; then    
    mkdir -p /usr/share/flink
    if [ "${FLINKURL}" != "none" ]; then
        getFile ${FLINKURL} /tmp/flink
    else
        getFile "https://archive.apache.org/dist/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz" /tmp/flink
    fi
    tar xzf /tmp/flink -C /usr/share/flink --strip-components=1
    rm -f /tmp/flink 
fi

# Clean up
clean_up

echo "Done!"
