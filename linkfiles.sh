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
    fi;
    if [[ -e "${2}" ]]; then
        echo "Local name ${2} exists, delete it first if you meant it";
        return 2;
    fi;
    if [[ ! -e "${1}" ]]; then
        echo "Remote file or directory ${1} doesn't exist";
        return 3;
    fi;
    echo "About to symlink ${1} to ${2}"
    ln -s "${1}" "${2}"
}

[[ ! -e $(pwd)/.bashrc ]] && echo "Run this script from the git repo" && return 1
symlink $(pwd)/.bash_env ~/.bash_env
symlink $(pwd)/.bash_profile ~/.bash_profile
symlink $(pwd)/.bashrc ~/.bashrc
symlink $(pwd)/checkip ~/bin/checkip
symlink $(pwd)/defaults ~/bin/defaults
symlink $(pwd)/findprefs ~/bin/findprefs
symlink $(pwd)/hang ~/bin/hang
symlink $(pwd)/inline ~/bin/inline
symlink $(pwd)/ipinfo ~/bin/ipinfo
symlink $(pwd)/proxy ~/bin/proxy
symlink $(pwd)/scrab ~/bin/scrab
symlink $(pwd)/timedns ~/bin/timedns
symlink $(pwd)/watchnet ~/bin/watchnet
[[ -e /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport ]] && symlink /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport ~/bin/airport

[[ ! -d ~/Library/KeyBindings ]] && mkdir ~/Library/KeyBindings
symlink $(pwd)/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict

symlink $(pwd)/init.el ~/.emacs.d/init.el
[[ ! -d ~/.emacs.d/add-ins ]] && mkdir ~/.emacs.d/add-ins
symlink $(pwd)/applescript.el ~/.emacs.d/add-ins/applescript.el
symlink $(pwd)/editorconfig.el ~/.emacs.d/add-ins/editorconfig.el
symlink $(pwd)/markdown-mode.el ~/.emacs.d/add-ins/markdown-mode.el

echo "About to symbolically link (with sudo) $(pwd)/dict_scrabble /usr/share/dict/altscrab"
sudo ln -s $(pwd)/dict_scrabble /usr/share/dict/altscrab
symlink $(pwd)/org.gnu.emacsserver.plist ~/Library/LaunchAgents/org.gnu.emacsserver.plist

symlink $(pwd)/config ~/.ssh/config
echo "Copy com.centvc.socat_listener.plist if desired into ~/Library/LaunchAgents"

