#!/bin/bash -i

set -e

source dev-container-features-test-lib

check "black --version" black --version

reportResults
