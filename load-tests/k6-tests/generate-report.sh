#!/bin/bash

echo "========================================"
echo "  ГЕНЕРАЦИЯ ОТЧЕТА ТЕСТИРОВАНИЯ"
echo "========================================"
echo ""

# Запуск теста с сохранением результатов
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_FILE="results/full-test-${TIMESTAMP}.json"

echo "Запуск теста..."
k6 run --out json=${RESULTS_FILE} microblog-full-test.js 2>&1 | tee results/test-output-${TIMESTAMP}.log

echo ""
echo "========================================"
echo "  ОТЧЕТ ГОТОВ"
echo "========================================"
echo "Результаты сохранены в:"
echo "  - ${RESULTS_FILE}"
echo "  - results/test-output-${TIMESTAMP}.log"
echo ""

# Краткий анализ
echo "Краткий анализ:"
grep -E "✓|✗|http_req_duration|checks" results/test-output-${TIMESTAMP}.log | tail -20
