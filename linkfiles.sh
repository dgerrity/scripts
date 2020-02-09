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

symlink $(pwd)/.bash_env ~/.bash_env
symlink $(pwd)/.bash_profile ~/.bash_profile
symlink $(pwd)/.bashrc ~/.bashrc
symlink $(pwd)/checkip /usr/local/bin/checkip
symlink $(pwd)/defaults /usr/local/bin/defaults
symlink $(pwd)/findprefs /usr/local/bin/findprefs
symlink $(pwd)/hang /usr/local/bin/hang
symlink $(pwd)/inline /usr/local/bin/inline
symlink $(pwd)/ipinfo /usr/local/bin/ipinfo
symlink $(pwd)/proxy /usr/local/bin/proxy
symlink $(pwd)/scrab /usr/local/bin/scrab
symlink $(pwd)/timedns /usr/local/bin/timedns
symlink $(pwd)/watchnet /usr/local/bin/watchnet
[[ ! -d ~/Library/KeyBindings ]] && mkdir ~/Library/KeyBindings
symlink $(pwd)/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict
symlink $(pwd)/init.el ~/.emacs.d/init.el
[[ ! -d ~/.emacs.d/add-ins ]] && mkdir ~/.emacs.d/add-ins
symlink $(pwd)/applescript.el ~/.emacs.d/add-ins/applescript.el
symlink $(pwd)/editorconfig.el ~/.emacs.d/add-ins/editorconfig.el
symlink $(pwd)/markdown-mode.el ~/.emacs.d/add-ins/markdown-mode.el
echo "About to symbolically link (with sudo) $(pwd)/dict_scrabble /usr/share/dict/altscrab"
sudo ln -s $(pwd)/dict_scrabble /usr/share/dict/altscrab
sudo ln -s $(pwd)/org.gnu.emacsserver.plist ~/Library/LaunchAgents/org.gnu.emacsserver.plist


