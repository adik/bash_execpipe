#!/bin/bash
# Author: smirnov.arkady@gmail.com

# INSTALL
#
# Add to crontab:
# * * * * *     /path/to/execpipe.sh status || /path/to/execpipe.sh start
# 
# Sample:
# find . -name '*.mp3' ! -path '*previews*' -exec bash -c 'echo {} && echo {} >/tmp/execpipe_cmd' \;
#

PIPE=/tmp/execpipe_cmd
PIDFILE=/var/run/execpipe.pid

HANDLER=./test.sh

# delay between executions
EXECSLEEP=0.5

PIPECHMOD=0777
PIPECHOWN=root.root

check_status() {
    if [ ! -f $PIDFILE ]; then
        echo 'Could not open ('$PIDFILE')'
        return 1
    elif ! kill -0 `cat $PIDFILE` &>/dev/null; then
        echo 'Calling app pid (='`cat $PIDFILE`') is not reposnding.'
        return 1
    fi
}


run_daemon() {
  #if [[ ! -p $PIPE ]]; then
    rm -f "$PIPE" "$PIPE.out" 2>/dev/null
    if mkfifo "$PIPE" "$PIPE.out"; then 
      chmod $PIPECHMOD "$PIPE" 
      chmod 700 "$PIPE.out"
    else
      return 1
    fi
  #fi

  while true; do
    while IFS="" read -r -d $'\n' line; do
      printf '%s\n' "${line}"
    done <$PIPE >$PIPE.out &
    bgproxy=$!

    exec 3>$PIPE
    exec 4<$PIPE.out

    while IFS="" read -r -d $'\n' <&4 line; do
      #echo `date +%s` $line >> /tmp/zzzdsfdf
       [ -x "$HANDLER" ] && $HANDLER $line
      sleep $EXECSLEEP
    done &
    bgreader=$!

    trap "kill -TERM $bgproxy;kill -TERM $bgreader; echo 'bgproxy=$bgproxy bgreader=$bgreader'; rm -f '$PIPE'; exit" 0 1 2 3 13 15
    wait "$bgproxy"
    echo "restarting..."
  done 
}

# ---------------
case "$1" in
    daemon)
      run_daemon
      ;;
    status)
      check_status
      ;;
    start)
      if ! touch $PIDFILE >/dev/null 2>&1 && [ ! -w $PIDFILE ]; then
        echo "PIDFILE (=$PIDFILE) not writeable" >&2
      elif ! check_status >/dev/null; then
        echo 'Daemonize' 
        nohup $0 daemon >/dev/null 2>&1 &
        echo $! > $PIDFILE
      else
        echo 'Already running'
      fi
      ;;
    stop)
      kill `cat $PIDFILE`
      ;;
    *)
      echo "Usage: $0 {start|stop|status}" >&2
      exit 1
      ;;
esac

