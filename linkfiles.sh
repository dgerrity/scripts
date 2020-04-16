#!/usr/bin/env bash
################################################################################
#
# linkefiles.sh - sets up symlinks for the executables in this repo
#
################################################################################

function symlink() 
{ 
    if [[ -z ${2} ]]; then
        echo "Usage: $FUNCNAME remote-path local-name";
        echo "ln -s remote-path local-name";
        return 1;
    elif [[ -L "${2}" ]]; then
        echo "Skipping echo $(\ls -l "${2}" | cut -c43-)"
        return 2;
    elif [[ -e "${2}" ]]; then
	echo "Not linking: Target file ${2} exists and is not a symlink."
	return 3;
    elif [[ ! -e "${1}" ]]; then
        echo "Not linking: Remote file or directory ${1} doesn't exist";
        return 4;
    fi;
    echo "About to symlink ${1} to ${2}"
    ln -s "${1}" "${2}"
}

[[ ! -e $(pwd)/.bashrc ]] && echo "Run this script from the git repo" && return 1

[[ ! -d ${HOME}/bin ]] && mkdir ${HOME}/bin

symlink $(pwd)/.bash_env ${HOME}/.bash_env
symlink $(pwd)/.bash_profile ${HOME}/.bash_profile
symlink $(pwd)/.bashrc ${HOME}/.bashrc
symlink $(pwd)/checkip ${HOME}/bin/checkip
symlink $(pwd)/defaults ${HOME}/bin/defaults
symlink $(pwd)/ec ${HOME}/bin/ec
symlink $(pwd)/emacsc ${HOME}/bin/emacsc
symlink $(pwd)/emacst ${HOME}/bin/emacst
symlink $(pwd)/findprefs ${HOME}/bin/findprefs
symlink $(pwd)/hang ${HOME}/bin/hang
symlink $(pwd)/inline ${HOME}/bin/inline
symlink $(pwd)/ipinfo ${HOME}/bin/ipinfo
symlink $(pwd)/proxy ${HOME}/bin/proxy
symlink $(pwd)/scrab ${HOME}/bin/scrab
symlink $(pwd)/timedns ${HOME}/bin/timedns
symlink $(pwd)/watchnet ${HOME}/bin/watchnet

[[ -e /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport ]] && symlink /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport ${HOME}/bin/airport

[[ ! -d ~/Library/KeyBindings ]] && mkdir ~/Library/KeyBindings
cp $(pwd)/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict

symlink $(pwd)/init.el ~/.emacs.d/init.el
[[ ! -d ~/.emacs.d/add-ins ]] && mkdir ~/.emacs.d/add-ins
symlink $(pwd)/applescript.el ~/.emacs.d/add-ins/applescript.el
symlink $(pwd)/editorconfig.el ~/.emacs.d/add-ins/editorconfig.el
symlink $(pwd)/markdown-mode.el ~/.emacs.d/add-ins/markdown-mode.el

#echo "About to symbolically link (with sudo) $(pwd)/dict_scrabble /usr/share/dict/altscrab"
#sudo ln -s $(pwd)/dict_scrabble /usr/share/dict/altscrab

symlink $(pwd)/org.gnu.emacsserver.plist ~/Library/LaunchAgents/org.gnu.emacsserver.plist
symlink $(pwd)/wakeup ~/.wakeup
symlink $(pwd)/sleep ~/.sleep
symlink $(pwd)/config ~/.ssh/config

echo "Copy com.centvc.socat_listener.plist if desired into ~/Library/LaunchAgents"

