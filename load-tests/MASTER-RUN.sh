#!/bin/bash
# MASTER-RUN.sh - Главный скрипт для запуска всего
# РАСПОЛОЖЕНИЕ: ~/load-tests/MASTER-RUN.sh
# ЗАПУСК: chmod +x MASTER-RUN.sh && ./MASTER-RUN.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ МИКРОБЛОГИНГА            ║${NC}"
echo -e "${BLUE}║              ПОЛНЫЙ АВТОМАТИЗИРОВАННЫЙ ЗАПУСК         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Проверка наличия всех файлов
echo -e "${YELLOW}Проверка структуры файлов...${NC}"

FILES_TO_CHECK=(
    "k6-tests/load-test-script.js"
    "scripts/run-load-tests.sh"
    "jmeter-tests/load-test-plan.jmx"
    "vegeta-tests/vegeta-test.sh"
    "locust-tests/locustfile.py"
    "monitoring/docker-compose-monitoring.yml"
    "scripts/monitor.sh"
    "scripts/run-all-tests.sh"
)

MISSING_FILES=0
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file - ОТСУТСТВУЕТ"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo -e "\n${RED}Ошибка: Отсутствуют $MISSING_FILES файлов${NC}"
    echo -e "${YELLOW}Пожалуйста, создайте все файлы перед запуском${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓ Все файлы на месте${NC}"
echo ""

# Меню выбора
echo -e "${BLUE}Выберите действие:${NC}"
echo ""
echo "  1) Быстрый тест (30 секунд)"
echo "  2) Полный тест (все тесты последовательно)"
echo "  3) Только K6 тест"
echo "  4) Только Vegeta тест"
echo "  5) Только Locust тест"
echo "  6) Запустить мониторинг"
echo "  7) Запустить все параллельно (тесты + мониторинг)"
echo "  8) Проверить статус сервера"
echo "  9) Выход"
echo ""
read -p "Ваш выбор (1-9): " choice

case $choice in
    1)
        echo -e "\n${YELLOW}Запуск быстрого теста...${NC}"
        cd k6-tests
        k6 run --vus 50 --duration 30s load-test-script.js
        ;;
    2)
        echo -e "\n${YELLOW}Запуск полного теста...${NC}"
        cd scripts
        ./run-all-tests.sh
        ;;
    3)
        echo -e "\n${YELLOW}Запуск K6 теста...${NC}"
        cd k6-tests
        k6 run load-test-script.js
        ;;
    4)
        echo -e "\n${YELLOW}Запуск Vegeta теста...${NC}"
        cd vegeta-tests
        ./vegeta-test.sh
        ;;
    5)
        echo -e "\n${YELLOW}Запуск Locust теста...${NC}"
        cd locust-tests
        locust -f locustfile.py --host=http://localhost:8080
        ;;
    6)
        echo -e "\n${YELLOW}Запуск мониторинга...${NC}"
        cd scripts
        ./monitor.sh
        ;;
    7)
        echo -e "\n${YELLOW}Запуск всех тестов с мониторингом...${NC}"
        # Запуск мониторинга в фоне
        cd scripts
        ./monitor.sh &
        MONITOR_PID=$!
        # Запуск тестов
        ./run-all-tests.sh
        # Остановка мониторинга
        kill $MONITOR_PID
        ;;
    8)
        echo -e "\n${YELLOW}Проверка статуса сервера...${NC}"
        curl -s http://localhost:8080/actuator/health || echo "Сервер не отвечает"
        ;;
    9)
        echo -e "\n${GREEN}До свидания!${NC}"
        exit 0
        ;;
    *)
        echo -e "\n${RED}Неверный выбор${NC}"
        ;;
esac
