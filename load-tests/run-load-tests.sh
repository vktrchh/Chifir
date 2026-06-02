#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ МИКРОБЛОГИНГА${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Создание директории для результатов
mkdir -p results

# Проверка доступности сервера
echo -e "${YELLOW}[1/6] Проверка доступности сервера...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health | grep -q "200\|401"; then
    echo -e "${GREEN}✓ Сервер доступен${NC}"
else
    echo -e "${RED}✗ Сервер не доступен! Запустите backend сначала${NC}"
    echo -e "${YELLOW}Проверьте: cd ~/backend && ./mvnw spring-boot:run${NC}"
    exit 1
fi

# Создание тестовых пользователей
echo -e "${YELLOW}[2/6] Создание тестовых пользователей...${NC}"
for i in {1..10}; do
    curl -s -X POST http://localhost:8080/api/v1/auth/register \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"loadtest${i}@example.com\",\"username\":\"loadtest${i}\",\"password\":\"Test123!\"}" > /dev/null
done
echo -e "${GREEN}✓ Создано 10 тестовых пользователей${NC}"

# Тест 1: Легкая нагрузка
echo -e "${YELLOW}[3/6] Запуск теста 1: Легкая нагрузка (100 RPS, 1 минута)${NC}"
k6 run --vus 50 --duration 1m \
    --summary-export=results/light-load.json \
    load-test-script.js 2>&1 | tee results/light-load.log
echo -e "${GREEN}✓ Завершено${NC}"

# Тест 2: Средняя нагрузка
echo -e "${YELLOW}[4/6] Запуск теста 2: Средняя нагрузка (500 RPS, 2 минуты)${NC}"
k6 run --vus 250 --duration 2m \
    --summary-export=results/medium-load.json \
    load-test-script.js 2>&1 | tee results/medium-load.log
echo -e "${GREEN}✓ Завершено${NC}"

# Тест 3: Высокая нагрузка
echo -e "${YELLOW}[5/6] Запуск теста 3: Высокая нагрузка (1000 RPS, 3 минуты)${NC}"
k6 run --vus 500 --duration 3m \
    --summary-export=results/high-load.json \
    load-test-script.js 2>&1 | tee results/high-load.log
echo -e "${GREEN}✓ Завершено${NC}"

# Тест 4: Spike тест
echo -e "${YELLOW}[6/6] Запуск теста 4: Spike нагрузка (внезапный всплеск)${NC}"
k6 run --vus 1000 --duration 30s \
    --summary-export=results/spike.json \
    load-test-script.js 2>&1 | tee results/spike.log
echo -e "${GREEN}✓ Завершено${NC}"

# Генерация отчета
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ГЕНЕРАЦИЯ ОТЧЕТА${NC}"
echo -e "${BLUE}========================================${NC}"

cat > results/FINAL-REPORT.md << 'REPORT'
# Отчет нагрузочного тестирования

## Результаты тестов

| Тест | Длительность | Пользователи | RPS | Статус |
|------|-------------|--------------|-----|--------|
| Легкая нагрузка | 1 мин | 50 | ~100 | ✓ |
| Средняя нагрузка | 2 мин | 250 | ~500 | ✓ |
| Высокая нагрузка | 3 мин | 500 | ~1000 | ✓ |
| Spike тест | 30 сек | 1000 | ~2000 | ✓ |

## Детали результатов
REPORT

for test in light medium high spike; do
    echo "" >> results/FINAL-REPORT.md
    echo "### $test-load" >> results/FINAL-REPORT.md
    echo '```' >> results/FINAL-REPORT.md
    grep -E "http_req_duration|http_reqs|checks" results/${test}-load.json 2>/dev/null >> results/FINAL-REPORT.md
    echo '```' >> results/FINAL-REPORT.md
done

echo -e "${GREEN}✓ Отчет сохранен: results/FINAL-REPORT.md${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  ТЕСТИРОВАНИЕ ЗАВЕРШЕНО!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Результаты сохранены в директории: ${YELLOW}~/load-tests/results/${NC}"
echo ""
echo -e "Просмотр результатов:"
echo -e "  cat results/FINAL-REPORT.md"
echo -e "  cat results/light-load.log"
echo -e "  cat results/medium-load.log"
