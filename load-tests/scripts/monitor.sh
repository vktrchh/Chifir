#!/bin/bash
# monitor.sh - Мониторинг системы во время тестов
# РАСПОЛОЖЕНИЕ: ~/load-tests/scripts/monitor.sh
# ЗАПУСК: ./monitor.sh

BASE_URL="http://localhost:8080"
LOG_FILE="../results/monitor-$(date +"%Y%m%d_%H%M%S").log"

echo "=== МОНИТОРИНГ СИСТЕМЫ ===" | tee -a ${LOG_FILE}
echo "Лог сохраняется в: ${LOG_FILE}" | tee -a ${LOG_FILE}
echo "Нажмите Ctrl+C для остановки" | tee -a ${LOG_FILE}
echo "" | tee -a ${LOG_FILE}

while true; do
    clear
    TIMESTAMP=$(date +"%H:%M:%S")
    echo "=== МОНИТОРИНГ В РЕАЛЬНОМ ВРЕМЕНИ ===" | tee -a ${LOG_FILE}
    echo "Время: ${TIMESTAMP}" | tee -a ${LOG_FILE}
    echo "" | tee -a ${LOG_FILE}
    
    # CPU Usage
    echo "=== CPU ===" | tee -a ${LOG_FILE}
    top -bn1 | grep "Cpu(s)" | awk '{print "  " $2 " user, " $4 " system"}' | tee -a ${LOG_FILE}
    
    # Memory Usage
    echo "" | tee -a ${LOG_FILE}
    echo "=== ПАМЯТЬ ===" | tee -a ${LOG_FILE}
    free -h | grep "Mem:" | awk '{print "  Used: " $3 " / Total: " $2 " (" $3/$2*100 "%)"}' | tee -a ${LOG_FILE}
    
    # Backend health check
    echo "" | tee -a ${LOG_FILE}
    echo "=== BACKEND ===" | tee -a ${LOG_FILE}
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/actuator/health 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
        echo "  Status: UP (HTTP ${HTTP_CODE})" | tee -a ${LOG_FILE}
    else
        echo "  Status: DOWN (HTTP ${HTTP_CODE})" | tee -a ${LOG_FILE}
    fi
    
    # Response time
    RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" ${BASE_URL}/api/v1/feed 2>/dev/null)
    if [ -n "$RESPONSE_TIME" ]; then
        RESPONSE_MS=$(echo "$RESPONSE_TIME * 1000" | bc)
        echo "  Feed response time: ${RESPONSE_MS}ms" | tee -a ${LOG_FILE}
    fi
    
    # PostgreSQL connections
    echo "" | tee -a ${LOG_FILE}
    echo "=== POSTGRESQL ===" | tee -a ${LOG_FILE}
    sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;" -t 2>/dev/null | \
        awk '{print "  Active connections: " $1}' | tee -a ${LOG_FILE}
    
    sleep 5
done
