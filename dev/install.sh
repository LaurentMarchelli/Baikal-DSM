#!/usr/bin/env bash

set -e

# Install toolchain dependencies
apt-get install -y git

# Install DSM 6.0 toolkit
# https://originhelp.synology.com/developer-guide/create_package/install_toolkit.html
mkdir -p /tookit
cd /tookit
git clone https://github.com/SynologyOpenSource/pkgscripts-ng.git

# # Install x64 platform, php does not need more.
# https://originhelp.synology.com/developer-guide/create_package/prepare_build_environment.html
cd pkgscripts-ng/
./EnvDeploy -v 6.0 -p x64

# /toolkit/source
