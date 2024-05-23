#!/usr/bin/env bash

JAVA_VERSION="${VERSION:-"17"}"
INSTALL_GRADLE="${INSTALLGRADLE:-"false"}"
GRADLE_VERSION="${GRADLEVERSION:-"none"}"
INSTALL_MAVEN="${INSTALLMAVEN:-"false"}"
MAVEN_VERSION="${MAVENVERSION:-"none"}"
INSTALL_ANT="${INSTALLANT:-"false"}"
ANT_VERSION="${ANTVERSION:-"none"}"
INSTALL_GROOVY="${INSTALLGROOVY:-"false"}"
GROOVY_VERSION="${GROOVYVERSION:-"none"}"
# JDK_DISTRO="${JDKDISTRO:-"ms"}"

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

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

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

updaterc() {
    local _bashrc
    local _zshrc
    if [ "${UPDATE_RC}" = "true" ]; then
        case $ADJUSTED_ID in
            debian)
                _bashrc=/etc/bash.bashrc
                _zshrc=/etc/zsh/zshrc
                ;;
        esac
        echo "Updating ${_bashrc} and ${_zshrc}..."
        if [[ "$(cat ${_bashrc})" != *"$1"* ]]; then
            echo -e "$1" >> "${_bashrc}"
        fi
        if [ -f "${_zshrc}" ] && [[ "$(cat ${_zshrc})" != *"$1"* ]]; then
            echo -e "$1" >> "${_zshrc}"
        fi
    fi
}


pkg_manager_update() {
    case $ADJUSTED_ID in
        debian)
            if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
                echo "Running apt-get update..."
                ${PKG_MGR_CMD} update -y
            fi
            ;;
    esac
}

# Checks if packages are installed and installs them if not
check_packages() {
    case ${ADJUSTED_ID} in
        debian)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                pkg_manager_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
    esac
}

# Use Microsoft JDK for everything but JDK 8 and 18 (unless specified differently with jdkDistro option)
get_jdk_distro() {
    VERSION="$1"
    if [ "${JDK_DISTRO}" = "ms" ]; then
        if echo "${VERSION}" | grep -E '^8([\s\.]|$)' > /dev/null 2>&1 || echo "${VERSION}" | grep -E '^18([\s\.]|$)' > /dev/null 2>&1; then
            JDK_DISTRO="tem"
        fi
    fi
}


export DEBIAN_FRONTEND=noninteractive

architecture="$(uname -m)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

# Install dependencies,
check_packages ca-certificates zip unzip sed findutils util-linux tar
check_packages openjdk-8-jdk
# Make sure passwd (Debian) and shadow-utils RHEL family is installed
if [ ${ADJUSTED_ID} = "debian" ]; then
    check_packages passwd
fi
# minimal RHEL installs may not include curl, or includes curl-minimal instead.
# Install curl if the "curl" command is not present.
if ! type curl > /dev/null 2>&1; then
    check_packages curl
fi


# Install Ant
if [[ "${INSTALL_ANT}" = "true" ]] && ! ant -version > /dev/null 2>&1; then
    check_packages ant
fi

# Install Gradle
if [[ "${INSTALL_GRADLE}" = "true" ]] && ! gradle --version > /dev/null 2>&1; then
    check_packages gradle
fi

# Install Maven
if [[ "${INSTALL_MAVEN}" = "true" ]] && ! mvn --version > /dev/null 2>&1; then
    check_packages maven
fi

# Install Groovy
if [[ "${INSTALL_GROOVY}" = "true" ]] && ! groovy --version > /dev/null 2>&1; then
    check_packages groovy
fi

# Clean up
clean_up

echo "Done!"
