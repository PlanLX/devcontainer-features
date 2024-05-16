#!/bin/bash -i

set -e

source dev-container-features-test-lib

check "magic-gfw --version" magic-gfw --version

reportResults
