#!/bin/bash
# run-load-test.sh - Запуск полного нагрузочного тестирования

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ МИКРОБЛОГИНГА (1M DAU)         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Отключение прокси
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
echo -e "${YELLOW}🔧 Прокси отключены${NC}"

# Получение Windows IP
WIN_IP=$(cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}')
if [ -z "$WIN_IP" ]; then
    WIN_IP="172.18.0.1"
fi
echo -e "${YELLOW}📡 Windows IP: ${WIN_IP}${NC}"

# Проверка backend
echo -n "🔍 Проверка backend... "
if curl -s -o /dev/null -w "%{http_code}" http://${WIN_IP}:8080/actuator/health | grep -q "200"; then
    echo -e "${GREEN}✅ РАБОТАЕТ${NC}"
else
    echo -e "${RED}❌ НЕ РАБОТАЕТ${NC}"
    echo ""
    echo -e "${YELLOW}Запустите backend в другом окне:${NC}"
    echo "  cd ~/test-backend"
    echo "  python3 mock_server_fast.py"
    exit 1
fi

# Создание директории для результатов
mkdir -p results

# Выбор типа теста
echo ""
echo -e "${BLUE}Выберите тип теста:${NC}"
echo "  1) Полный тест (соответствует требованиям - 15 минут)"
echo "  2) Быстрый тест (проверка - 2 минуты)"
echo "  3) Только чтение ленты (feed)"
echo "  4) Spike тест (лайки 10,000/сек)"
echo "  5) Смешанный тест (все сценарии)"
echo "  6) Выход"
echo ""
read -p "Ваш выбор (1-6): " choice

case $choice in
    1)
        echo -e "${GREEN}🚀 Запуск ПОЛНОГО теста...${NC}"
        k6 run --out json=results/full-test-$(date +%Y%m%d-%H%M%S).json \
            -e WIN_IP=${WIN_IP} \
            final-load-test.js
        ;;
    2)
        echo -e "${GREEN}🚀 Запуск БЫСТРОГО теста...${NC}"
        k6 run --vus 100 --duration 2m \
            -e WIN_IP=${WIN_IP} \
            final-load-test.js
        ;;
    3)
        echo -e "${GREEN}🚀 Запуск теста ЧТЕНИЯ ЛЕНТЫ...${NC}"
        k6 run --vus 500 --duration 5m \
            -e WIN_IP=${WIN_IP} \
            --exec readFeedScenario \
            final-load-test.js
        ;;
    4)
        echo -e "${GREEN}🚀 Запуск SPIKE теста (10,000 лайков/сек)...${NC}"
        k6 run --vus 2000 --duration 30s \
            -e WIN_IP=${WIN_IP} \
            --exec spikeScenario \
            final-load-test.js
        ;;
    5)
        echo -e "${GREEN}🚀 Запуск СМЕШАННОГО теста...${NC}"
        k6 run --vus 500 --duration 5m \
            -e WIN_IP=${WIN_IP} \
            final-load-test.js
        ;;
    6)
        echo -e "${YELLOW}До свидания!${NC}"
        exit 0
        ;;
esac

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Тестирование завершено!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Результаты сохранены в: ${YELLOW}results/${NC}"
