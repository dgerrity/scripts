#!/usr/bin/env bash
################################################################################
#
# linkefiles.sh - sets up symlinks for the executables in this repo
#
################################################################################

function symlink() 
{ 
    if [[ -z "${2}" ]]; then
        echo "Usage: $FUNCNAME remote-path local-name";
        echo "ln -s remote-path local-name";
        return 1;
    elif [[ -L "${2}" ]]; then
        echo "${2}"
        return 2;
    elif [[ -e "${2}" ]]; then
	echo "Skipping $(\ls -l "${2}" | cut -c43-): Target file exists and is NOT symlink."
	return 3;
    elif [[ ! -e "${1}" ]]; then
        echo "Not linking: Remote file or directory ${1} doesn't exist";
        return 4;
    fi;
    echo "About to symlink ${1} to ${2}"
    ln -s "${1}" "${2}"
}

function linkfile() {
    symlink "$(pwd)/${1}" "${HOME}/bin/${1}"
}    

[[ ! -e "$(pwd)/.bashrc" ]] && echo "Run this script from the git repo" && return 1

[[ ! -d "${HOME}/bin" ]] && mkdir "${HOME}/bin"

symlink "$(pwd)/.bash_env" "${HOME}/.bash_env"
symlink "$(pwd)/.bash_profile" "${HOME}/.bash_profile"
symlink "$(pwd)/.bashrc" "${HOME}/.bashrc"
symlink "$(pwd)/known_mac_addresses" "${HOME}/.knownmacaddresses"
symlink "$(pwd)/wakeup" "${HOME}/.wakeup"
symlink "$(pwd)/sleep" "${HOME}/.sleep"
symlink "$(pwd)/config" "${HOME}/.ssh/config"

linkfile checkip
linkfile defaults
linkfile ec
linkfile emacsc
linkfile emacst
linkfile findprefs
linkfile hang
linkfile inline
linkfile ipinfo
linkfile proxy
linkfile ovpn
linkfile quartiles
linkfile scrab
linkfile timedns
linkfile today
linkfile vol
linkfile watchnet
linkfile zn

[[ -e /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport ]] && \
    symlink /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport "${HOME}/bin/airport"

symlink "$(pwd)/init.el" "${HOME}/.emacs.d/init.el"
[[ ! -d "${HOME}/.emacs.d/add-ins" ]] && mkdir "${HOME}/.emacs.d/add-ins"
symlink "$(pwd)/applescript.el" "${HOME}/.emacs.d/add-ins/applescript.el"
symlink "$(pwd)/editorconfig.el" "${HOME}/.emacs.d/add-ins/editorconfig.el"
symlink "$(pwd)/markdown-mode.el" "${HOME}/.emacs.d/add-ins/markdown-mode.el"

echo ">> Copy com.centvc.socat_listener.plist if desired into ${HOME}/Library/LaunchAgents"
echo ">> Copy $(pwd)/com.centvc.iperf3.plist if desired into ${HOME}/Library/LaunchAgents"
