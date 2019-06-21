#!/bin/bash -e

function installDependencies()
{
    installBuildEssential
    installPackage 'libssl-dev' 'openssl-devel'
}

function install()
{
    umask '0022'

    # Clean Up

    initializeFolder "${NGINX_INSTALL_FOLDER_PATH}"

    # Download Dependencies

    local -r tempPCREFolder="$(getTemporaryFolder)"
    unzipRemoteFile "${NGINX_PCRE_DOWNLOAD_URL}" "${tempPCREFolder}"

    local -r tempZLIBFolder="$(getTemporaryFolder)"
    unzipRemoteFile "${NGINX_ZLIB_DOWNLOAD_URL}" "${tempZLIBFolder}"

    # Install

    local -r tempFolder="$(getTemporaryFolder)"

    unzipRemoteFile "${NGINX_DOWNLOAD_URL}" "${tempFolder}"
    addUser "${NGINX_USER_NAME}" "${NGINX_GROUP_NAME}" 'false' 'true' 'false'
    cd "${tempFolder}"
    "${tempFolder}/configure" \
        "${NGINX_CONFIG[@]}" \
        --with-pcre="${tempPCREFolder}" \
        --with-zlib="${tempZLIBFolder}"
    make
    make install
    rm -f -r "${tempFolder}" "${tempPCREFolder}" "${tempZLIBFolder}"

    # Config Server

    local -r serverConfigData=('__PORT__' "${NGINX_PORT}")

    createFileFromTemplate "$(dirname "${BASH_SOURCE[0]}")/../templates/nginx.conf.conf" "${NGINX_INSTALL_FOLDER_PATH}/conf/nginx.conf" "${serverConfigData[@]}"

    # Config Log

    touch "${NGINX_INSTALL_FOLDER_PATH}/logs/access.log"
    touch "${NGINX_INSTALL_FOLDER_PATH}/logs/error.log"

    # Config Profile

    local -r profileConfigData=('__INSTALL_FOLDER_PATH__' "${NGINX_INSTALL_FOLDER_PATH}")

    createFileFromTemplate "$(dirname "${BASH_SOURCE[0]}")/../templates/nginx.sh.profile" '/etc/profile.d/nginx.sh' "${profileConfigData[@]}"

    # Config Init

    local -r initConfigData=('__INSTALL_FOLDER_PATH__' "${NGINX_INSTALL_FOLDER_PATH}")

    createInitFileFromTemplate "${NGINX_SERVICE_NAME}" "$(dirname "${BASH_SOURCE[0]}")/../templates" "${initConfigData[@]}"

    # Start

    chown -R "${NGINX_USER_NAME}:${NGINX_GROUP_NAME}" "${NGINX_INSTALL_FOLDER_PATH}"
    startService "${NGINX_SERVICE_NAME}"

    # Display Open Ports

    displayOpenPorts '5'

    # Display Version

    displayVersion "$(nginx -V 2>&1)"

    umask '0077'
}

function main()
{
    source "$(dirname "${BASH_SOURCE[0]}")/../../../libraries/util.bash"
    source "$(dirname "${BASH_SOURCE[0]}")/../attributes/source.bash"

    header 'INSTALLING NGINX FROM SOURCE'

    checkRequireLinuxSystem
    checkRequireRootUser
    checkRequirePorts "${NGINX_PORT}"

    installDependencies
    install
    installCleanUp
}

main "${@}"