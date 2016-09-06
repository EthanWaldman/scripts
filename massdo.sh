#!/bin/bash
#!
         SERVER_PATTERN="${1}"
         shift
         COMMAND="$*"

         cat ~/server_list | grep -v lb | grep -v win | grep -v '^$' | grep -i "${SERVER_PATTERN}" | cut -f1 \
         | while read SERVER_NAME
         do
                 echo -n "${SERVER_NAME}: "
                 ~/sshn.sh ${SERVER_NAME} "${COMMAND}" < /dev/tty
                 echo ""
         done
