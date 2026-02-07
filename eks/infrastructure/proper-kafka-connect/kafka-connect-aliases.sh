# Kafka Connect aliases
alias kc-exec='kubectl exec kafka-connect-proper-0 -n lab --'
alias kc-curl='kubectl exec kafka-connect-proper-0 -n lab -- curl -s'
alias kc-post='kubectl exec kafka-connect-proper-0 -n lab -- curl -X POST -H "Content-Type: application/json"'
alias kc-list='kc-curl http://localhost:8083/connectors'
alias kc-status='kc-curl http://localhost:8083/connectors/$1/status'
alias kc-delete='kubectl exec kafka-connect-proper-0 -n lab -- curl -X DELETE http://localhost:8083/connectors/$1'
alias kc-logs='kubectl logs kafka-connect-proper-0 -n lab --tail=50'
alias kc-pod='kubectl get pods -n lab -l app=kafka-connect-proper'
