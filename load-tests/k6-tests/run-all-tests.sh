#!/bin/bash

echo "=========================================="
echo "  ЗАПУСК ВСЕХ ТЕСТОВ"
echo "=========================================="

# Тест 1: Легкая нагрузка
echo ""
echo "[1/5] Легкая нагрузка (50 VUs, 2 мин)"
k6 run --vus 50 --duration 2m microblog-full-test.js

# Тест 2: Средняя нагрузка
echo ""
echo "[2/5] Средняя нагрузка (200 VUs, 3 мин)"
k6 run --vus 200 --duration 3m microblog-full-test.js

# Тест 3: Высокая нагрузка
echo ""
echo "[3/5] Высокая нагрузка (500 VUs, 5 мин)"
k6 run --vus 500 --duration 5m microblog-full-test.js

# Тест 4: Очень высокая нагрузка
echo ""
echo "[4/5] Очень высокая нагрузка (1000 VUs, 5 мин)"
k6 run --vus 1000 --duration 5m microblog-full-test.js

# Тест 5: Spike тест
echo ""
echo "[5/5] Spike тест (внезапная нагрузка)"
k6 run --vus 2000 --duration 30s microblog-full-test.js

echo ""
echo "=========================================="
echo "  ВСЕ ТЕСТЫ ЗАВЕРШЕНЫ"
echo "=========================================="
