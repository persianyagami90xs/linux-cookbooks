#!/bin/bash -e

function installDependencies()
{
    if [[ "$(existCommand 'java')" = 'false' || ! -d "${EC2_API_TOOLS_JDK_INSTALL_FOLDER_PATH}" ]]
    then
        "$(dirname "${BASH_SOURCE[0]}")/../../jdk/recipes/install.bash" "${EC2_API_TOOLS_JDK_INSTALL_FOLDER_PATH}"
    fi
}

function install()
{
    umask '0022'

    # Clean Up

    initializeFolder "${EC2_API_TOOLS_INSTALL_FOLDER_PATH}"

    # Install

    unzipRemoteFile "${EC2_API_TOOLS_DOWNLOAD_URL}" "${EC2_API_TOOLS_INSTALL_FOLDER_PATH}"

    local -r unzipFolder="$(find "${EC2_API_TOOLS_INSTALL_FOLDER_PATH}" -maxdepth 1 -xtype d 2> '/dev/null' | tail -1)"

    if [[ "$(isEmptyString "${unzipFolder}")" = 'true' || "$(trimString "$(wc -l <<< "${unzipFolder}")")" != '1' ]]
    then
        fatal 'FATAL : multiple unzip folder names found'
    fi

    if [[ "$(ls -A "${unzipFolder}")" = '' ]]
    then
        fatal "FATAL : folder '${unzipFolder}' empty"
    fi

    # Move Folder

    moveFolderContent "${unzipFolder}" "${EC2_API_TOOLS_INSTALL_FOLDER_PATH}"
    rm -f -r "${unzipFolder}"

    # Config Profile

    local -r profileConfigData=('__INSTALL_FOLDER_PATH__' "${EC2_API_TOOLS_INSTALL_FOLDER_PATH}")

    createFileFromTemplate "$(dirname "${BASH_SOURCE[0]}")/../templates/ec2-api-tools.sh.profile" '/etc/profile.d/ec2-api-tools.sh' "${profileConfigData[@]}"

    umask '0077'
}

function main()
{
    source "$(dirname "${BASH_SOURCE[0]}")/../../../libraries/util.bash"
    source "$(dirname "${BASH_SOURCE[0]}")/../attributes/default.bash"

    header 'INSTALLING EC2-API-TOOLS'

    checkRequireLinuxSystem
    checkRequireRootUser

    installDependencies
    install
    installCleanUp
}

main "${@}"