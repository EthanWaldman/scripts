#!/bin/bash
 #
        SERVER_NAME=$1

        IP_ADDRESS=`cat ~/server_list | grep -i -w "^${SERVER_NAME}" | cut -f2`

        shift
        ssh -q -t ${IP_ADDRESS} "$*" 2>/dev/null

