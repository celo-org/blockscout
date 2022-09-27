#!/usr/bin/env bash

if f[ -z "$1" ] 
  then
    echo "Usage: bin/local_iex.sh <your name here>
    return 2
fi

COOKIE=$ERLANG_COOKIE
NAME=$1

exec iex --name $NAME --cookie $COOKIE --remsh blockscout@$POD_IP
