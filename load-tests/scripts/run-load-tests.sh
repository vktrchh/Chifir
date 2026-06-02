#!/bin/bash
# run-load-tests.sh - Главный скрипт запуска всех тестов
# РАСПОЛОЖЕНИЕ: ~/load-tests/scripts/run-load-tests.sh
# ЗАПУСК: chmod +x run-load-tests.sh && ./run-load-tests.sh

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Конфигурация
BASE_URL="http://localhost:8080"
RESULTS_DIR="../results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ МИКРОБЛОГИНГА${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Время начала: ${TIMESTAMP}"
echo -e "Целевой сервер: ${BASE_URL}"
echo ""

# Создание директории для результатов
mkdir -p ${RESULTS_DIR}

# Проверка доступности сервера
echo -e "${YELLOW}[1/8] Проверка доступности сервера...${NC}"
if curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/actuator/health | grep -q "200\|401"; then
    echo -e "${GREEN}✓ Сервер доступен${NC}"
else
    echo -e "${RED}✗ Сервер не доступен!${NC}"
    echo -e "${YELLOW}Пожалуйста, запустите backend:${NC}"
    echo "  cd ~/microblog-backend && ./mvnw spring-boot:run"
    exit 1
fi

# Создание тестовых пользователей
echo -e "${YELLOW}[2/8] Создание тестовых пользователей...${NC}"
for i in {1..10}; do
    curl -s -X POST ${BASE_URL}/api/v1/auth/register \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"loadtest${i}@example.com\",\"username\":\"loadtest${i}\",\"password\":\"Test123!\"}" > /dev/null
done
echo -e "${GREEN}✓ Создано 10 тестовых пользователей${NC}"

# Тест 1: Легкая нагрузка (K6)
echo -e "${YELLOW}[3/8] Запуск K6 теста: Легкая нагрузка...${NC}"
cd ../k6-tests
k6 run --vus 50 --duration 1m \
    --summary-export=${RESULTS_DIR}/k6-light-${TIMESTAMP}.json \
    load-test-script.js > ${RESULTS_DIR}/k6-light-${TIMESTAMP}.log 2>&1
echo -e "${GREEN}✓ Завершено (результат: ${RESULTS_DIR}/k6-light-${TIMESTAMP}.log)${NC}"

# Тест 2: Средняя нагрузка (K6)
echo -e "${YELLOW}[4/8] Запуск K6 теста: Средняя нагрузка...${NC}"
k6 run --vus 250 --duration 2m \
    --summary-export=${RESULTS_DIR}/k6-medium-${TIMESTAMP}.json \
    load-test-script.js > ${RESULTS_DIR}/k6-medium-${TIMESTAMP}.log 2>&1
echo -e "${GREEN}✓ Завершено${NC}"

# Тест 3: Высокая нагрузка (K6)
echo -e "${YELLOW}[5/8] Запуск K6 теста: Высокая нагрузка...${NC}"
k6 run --vus 500 --duration 3m \
    --summary-export=${RESULTS_DIR}/k6-high-${TIMESTAMP}.json \
    load-test-script.js > ${RESULTS_DIR}/k6-high-${TIMESTAMP}.log 2>&1
echo -e "${GREEN}✓ Завершено${NC}"

# Тест 4: Vegeta тест
echo -e "${YELLOW}[6/8] Запуск Vegeta теста...${NC}"
cd ../vegeta-tests
cat > endpoints.txt << 'ENDPOINTS'
GET http://localhost:8080/api/v1/feed
ENDPOINTS
vegeta attack -rate=500 -duration=30s -targets=endpoints.txt \
    > ${RESULTS_DIR}/vegeta-${TIMESTAMP}.bin 2>&1
vegeta report ${RESULTS_DIR}/vegeta-${TIMESTAMP}.bin \
    > ${RESULTS_DIR}/vegeta-${TIMESTAMP}.txt
echo -e "${GREEN}✓ Завершено${NC}"

# Генерация отчета
echo -e "${YELLOW}[7/8] Генерация финального отчета...${NC}"
cat > ${RESULTS_DIR}/FINAL-REPORT-${TIMESTAMP}.md << REPORTMARKER
# Отчет нагрузочного тестирования

**Дата:** ${TIMESTAMP}
**Целевой сервер:** ${BASE_URL}

## Результаты тестов

### K6 - Легкая нагрузка (50 VUs, 1 минута)
\`\`\`
$(tail -20 ${RESULTS_DIR}/k6-light-${TIMESTAMP}.log | grep -E "http_req|checks|errors" || echo "Данные не найдены")
\`\`\`

### K6 - Средняя нагрузка (250 VUs, 2 минуты)
\`\`\`
$(tail -20 ${RESULTS_DIR}/k6-medium-${TIMESTAMP}.log | grep -E "http_req|checks|errors" || echo "Данные не найдены")
\`\`\`

### K6 - Высокая нагрузка (500 VUs, 3 минуты)
\`\`\`
$(tail -20 ${RESULTS_DIR}/k6-high-${TIMESTAMP}.log | grep -E "http_req|checks|errors" || echo "Данные не найдены")
\`\`\`

### Vegeta тест
\`\`\`
$(cat ${RESULTS_DIR}/vegeta-${TIMESTAMP}.txt 2>/dev/null || echo "Данные не найдены")
\`\`\`

## Заключение
Тестирование завершено. Детальные логи сохранены в директории ${RESULTS_DIR}
REPORTMARKER

echo -e "${GREEN}✓ Отчет создан: ${RESULTS_DIR}/FINAL-REPORT-${TIMESTAMP}.md${NC}"

# Завершение
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  ТЕСТИРОВАНИЕ ЗАВЕРШЕНО!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Результаты сохранены в: ${YELLOW}${RESULTS_DIR}${NC}"
echo ""
echo -e "Просмотр отчета:"
echo -e "  cat ${RESULTS_DIR}/FINAL-REPORT-${TIMESTAMP}.md"
echo ""
echo -e "Просмотр логов:"
echo -e "  ls -la ${RESULTS_DIR}/"
