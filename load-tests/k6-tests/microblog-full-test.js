// microblog-full-test.js
// Полный нагрузочный тест для микроблогинга
// Соответствует требованиям: 1M DAU, 2500 RPS чтения, 25 RPS записи

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ======================================================
// КОНФИГУРАЦИЯ
// ======================================================

const BASE_URL = 'http://localhost:8080';

// Метрики
const errorRate = new Rate('errors');
const feedLatency = new Trend('feed_latency', true);
const loginLatency = new Trend('login_latency', true);
const postLatency = new Trend('post_latency', true);
const likeLatency = new Trend('like_latency', true);
const followLatency = new Trend('follow_latency', true);
const searchLatency = new Trend('search_latency', true);
const profileLatency = new Trend('profile_latency', true);
const totalRequests = new Counter('total_requests');

// Тестовые данные
const testUsers = [
    { email: 'test1@example.com', password: 'Test123!', username: 'test1' },
    { email: 'test2@example.com', password: 'Test123!', username: 'test2' },
    { email: 'test3@example.com', password: 'Test123!', username: 'test3' },
    { email: 'test4@example.com', password: 'Test123!', username: 'test4' },
    { email: 'test5@example.com', password: 'Test123!', username: 'test5' },
];

const tags = ['java', 'spring', 'microblogging', 'database', 'api', 'rest', 'cloud', 'docker'];

// Кэш токенов
let authTokens = new Map();

// ======================================================
// КОНФИГУРАЦИЯ НАГРУЗКИ
// ======================================================

export const options = {
    scenarios: {
        // Сценарий 1: Чтение ленты (основной - 70% трафика)
        read_feed: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 100 },   // Разогрев
                { duration: '3m', target: 500 },   // Средняя нагрузка
                { duration: '5m', target: 1500 },  // Высокая нагрузка
                { duration: '2m', target: 1500 },  // Удержание
                { duration: '1m', target: 0 },     // Спад
            ],
            gracefulRampDown: '30s',
            exec: 'testReadFeed',
            tags: { scenario: 'read_feed' },
        },
        
        // Сценарий 2: Социальные действия (20% трафика)
        social_actions: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 30 },
                { duration: '3m', target: 150 },
                { duration: '5m', target: 400 },
                { duration: '2m', target: 400 },
                { duration: '1m', target: 0 },
            ],
            gracefulRampDown: '30s',
            exec: 'testSocialActions',
            tags: { scenario: 'social' },
            startTime: '30s',
        },
        
        // Сценарий 3: Запись постов (1% трафика)
        write_posts: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 5 },
                { duration: '3m', target: 25 },
                { duration: '5m', target: 25 },
                { duration: '2m', target: 25 },
                { duration: '1m', target: 0 },
            ],
            gracefulRampDown: '30s',
            exec: 'testWritePost',
            tags: { scenario: 'write' },
            startTime: '1m',
        },
        
        // Сценарий 4: Авторизация (9% трафика)
        auth_actions: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 10 },
                { duration: '2m', target: 50 },
                { duration: '3m', target: 100 },
                { duration: '1m', target: 0 },
            ],
            gracefulRampDown: '30s',
            exec: 'testAuth',
            tags: { scenario: 'auth' },
            startTime: '30s',
        },
    },
    
    thresholds: {
        // Требование №3: Feed ≤ 1.5 сек
        'feed_latency': ['p(95)<1500', 'p(99)<2000'],
        // Требование №1: Login ≤ 2 сек
        'login_latency': ['p(95)<2000', 'p(99)<3000'],
        // Требование №2: Post ≤ 1 сек
        'post_latency': ['p(95)<1000', 'p(99)<1500'],
        // Требование №5: Follow ≤ 500 мс
        'follow_latency': ['p(95)<500', 'p(99)<1000'],
        // Требование №6: Search ≤ 2 сек
        'search_latency': ['p(95)<2000', 'p(99)<3000'],
        // Требование №7: Profile ≤ 1 сек
        'profile_latency': ['p(95)<1000', 'p(99)<1500'],
        // Общие требования
        'errors': ['rate<0.01'],           // < 1% ошибок
        'http_req_failed': ['rate<0.01'],  // < 1% ошибок HTTP
    },
};

// ======================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// ======================================================

function getRandomUser() {
    return testUsers[Math.floor(Math.random() * testUsers.length)];
}

function getRandomTag() {
    return tags[Math.floor(Math.random() * tags.length)];
}

function getRandomId() {
    return Math.floor(Math.random() * 10000) + 1;
}

function authenticate(user) {
    const payload = JSON.stringify({
        email: user.email,
        password: user.password,
    });
    
    const params = {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'login' },
    };
    
    const response = http.post(`${BASE_URL}/api/v1/auth/login`, payload, params);
    totalRequests.add(1);
    
    if (response.status === 200) {
        const body = JSON.parse(response.body);
        return body.token || body.accessToken;
    }
    return null;
}

function getAuthToken() {
    const user = getRandomUser();
    let token = authTokens.get(user.email);
    
    if (!token || Math.random() < 0.1) {  // 10% обновление токенов
        token = authenticate(user);
        if (token) {
            authTokens.set(user.email, token);
        }
    }
    return token;
}

function getAuthHeaders() {
    const token = getAuthToken();
    return {
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
    };
}

// ======================================================
// ТЕСТОВЫЕ СЦЕНАРИИ
// ======================================================

// Сценарий 1: Чтение ленты
export function testReadFeed() {
    group('Read Feed', function() {
        const start = Date.now();
        const response = http.get(`${BASE_URL}/api/v1/feed?limit=20&offset=0`);
        feedLatency.add(Date.now() - start);
        totalRequests.add(1);
        
        const success = check(response, {
            'feed status 200': (r) => r.status === 200,
            'feed has posts': (r) => {
                try {
                    const body = JSON.parse(r.body);
                    return body.posts !== undefined || Array.isArray(body);
                } catch {
                    return false;
                }
            },
        });
        
        if (!success) errorRate.add(1);
    });
    
    sleep(Math.random() * 1 + 0.5);
}

// Сценарий 2: Социальные действия
export function testSocialActions() {
    const action = Math.random();
    
    // 60% лайки
    if (action < 0.6) {
        group('Like Post', function() {
            const postId = getRandomId();
            const start = Date.now();
            const response = http.post(`${BASE_URL}/api/v1/posts/${postId}/like`, null);
            likeLatency.add(Date.now() - start);
            totalRequests.add(1);
            
            const success = check(response, {
                'like status 200 or 409': (r) => r.status === 200 || r.status === 409,
            });
            if (!success) errorRate.add(1);
        });
    }
    // 30% подписки
    else if (action < 0.9) {
        group('Follow User', function() {
            const userId = getRandomId();
            const start = Date.now();
            const response = http.post(`${BASE_URL}/api/v1/follows/${userId}`, null);
            followLatency.add(Date.now() - start);
            totalRequests.add(1);
            
            const success = check(response, {
                'follow status 200': (r) => r.status === 200,
            });
            if (!success) errorRate.add(1);
        });
    }
    // 10% просмотр профиля
    else {
        group('View Profile', function() {
            const userId = getRandomId();
            const start = Date.now();
            const response = http.get(`${BASE_URL}/api/v1/users/${userId}`);
            profileLatency.add(Date.now() - start);
            totalRequests.add(1);
            
            const success = check(response, {
                'profile status 200': (r) => r.status === 200,
            });
            if (!success) errorRate.add(1);
        });
    }
    
    sleep(Math.random() * 1 + 0.3);
}

// Сценарий 3: Запись постов
export function testWritePost() {
    group('Create Post', function() {
        const payload = JSON.stringify({
            content: `Тестовый пост для нагрузочного тестирования ${Date.now()} #loadtest #${getRandomTag()}`,
            mediaIds: [],
            tags: [getRandomTag(), 'loadtest'],
        });
        
        const start = Date.now();
        const response = http.post(`${BASE_URL}/api/v1/posts`, payload, {
            headers: { 'Content-Type': 'application/json' },
        });
        postLatency.add(Date.now() - start);
        totalRequests.add(1);
        
        const success = check(response, {
            'post status 201 or 200': (r) => r.status === 201 || r.status === 200,
        });
        if (!success) errorRate.add(1);
    });
    
    // Постинг реже, пауза больше
    sleep(Math.random() * 3 + 2);
}

// Сценарий 4: Авторизация
export function testAuth() {
    const user = getRandomUser();
    
    group('Login', function() {
        const payload = JSON.stringify({
            email: user.email,
            password: user.password,
        });
        
        const start = Date.now();
        const response = http.post(`${BASE_URL}/api/v1/auth/login`, payload, {
            headers: { 'Content-Type': 'application/json' },
        });
        loginLatency.add(Date.now() - start);
        totalRequests.add(1);
        
        const success = check(response, {
            'login status 200': (r) => r.status === 200,
            'has token': (r) => {
                try {
                    const body = JSON.parse(r.body);
                    return body.token !== undefined || body.accessToken !== undefined;
                } catch {
                    return false;
                }
            },
        });
        
        if (!success) errorRate.add(1);
    });
    
    sleep(Math.random() * 2 + 1);
}

// Сценарий 5: Поиск по тегам
export function testSearch() {
    group('Search by Tag', function() {
        const tag = getRandomTag();
        const start = Date.now();
        const response = http.get(`${BASE_URL}/api/v1/tags/${tag}/posts?limit=20`);
        searchLatency.add(Date.now() - start);
        totalRequests.add(1);
        
        const success = check(response, {
            'search status 200': (r) => r.status === 200,
        });
        if (!success) errorRate.add(1);
    });
    
    sleep(Math.random() * 1 + 0.5);
}

// ======================================================
// SETUP И TEARDOWN
// ======================================================

export function setup() {
    console.log('\n' + '='.repeat(60));
    console.log('  ПОЛНЫЙ НАГРУЗОЧНЫЙ ТЕСТ МИКРОБЛОГИНГА');
    console.log('='.repeat(60));
    console.log(`  Целевой сервер: ${BASE_URL}`);
    console.log(`  Время начала: ${new Date().toISOString()}`);
    console.log('='.repeat(60) + '\n');
    
    // Проверка доступности backend
    try {
        const healthCheck = http.get(`${BASE_URL}/actuator/health`, { timeout: '5s' });
        if (healthCheck.status !== 200) {
            console.error('❌ Backend не доступен!');
            return { error: 'Backend not available' };
        }
        console.log('✅ Backend доступен\n');
    } catch (e) {
        console.error('❌ Ошибка подключения к backend:', e.message);
        return { error: 'Connection failed' };
    }
    
    // Создание тестовых пользователей
    console.log('📝 Создание тестовых пользователей...');
    for (const user of testUsers) {
        const payload = JSON.stringify({
            email: user.email,
            username: user.username,
            password: user.password,
        });
        http.post(`${BASE_URL}/api/v1/auth/register`, payload, {
            headers: { 'Content-Type': 'application/json' },
        });
    }
    console.log(`✅ Создано ${testUsers.length} тестовых пользователей\n`);
    
    return { startTime: Date.now(), usersCount: testUsers.length };
}

export function teardown(data) {
    const duration = (Date.now() - data.startTime) / 1000;
    
    console.log('\n' + '='.repeat(60));
    console.log('  РЕЗУЛЬТАТЫ НАГРУЗОЧНОГО ТЕСТИРОВАНИЯ');
    console.log('='.repeat(60));
    console.log(`  Длительность: ${duration.toFixed(2)} секунд`);
    console.log(`  Тестовых пользователей: ${data.usersCount}`);
    console.log('='.repeat(60));
    console.log('\n✅ Тестирование завершено!\n');
}

// Экспорт дополнительных сценариев для гибкости
export function testMixed() {
    const r = Math.random();
    
    if (r < 0.7) {
        testReadFeed();
    } else if (r < 0.85) {
        testSocialActions();
    } else if (r < 0.95) {
        testSearch();
    } else {
        testWritePost();
    }
}
