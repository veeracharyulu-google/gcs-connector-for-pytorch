#!/bin/bash
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Fail on any error.
set -e

# Code under repo is checked out to this directory.
cd "${KOKORO_ARTIFACTS_DIR}/github/dataflux-pytorch"

function setup_virtual_envs() {
    echo Setting up Python virtual environment.
    local venv_dir="${TMPDIR:-/tmp}/venv"
    rm -rf "${venv_dir}"
    if ! python3 -m venv "${venv_dir}" 2>/dev/null; then
        rm -rf "${venv_dir}"
        if python3 -m virtualenv --version >/dev/null 2>&1; then
            python3 -m virtualenv "${venv_dir}"
        else
            sudo apt-get -y update
            sudo apt install -y python3-venv
            python3 -m venv "${venv_dir}"
        fi
    fi
    source "${venv_dir}/bin/activate"
}

function run_git_commands() {
    echo Setting git permissions.
    git config --global --add safe.directory "*" 

    echo Installing git submodules.
    git submodule init

    echo Updating git submodules.
    git submodule update
}

function install_requirements() {
    echo Installing pytest.
    python3 -m pip install --no-cache-dir pytest

    echo Installing project from PyPI.
    python3 -m pip install --no-cache-dir gcs-torch-dataflux
}

function run_integration_tests(){
    echo Running integration tests on PyPI version.
    # NOTE: Using pytest command ensures tests run against the installed PyPI package.
    # On adding `python3 -m` to the command, the test will run on the local version.
    pytest dataflux_pytorch/integration_tests/integration_test.py -vv --junit-xml="${KOKORO_ARTIFACTS_DIR}/integration_tests/sponge_log.xml" --log-cli-level=DEBUG
}

setup_virtual_envs
run_git_commands
install_requirements
run_integration_tests
