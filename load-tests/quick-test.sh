#!/bin/bash

echo "=== БЫСТРЫЙ ТЕСТ (30 секунд) ==="
echo "Тестирование GET /api/v1/feed"

# Простой тест с curl
echo ""
echo "Результаты теста:"

# Замер времени 10 запросов
total=0
for i in {1..10}; do
    start=$(date +%s%N)
    curl -s -o /dev/null http://localhost:8080/api/v1/feed
    end=$(date +%s%N)
    duration=$((($end - $start)/1000000))
    echo "Запрос $i: ${duration}ms"
    total=$((total + duration))
done

avg=$((total / 10))
echo ""
echo "Среднее время ответа: ${avg}ms"

if [ $avg -lt 1500 ]; then
    echo "✓ Результат: ХОРОШО (< 1500ms)"
else
    echo "✗ Результат: МЕДЛЕННО (> 1500ms)"
fi
