#!/bin/sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/userdata/app/lib
case "$1" in
  start)
	echo "Starting Ai-server..."
	start-stop-daemon --start --background --exec /userdata/app/bin/Ai-server &
	/userdata/app/bin/ai-server-deamon.sh  &
	echo "OK"
	;;
  stop)
	echo "Stoping Ai-server..."
	killall Ai-server
	#killall robot_camera_test
	;;
  restart)
	"$0" stop
	sleep 1 # Prevent race condition: ensure wifi stops before start.
	"$0" start
	;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

