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


# use pipIndexUrl
if [ "${PIPINDEXURL}" != "none" ]; then
    pip install pip-tools pytest pytest-mock --index-url=$PIPINDEXURL
else
    pip install pip-tools pytest pytest-mock
fi


# use pipIndexUrl
if [ "${PIPINDEXURL}" != "none" ]; then
    pip install pip-tools pytest pytest-mock --index-url=$PIPINDEXURL
else
    pip install pip-tools pytest pytest-mock
fi

echo 'Done!'
