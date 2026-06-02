// load-test-script.js - K6 нагрузочный тест
// РАСПОЛОЖЕНИЕ: ~/load-tests/k6-tests/load-test-script.js
// ЗАПУСК: k6 run load-test-script.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';

// КОНФИГУРАЦИЯ - ИЗМЕНИТЕ ПОД ВАШ СЕРВЕР
const BASE_URL = 'http://localhost:8080';  // Адрес вашего backend

// Метрики
const feedDuration = new Trend('feed_duration');
const loginDuration = new Trend('login_duration');
const errorRate = new Rate('error_rate');
const requestsTotal = new Counter('requests_total');

// Тестовые пользователи (должны существовать в системе)
const testUsers = [
  { email: 'test1@example.com', password: 'Test123!' },
  { email: 'test2@example.com', password: 'Test123!' },
  { email: 'test3@example.com', password: 'Test123!' },
];

// Конфигурация нагрузки
export const options = {
  stages: [
    { duration: '30s', target: 50 },    // Разогрев до 50 пользователей
    { duration: '1m', target: 200 },    // Увеличение до 200
    { duration: '2m', target: 500 },    // Пиковая нагрузка 500
    { duration: '30s', target: 0 },     // Снижение до 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],  // 95% запросов быстрее 2 сек
    http_req_failed: ['rate<0.05'],     // Менее 5% ошибок
  },
};

// Функция авторизации
function authenticate() {
  const user = testUsers[Math.floor(Math.random() * testUsers.length)];
  const payload = JSON.stringify({
    email: user.email,
    password: user.password,
  });
  
  const start = new Date();
  const response = http.post(`${BASE_URL}/api/v1/auth/login`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });
  loginDuration.add(new Date() - start);
  
  if (response.status === 200) {
    const body = JSON.parse(response.body);
    return body.token;
  }
  return null;
}

// Функция получения ленты
function getFeed(token) {
  const start = new Date();
  const response = http.get(`${BASE_URL}/api/v1/feed?limit=20`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  feedDuration.add(new Date() - start);
  requestsTotal.add(1);
  
  check(response, {
    'feed status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  return response;
}

// Главная функция теста
export default function () {
  const token = authenticate();
  if (token) {
    getFeed(token);
  }
  sleep(1);  // Пауза между запросами
}

// Функция настройки (выполняется один раз перед тестом)
export function setup() {
  console.log(`Starting load test at ${new Date().toISOString()}`);
  console.log(`Target: ${BASE_URL}`);
  return { startTime: Date.now() };
}

// Функция очистки (выполняется после теста)
export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`Test completed in ${duration} seconds`);
}
