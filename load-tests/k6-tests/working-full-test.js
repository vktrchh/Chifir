import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = 'http://localhost:8080';

export const options = {
    // УМЕНЬШЕННАЯ нагрузка для Python backend
    stages: [
        { duration: '30s', target: 20 },   // Медленный старт
        { duration: '1m', target: 50 },    // Средняя нагрузка
        { duration: '2m', target: 100 },   // Максимум 100 пользователей
        { duration: '1m', target: 0 },     // Спад
    ],
    thresholds: {
        http_req_duration: ['p(95)<2000'],  // 95% запросов < 2 сек
        http_req_failed: ['rate<0.05'],     // < 5% ошибок
    },
};

// Функция для теста ленты
export function testFeed() {
    const response = http.get(`${BASE_URL}/api/v1/feed?limit=20`);
    check(response, {
        'feed status 200': (r) => r.status === 200,
    });
    sleep(1);
}

// Функция для теста авторизации
export function testLogin() {
    const payload = JSON.stringify({
        email: 'test@example.com',
        password: 'Test123!',
    });
    
    const response = http.post(`${BASE_URL}/api/v1/auth/login`, payload, {
        headers: { 'Content-Type': 'application/json' },
    });
    
    check(response, {
        'login status 200': (r) => r.status === 200,
    });
    sleep(2);
}

// Функция для теста создания поста
export function testCreatePost() {
    const payload = JSON.stringify({
        content: `Тестовый пост ${Date.now()}`,
        mediaIds: [],
    });
    
    const response = http.post(`${BASE_URL}/api/v1/posts`, payload, {
        headers: { 'Content-Type': 'application/json' },
    });
    
    check(response, {
        'post status 201': (r) => r.status === 201,
    });
    sleep(3);
}

// Главная функция - 80% чтение, 20% запись
export default function () {
    const r = Math.random();
    
    if (r < 0.8) {
        testFeed();           // 80% - чтение ленты
    } else if (r < 0.95) {
        testLogin();          // 15% - авторизация
    } else {
        testCreatePost();     // 5% - создание поста
    }
}
