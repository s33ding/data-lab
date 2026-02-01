#!/bin/bash

PID_FILE="/tmp/postgres-portforward.pid"
LOCAL_PORT=5432
SERVICE_NAME="postgres"
SERVICE_PORT=5432

start_portforward() {
    if [ -f "$PID_FILE" ]; then
        echo "Port forward already running (PID: $(cat $PID_FILE))"
        return
    fi
    
    echo "Starting PostgreSQL port forward..."
    kubectl port-forward svc/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT &
    echo $! > "$PID_FILE"
    echo "Port forward started on localhost:$LOCAL_PORT (PID: $!)"
}

stop_portforward() {
    if [ ! -f "$PID_FILE" ]; then
        echo "No port forward running"
        return
    fi
    
    PID=$(cat "$PID_FILE")
    kill $PID 2>/dev/null
    rm "$PID_FILE"
    echo "Port forward stopped"
}

case "$1" in
    start)
        start_portforward
        ;;
    stop)
        stop_portforward
        ;;
    restart)
        stop_portforward
        sleep 1
        start_portforward
        ;;
    status)
        if [ -f "$PID_FILE" ]; then
            echo "Port forward running (PID: $(cat $PID_FILE))"
        else
            echo "Port forward not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
