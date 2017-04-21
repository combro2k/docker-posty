#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

export DEBIAN_FRONTEND="noninteractive"

PACKAGES=(
    'libmysqlclient-dev'
    'mysql-client'
)

load_rvm()
{
    if [ -f "${APP_HOME}/.rvm/scripts/rvm" ]
    then
        source ${APP_HOME}/.rvm/scripts/rvm
    else
        echo "Could not load RVM"
        return 1
    fi

    return 0
}

pre_install() {
    sudo mkdir -p /var/vmail || return 1
    sudo chmod +x /usr/local/bin/* || return 1

    mkdir -p /home/app/posty_api || return 1

    sudo apt-get update 2>&1 || return 1
    sudo apt-get install -yq ${PACKAGES[@]} 2>&1 || return 1

    return 0
}

install_posty_api()
{
    curl --location --silent \
            https://github.com/posty/posty_api/archive/v2.0.4.tar.gz | tar zx -C /home/app/posty_api --strip-components=1 2>&1 || return 1

    cd /home/app/posty_api 2>&1 || return 1

    # Fix issues with json gem .. 
    bundle update json 2>&1 || return 1
    bundle install 2>&1 || return 1

    return 0
}

install_posty_client(){
    gem install posty_client || return 1

    return 0
}

post_install() {
	sudo apt-get autoremove 2>&1 || return 1
	sudo apt-get autoclean 2>&1 || return 1
	sudo rm -fr /var/lib/apt 2>&1 || return 1

	sudo chown ${APP_USER}:${APP_USER} ${APP_HOME} /var/vmail -R

	return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	tasks=(
	    'pre_install'
        'install_posty_api'
        'install_posty_client'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..." || exit 1
		${task} | tee -a "${INSTALL_LOG}" > /dev/null 2>&1 || exit 1
	done
}

eval load_rvm

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1 || exit 1
		${task} 2>&1 || exit 1
	done
fi
