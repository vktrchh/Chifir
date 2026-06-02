#!/bin/bash
# vegeta-test.sh - Тестирование с Vegeta
# РАСПОЛОЖЕНИЕ: ~/load-tests/vegeta-tests/vegeta-test.sh
# ЗАПУСК: chmod +x vegeta-test.sh && ./vegeta-test.sh

BASE_URL="http://localhost:8080"
RESULTS_DIR="../results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "=== VEGETA НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ ==="

# Создание файла с эндпоинтами
cat > targets.txt << EOF
GET ${BASE_URL}/api/v1/feed
GET ${BASE_URL}/api/v1/users/1
GET ${BASE_URL}/api/v1/tags/java/posts
POST ${BASE_URL}/api/v1/auth/login
@login-payload.json
