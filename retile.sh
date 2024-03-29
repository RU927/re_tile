#!/bin/bash

# Fetch submodules
# git submodule update --init --recursive

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'
# GREEN2='[32;1m'
WHITE='[37;1m'
# BLUE='[34;1m'

RV='\u001b[7m'

this_dir="$(dirname "$(realpath "$0")")"
dot_config=$this_dir/config
dot_home=$this_dir/home
config_dir=$HOME/.config
# src_dir=$HOME/src/lua
font_dir=$HOME/.local/share/fonts

configExists() {
	[[ -e "$1" ]] && [[ ! -L "$1" ]]
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

checkEnv() {
	## Check Package Handeler
	PACKAGEMANAGER='apt dnf'
	for pgm in ${PACKAGEMANAGER}; do
		if command_exists "${pgm}"; then
			PACKAGER=${pgm}
			echo -e "${RV}Using ${pgm}"
		fi
	done

	if [ -z "${PACKAGER}" ]; then
		echo -e "${RED}Can't find a supported package manager"
		exit 1
	fi

	## Check if the current directory is writable.
	PATHs="$this_dir $config_dir "
	for path in $PATHs; do
		if [[ ! -w ${path} ]]; then
			echo -e "${RED}Can't write to ${path}${RC}"
			exit 1
		fi
	done
}

checkEnv

function install_packages {
	DEPENDENCIES='xauth xorg i3lock'

	echo -e "${YELLOW}Installing required packages...${RC}"
	sudo "${PACKAGER}" install -yq "${DEPENDENCIES}"
}

function back_sym {
	# перед создание линков делает бекапы только тех пользовательских конфикураций,
	# файлы которых есть в ./config ./home
	mkdir -p "$config_dir"
	echo -e "${RV}${YELLOW} Backing up existing files... ${RC}"
	for config in $(command ls "${dot_config}"); do
		if configExists "${config_dir}/${config}"; then
			echo -e "${YELLOW}Moving old config ${config_dir}/${config} to ${config_dir}/${config}.old${RC}"
			if ! mv "${config_dir}/${config}" "${config_dir}/${config}.old"; then
				echo -e "${RED}Can't move the old config!${RC}"
				exit 1
			fi
			echo -e "${WHITE} Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old' ${RC}"
		fi
		echo -e "${GREEN}Linking ${dot_config}/${config} to ${config_dir}/${config}${RC}"
		if ! ln -snf "${dot_config}/${config}" "${config_dir}/${config}"; then
			echo echo -e "${RED}Can't link the config!${RC}"
			exit 1
		fi
	done

	for config in $(command ls "${dot_home}"); do
		if configExists "$HOME/.${config}"; then
			echo -e "${YELLOW}Moving old config ${HOME}/.${config} to ${HOME}/.${config}.old${RC}"
			if ! mv "${HOME}/.${config}" "${HOME}/.${config}.old"; then
				echo -e "${RED}Can't move the old config!${RC}"
				exit 1
			fi
			echo -e "${WHITE} Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old' ${RC}"
		fi
		echo -e "${GREEN}Linking ${dot_home}/${config} to ${HOME}/.${config}${RC}"
		if ! ln -snf "${dot_home}/${config}" "${HOME}/.${config}"; then
			echo echo -e "${RED}Can't link the config!${RC}"
			exit 1
		fi
	done

}

# Lua
function install_lua {
	if ! command_exists lua; then
		echo -e "${RV} Installing Lua ${RC}"
	fi
}

# Luarocks
function install_luarocks {
	if command_exists lua; then
		if ! command_exists luarocks; then
			echo -e "${RV} Installing Luarocks... ${RC}"
		else
			echo -e "${RV} Luarocks is installed${RC}"
		fi
	else
		echo -e "${RED}Lua is not installed!${RC}"
		install_lua
		install_luarocks
	fi
}

# Awesome
function install_awesome {
	if ! command_exists awesome; then
		echo -e "${RV} Installing awesome... ${RC}"
		sudo apt install awesome awesome-extra
	else
		echo -e "${RV} Awesome is installed ${RC}"
	fi
}

function install_fonts {
	echo -e "\u001b[7m Installing fonts \u001b[0m"
	mkdir -p "$font_dir"
	cp "$this_dir"/set/awesomewm-font.ttf ~/.local/share/fonts/
	sudo fc-cache -fr
}

function all {
	echo -e "\u001b[7m Setting up Dotfiles... \u001b[0m"
	install_packages
	back_sym
	install_lua
	install_luarocks
	install_awesome
	install_fonts
	echo -e "\u001b[7m Done! \u001b[0m"
}

if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
	all
	exit 0
fi

# Menu TUI
echo -e "\u001b[32;1m Setting up Dotfiles...\u001b[0m"

echo -e " \u001b[37;1m\u001b[4mSelect an option:\u001b[0m"
echo -e "  \u001b[34;1m (a) ALL \u001b[0m"
echo -e "  \u001b[34;1m (p) install packages \u001b[0m"
echo -e "  \u001b[34;1m (s) backup and symlink \u001b[0m"
echo -e "  \u001b[34;1m (l) install lua \u001b[0m"
echo -e "  \u001b[34;1m (r) install luarocks (5,6,13) \u001b[0m"
echo -e "  \u001b[34;1m (w) install awesome \u001b[0m"
echo -e "  \u001b[34;1m (f) fonts \u001b[0m"

echo -e "  \u001b[31;1m (*) Anything else to exit \u001b[0m"

echo -en "\u001b[32;1m ==> \u001b[0m"

read -r option

case $option in

"a")
	all
	;;

"p")
	install_packages
	;;

"s")
	back_sym
	;;

"l")
	install_lua
	;;

"r")
	install_luarocks
	;;

"w")
	install_awesome
	;;

"f")
	install_fonts
	;;

*)
	echo -e "\u001b[31;1m Invalid option entered, Bye! \u001b[0m"
	exit 0
	;;
esac

exit 0
