#!/bin/bash

echo "╔════════════════════════════════════════════════════════╗"
echo "║     ИСПРАВЛЕННЫЙ ЗАПУСК НАГРУЗОЧНОГО ТЕСТИРОВАНИЯ      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Проверка bc
if ! command -v bc &> /dev/null; then
    echo "📦 Установка bc..."
    sudo apt install bc -y
fi

# Проверка backend
echo "🔍 Проверка backend..."
if curl -s http://localhost:8080/actuator/health | grep -q "UP"; then
    echo "✅ Backend работает"
else
    echo "❌ Backend не отвечает!"
    echo "Запустите: cd ~/test-backend && python3 mock_server_fast.py"
    exit 1
fi

echo ""
echo "Выберите тест:"
echo "  1) Щадящий тест (10-20 пользователей)"
echo "  2) Средний тест (20-50 пользователей)"
echo "  3) Быстрая проверка (5 пользователей)"
echo "  4) Выход"
echo ""
read -p "Ваш выбор: " choice

case $choice in
    1)
        echo "🚀 Запуск щадящего теста..."
        cd k6-tests
        k6 run gentle-test.js
        ;;
    2)
        echo "🚀 Запуск среднего теста..."
        cd k6-tests
        k6 run --vus 30 --duration 1m load-test-script.js
        ;;
    3)
        echo "🚀 Быстрая проверка..."
        cd k6-tests
        k6 run --vus 5 --duration 10s load-test-script.js
        ;;
    4)
        echo "До свидания!"
        exit 0
        ;;
esac

echo ""
echo "✅ Тест завершен!"
