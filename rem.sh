#!/bin/bash
#
	HOST=$1
	ROOT_OPTION=$2
	USER=$3

	shift;shift;shift
	COMMAND="$*"

	DIRNAME=`dirname $0`
	HOST_LIST=${DIRNAME}/hostlist.dat
	EXPECT_SCRIPT=/var/tmp/rem_expect_script.$$

	if [ -z "${HOST}" ]
	then
		echo "Usage: $0 Hostname [Elevate-to-root-flag] [Username (default=LVSLinuxAdmin)] [Command (or interactive if not provided)]"
		echo "CSU Hosts:"
		cat ${HOST_LIST} | cut -d' ' -f1
		echo
		exit
	fi

	if [ -z "${USER}" ]
	then
		USER="LVSLinuxAdmin"
	fi

	CREDENTIAL_FILE=${DIRNAME}/.credential_${USER}
	if [ -f ${CREDENTIAL_FILE} ]
	then
		PASSWORD=`cat ${CREDENTIAL_FILE}`
	else
		echo -n "Password: "
		read PASSWORD
	fi

	HOST_IP=`grep -i "^${HOST} " ${HOST_LIST} | cut -d' ' -f2`
	ping -c 1 -t 5 ${HOST_IP} 2>&1 > /dev/null
	if [ $? -ne 0 ]
	then
		echo "${HOST} not reachable - aborting"
		exit 255
	fi

	cat > ${EXPECT_SCRIPT} << EOI
set timeout -1
spawn -noecho \$env(SHELL)
match_max 100000
EOI

	if [ -n "${COMMAND}" ]
	then
		printf "log_user 0\n" >> ${EXPECT_SCRIPT}
	fi
	printf "send -- \"ssh -o \\\\\"StrictHostKeyChecking No\\\\\" -l [lindex \$argv 1] [lindex \$argv 0]\\\\r\"\n" >> ${EXPECT_SCRIPT}

	printf "expect \"password: \"\n" >> ${EXPECT_SCRIPT}
	printf "send -- \"[lindex \$argv 2]\\\\r\"\n" >> ${EXPECT_SCRIPT}

	printf "expect \"[lindex \$argv 1]\"\n" >> ${EXPECT_SCRIPT}

	if [ -n "${ROOT_OPTION}" ]
	then
		printf "send \"sudo -i\\\\r\"\n" >> ${EXPECT_SCRIPT}
		printf "expect \"password for [lindex \$argv 1]:\"\n" >> ${EXPECT_SCRIPT}
		printf "send -- \"[lindex \$argv 2]\\\\r\"\n" >> ${EXPECT_SCRIPT}
		printf "expect \"root\"\n" >> ${EXPECT_SCRIPT}
	fi

	if [ -z "${COMMAND}" ]
	then
		printf "interact -o \"Connection to [lindex \$argv 0] closed.\" return\n" >> ${EXPECT_SCRIPT}
	else
		printf "log_user 1\n" >> ${EXPECT_SCRIPT}
		printf "send -- \"${COMMAND}\\\\r\"\n" >> ${EXPECT_SCRIPT}
		if [ -z "${ROOT_OPTION}" ]
		then
			printf "expect \"[lindex \$argv 1]\"\n" >> ${EXPECT_SCRIPT}
		else
			printf "expect \"root\"\n" >> ${EXPECT_SCRIPT}
		fi
#		printf "log_user 0\n" >> ${EXPECT_SCRIPT}
		printf "send -- \"exit\\\\r\"\n" >> ${EXPECT_SCRIPT} 
		if [ -n "${ROOT_OPTION}" ]
		then
			printf "expect \"[lindex \$argv 1]\"\n" >> ${EXPECT_SCRIPT}
			printf "send -- \"exit\\\\r\"\n" >> ${EXPECT_SCRIPT} 
		fi
		printf "interact -o \"Connection to [lindex \$argv 0] closed.\" return\n" >> ${EXPECT_SCRIPT}
	fi

	printf "exit\n" >> ${EXPECT_SCRIPT}

#	cat ${EXPECT_SCRIPT}
	expect -f ${EXPECT_SCRIPT} ${HOST_IP} ${USER} ${PASSWORD} | (
		if [ -n "${COMMAND}" ]
		then
			cat | tr -d '\r' | grep -v " exit$" \
			| grep -v "^logout$" | tail -n +2
		else
			cat
		fi
	)
	rm -f ${EXPECT_SCRIPT}

	exit
