#!/bin/bash
# run-all-tests.sh - Запуск всех типов тестов
# РАСПОЛОЖЕНИЕ: ~/load-tests/scripts/run-all-tests.sh
# ЗАПУСК: chmod +x run-all-tests.sh && ./run-all-tests.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RESULTS_DIR="../results/all-tests-$(date +"%Y%m%d_%H%M%S")"
mkdir -p ${RESULTS_DIR}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ЗАПУСК ВСЕХ НАГРУЗОЧНЫХ ТЕСТОВ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Результаты будут сохранены в: ${YELLOW}${RESULTS_DIR}${NC}"
echo ""

# Функция для сохранения результатов
save_result() {
    local test_name=$1
    local output=$2
    echo "$output" > ${RESULTS_DIR}/${test_name}.txt
    echo -e "${GREEN}✓ ${test_name} сохранен${NC}"
}

# 1. K6 тест
echo -e "${YELLOW}[1/5] Запуск K6 теста...${NC}"
cd ../k6-tests
K6_OUTPUT=$(k6 run --vus 100 --duration 30s load-test-script.js 2>&1)
save_result "k6-test" "$K6_OUTPUT"

# 2. Vegeta тест
echo -e "${YELLOW}[2/5] Запуск Vegeta теста...${NC}"
cd ../vegeta-tests
VEGETA_OUTPUT=$(vegeta attack -rate=100 -duration=10s -targets=targets.txt 2>&1 | vegeta report)
save_result "vegeta-test" "$VEGETA_OUTPUT"

# 3. Locust тест (быстрый)
echo -e "${YELLOW}[3/5] Запуск Locust теста...${NC}"
cd ../locust-tests
LOCUST_OUTPUT=$(locust -f locustfile.py --host=http://localhost:8080 --headless -u 50 -r 5 --run-time 30s 2>&1)
save_result "locust-test" "$LOCUST_OUTPUT"

# 4. JMeter тест
echo -e "${YELLOW}[4/5] Запуск JMeter теста...${NC}"
cd ../jmeter-tests
JMETER_OUTPUT=$(jmeter -n -t load-test-plan.jmx -l ${RESULTS_DIR}/jmeter-results.jtl 2>&1)
save_result "jmeter-test" "$JMETER_OUTPUT"

# 5. Сводный отчет
echo -e "${YELLOW}[5/5] Генерация сводного отчета...${NC}"
cat > ${RESULTS_DIR}/SUMMARY.md << EOF
# Сводный отчет нагрузочного тестирования

## Информация
- **Дата:** $(date)
- **Директория результатов:** ${RESULTS_DIR}

## Содержимое
$(ls -la ${RESULTS_DIR})

## Результаты тестов

### K6
\`\`\`
$(head -50 ${RESULTS_DIR}/k6-test.txt)
\`\`\`

### Vegeta
\`\`\`
$(head -30 ${RESULTS_DIR}/vegeta-test.txt)
\`\`\`

### Locust
\`\`\`
$(head -50 ${RESULTS_DIR}/locust-test.txt)
\`\`\`

### JMeter
\`\`\`
$(head -20 ${RESULTS_DIR}/jmeter-test.txt)
\`\`\`
