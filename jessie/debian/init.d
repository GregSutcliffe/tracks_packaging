#! /bin/sh
### BEGIN INIT INFO
# Provides:          tracks
# Required-Start:    $network $named $remote_fs $syslog
# Required-Stop:     $network $named $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

PATH=/usr/share/tracks/bin:/sbin:/usr/sbin:/bin:/usr/bin
DESC="Tracks GTD Rails application"
NAME=tracks
SCRIPTNAME=/etc/init.d/$NAME

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

TRACKS_IFACE=${TRACKS_IFACE:-'0.0.0.0'}
TRACKS_PORT=${TRACKS_PORT:-'3000'}
TRACKS_USER=${TRACKS_USER:-'tracks'}
TRACKS_HOME=${TRACKS_HOME:-'/usr/share/tracks'}
TRACKS_ENV=${TRACKS_ENV:-'production'}
TRACKS_PID=${TRACKS_PID:-"${TRACKS_HOME}/tmp/pids/server.pid"}

DAEMON="/usr/bin/bundle"
DAEMON_OPTS="exec rails server -b ${TRACKS_IFACE} -p ${TRACKS_PORT} -e ${TRACKS_ENV} -d"

. /lib/init/vars.sh
. /lib/lsb/init-functions

is_true() {
    if [ "x$1" = "xtrue" -o "x$1" = "xyes" -o "x$1" = "x0" ]; then
        return 0
    else
        return 1
    fi
}

do_start()
{
    if is_true "$START" ; then
        start-stop-daemon --start --quiet --chuid "${TRACKS_USER}" --pidfile "${TRACKS_PID}" \
                          --chdir "${TRACKS_HOME}" --exec "${DAEMON}" -- $DAEMON_OPTS >/dev/null
    else
        echo ""
        echo "${NAME} not configured to start. Please edit /etc/default/${NAME} to enable."
    fi
}

do_stop()
{
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile "${TRACKS_PID}"
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2
    [ "$RETVAL" = 0 ] && rm -f $TRACKS_PID
    return "$RETVAL"
}

case "$1" in
    start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting" "$NAME"
        do_start
        case "$?" in
            0|1) RETVAL=0; [ "$VERBOSE" != no ] && log_end_msg "$RETVAL" ;;
            2) RETVAL=1; [ "$VERBOSE" != no ] && log_end_msg "$RETVAL" ;;
        esac
	exit "$RETVAL"
        ;;
    stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping" "$NAME"
        do_stop
        case "$?" in
            0|1) RETVAL=0; [ "$VERBOSE" != no ] && log_end_msg "$RETVAL" ;;
            2) RETVAL=1; [ "$VERBOSE" != no ] && log_end_msg "$RETVAL" ;;
        esac
	exit "$RETVAL"
        ;;
    status)
        status_of_proc -p "$TRACKS_PID" "$DAEMON" "$NAME" && exit 0 || exit $?
        ;;
    restart|force-reload)
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        log_daemon_msg "Restarting " "$NAME"
        do_stop
        case "$?" in
            0|1)
                do_start
                case "$?" in
                    0) log_end_msg 0 ;;
                    1) log_end_msg 1 ;; # Old process is still running
                    *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
            *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
    *)
        echo "Usage: ${SCRIPTNAME} {start|stop|status|restart|force-reload}" >&2
        exit 3
        ;;
esac
