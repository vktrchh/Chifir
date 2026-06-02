#!/bin/bash

echo "=== ТЕСТИРОВАНИЕ С VEGETA ==="

# Создание файла с эндпоинтами
cat > endpoints.txt << 'ENDPOINTS'
GET http://localhost:8080/api/v1/feed
GET http://localhost:8080/api/v1/users/1
GET http://localhost:8080/api/v1/tags/java/posts
ENDPOINTS

# Запуск Vegeta теста
echo "Запуск 500 RPS в течение 30 секунд..."
vegeta attack -rate=500 -duration=30s -targets=endpoints.txt | vegeta report > vegeta-results.txt

# Вывод результатов
echo ""
echo "=== РЕЗУЛЬТАТЫ VEGETA ==="
cat vegeta-results.txt

# Генерация графика (требуется установка plotutils)
if command -v vegeta plot &> /dev/null; then
    vegeta attack -rate=500 -duration=30s -targets=endpoints.txt | vegeta plot > plot.html
    echo "График сохранен: plot.html"
fi
