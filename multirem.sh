#!/bin/bash
#
	PATTERN="$1"
	ROOT_FLAG=$2
	shift;shift
	COMMAND="$*"

	if [ -z "${PATTERN}" -o -z "${COMMAND}" ]
	then
		echo "Usage: $0 Host-Match-Pattern [Elevate-to-root] Command"
		exit
	fi

	DIRNAME=`dirname $0`
	REMOTE_CMD=${DIRNAME}/rem.sh
	HOST_LIST=${DIRNAME}/hostlist.dat
	MULTI_SCRIPT=/var/tmp/multirem_script.$$

	cat ${HOST_LIST} | cut -d' ' -f1 | grep "${PATTERN}" \
	| while read HOST_NAME
	do
		echo "echo ${HOST_NAME}:"
		echo ${REMOTE_CMD} ${HOST_NAME} \"${ROOT_FLAG}\" \"\" \"${COMMAND}\"
	done > ${MULTI_SCRIPT}

	${SHELL} ${MULTI_SCRIPT}
	rm -f ${MULTI_SCRIPT}
	exit

