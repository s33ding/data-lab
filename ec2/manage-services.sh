#!/bin/bash

case "$1" in
    start)
        echo "Starting Kafka services..."
        sudo systemctl start zookeeper
        sleep 10
        sudo systemctl start kafka
        sleep 10
        sudo systemctl start kafka-connect
        echo "All services started"
        ;;
    stop)
        echo "Stopping Kafka services..."
        sudo systemctl stop kafka-connect
        sudo systemctl stop kafka
        sudo systemctl stop zookeeper
        echo "All services stopped"
        ;;
    status)
        echo "=== Zookeeper ==="
        sudo systemctl status zookeeper --no-pager
        echo -e "\n=== Kafka ==="
        sudo systemctl status kafka --no-pager
        echo -e "\n=== Kafka Connect ==="
        sudo systemctl status kafka-connect --no-pager
        ;;
    restart)
        $0 stop
        sleep 5
        $0 start
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
