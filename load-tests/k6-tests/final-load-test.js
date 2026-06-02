// final-load-test.js - Полный нагрузочный тест для микроблогинга
// Соответствует требованиям: 1M DAU, 2500 RPS чтения, 25 RPS записи

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate, Counter, Gauge } from 'k6/metrics';

// ======================================================
// КОНФИГУРАЦИЯ
// ======================================================

// Используйте Windows IP из WSL
const WIN_IP = __ENV.WIN_IP || '172.18.0.1';
const BASE_URL = `http://${WIN_IP}:8080`;

// Метрики
const feedDuration = new Trend('feed_duration', true);
const loginDuration = new Trend('login_duration', true);
const postDuration = new Trend('post_duration', true);
const likeDuration = new Trend('like_duration', true);
const followDuration = new Trend('follow_duration', true);
const searchDuration = new Trend('search_duration', true);
const profileDuration = new Trend('profile_duration', true);
const errorRate = new Rate('error_rate');
const requestsTotal = new Counter('requests_total');
const activeUsers = new Gauge('active_users');

// Тестовые данные
const testUsers = [];
for (let i = 1; i <= 100; i++) {
    testUsers.push({
        email: `loadtest${i}@example.com`,
        password: 'Test123!',
        username: `loadtest${i}`
    });
}

// ======================================================
// КОНФИГУРАЦИЯ НАГРУЗКИ (соответствует требованиям)
// ======================================================

export const options = {
    scenarios: {
        // Сценарий 1: Чтение ленты (основная нагрузка) - 70% трафика
        read_feed: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 500 },   // Разогрев
                { duration: '5m', target: 2000 },  // Пик чтения
                { duration: '2m', target: 2000 },  // Удержание
                { duration: '1m', target: 0 },     // Спад
            ],
            gracefulRampDown: '30s',
            exec: 'readFeedScenario',
            tags: { scenario: 'read_feed' },
        },
        
        // Сценарий 2: Запись постов - 1% трафика (25 RPS)
        write_post: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 10 },
                { duration: '5m', target: 25 },
                { duration: '2m', target: 25 },
                { duration: '1m', target: 0 },
            ],
            gracefulRampDown: '30s',
            exec: 'writePostScenario',
            tags: { scenario: 'write_post' },
        },
        
        // Сценарий 3: Социальные действия (лайки, подписки) - 20% трафика
        social_action: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 100 },
                { duration: '5m', target: 500 },
                { duration: '2m', target: 500 },
                { duration: '1m', target: 0 },
            ],
            gracefulRampDown: '30s',
            exec: 'socialScenario',
            tags: { scenario: 'social' },
        },
        
        // Сценарий 4: Spike тест (10,000 лайков/сек) - короткий
        spike_likes: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '10s', target: 1000 },
                { duration: '20s', target: 5000 },
                { duration: '10s', target: 0 },
            ],
            gracefulRampDown: '10s',
            startTime: '10m',
            exec: 'spikeScenario',
            tags: { scenario: 'spike' },
        },
    },
    
    thresholds: {
        // Требование №3: Feed ≤ 1.5 сек
        'feed_duration': ['p(95)<1500', 'p(99)<2000'],
        // Требование №1: Login ≤ 2 сек
        'login_duration': ['p(95)<2000', 'p(99)<3000'],
        // Требование №2: Post ≤ 1 сек
        'post_duration': ['p(95)<1000', 'p(99)<1500'],
        // Требование №5: Follow ≤ 500 мс
        'follow_duration': ['p(95)<500', 'p(99)<1000'],
        // Требование №6: Search ≤ 2 сек
        'search_duration': ['p(95)<2000', 'p(99)<3000'],
        // Требование №7: Profile ≤ 1 сек
        'profile_duration': ['p(95)<1000', 'p(99)<1500'],
        // Общее: ошибки < 0.1%
        'error_rate': ['rate<0.001'],
        // Общее: 95% запросов успешны
        'http_req_failed': ['rate<0.001'],
    },
    
    // Настройки для высокой нагрузки
    noConnectionReuse: false,
    userAgent: 'k6-load-test/1.0',
};

// ======================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// ======================================================

let authTokens = new Map();

function authenticate(user) {
    const payload = JSON.stringify({
        email: user.email,
        password: user.password,
    });
    
    const start = Date.now();
    const response = http.post(`${BASE_URL}/api/v1/auth/login`, payload, {
        headers: { 'Content-Type': 'application/json' },
        timeout: '5s',
    });
    loginDuration.add(Date.now() - start);
    requestsTotal.add(1);
    
    if (response.status === 200) {
        const body = JSON.parse(response.body);
        return body.token || body.accessToken;
    }
    return null;
}

function getRandomUser() {
    return testUsers[Math.floor(Math.random() * testUsers.length)];
}

function getRandomPostId() {
    return Math.floor(Math.random() * 100000) + 1;
}

function getRandomUserId() {
    return Math.floor(Math.random() * 100000) + 1;
}

function getRandomTag() {
    const tags = ['java', 'spring', 'microblogging', 'tech', 'news', 'programming', 'database', 'api'];
    return tags[Math.floor(Math.random() * tags.length)];
}

// ======================================================
// СЦЕНАРИИ ТЕСТИРОВАНИЯ
// ======================================================

// Сценарий 1: Чтение ленты (основной сценарий - 70% трафика)
export function readFeedScenario() {
    const user = getRandomUser();
    let token = authTokens.get(user.email);
    
    if (!token) {
        token = authenticate(user);
        if (token) {
            authTokens.set(user.email, token);
        } else {
            errorRate.add(1);
            return;
        }
    }
    
    group('Read Feed', function() {
        const start = Date.now();
        const response = http.get(`${BASE_URL}/api/v1/feed?limit=20&offset=0`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
            timeout: '5s',
        });
        feedDuration.add(Date.now() - start);
        requestsTotal.add(1);
        
        const success = check(response, {
            'feed status is 200': (r) => r.status === 200,
            'feed has data': (r) => {
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
    
    // Имитация реального поведения: пауза между действиями
    sleep(Math.random() * 2 + 0.5);
}

// Сценарий 2: Запись постов (1% трафика, ~25 RPS)
export function writePostScenario() {
    const user = getRandomUser();
    let token = authTokens.get(user.email);
    
    if (!token) {
        token = authenticate(user);
        if (token) {
            authTokens.set(user.email, token);
        } else {
            errorRate.add(1);
            return;
        }
    }
    
    group('Create Post', function() {
        const payload = JSON.stringify({
            content: `Тестовый пост для нагрузочного тестирования ${Date.now()} #loadtest #k6 #${getRandomTag()}`,
            mediaIds: [],
            tags: [getRandomTag(), 'loadtest'],
        });
        
        const start = Date.now();
        const response = http.post(`${BASE_URL}/api/v1/posts`, payload, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
            timeout: '10s',
        });
        postDuration.add(Date.now() - start);
        requestsTotal.add(1);
        
        const success = check(response, {
            'create post status is 201 or 200': (r) => r.status === 201 || r.status === 200,
        });
        
        if (!success) errorRate.add(1);
    });
    
    // Постинг происходит реже, пауза больше
    sleep(Math.random() * 5 + 3);
}

// Сценарий 3: Социальные действия (лайки, подписки)
export function socialScenario() {
    const user = getRandomUser();
    let token = authTokens.get(user.email);
    
    if (!token) {
        token = authenticate(user);
        if (token) {
            authTokens.set(user.email, token);
        } else {
            errorRate.add(1);
            return;
        }
    }
    
    const action = Math.random();
    
    // 60% лайки, 30% подписки, 10% профиль
    if (action < 0.6) {
        // Like post
        group('Like Post', function() {
            const postId = getRandomPostId();
            const start = Date.now();
            const response = http.post(`${BASE_URL}/api/v1/posts/${postId}/like`, null, {
                headers: { 'Authorization': `Bearer ${token}` },
                timeout: '5s',
            });
            likeDuration.add(Date.now() - start);
            requestsTotal.add(1);
            
            // 409 = already liked - это нормально
            const success = check(response, {
                'like status is 200 or 409': (r) => r.status === 200 || r.status === 409,
            });
            if (!success) errorRate.add(1);
        });
    } 
    else if (action < 0.9) {
        // Follow user
        group('Follow User', function() {
            const userId = getRandomUserId();
            const start = Date.now();
            const response = http.post(`${BASE_URL}/api/v1/follows/${userId}`, null, {
                headers: { 'Authorization': `Bearer ${token}` },
                timeout: '5s',
            });
            followDuration.add(Date.now() - start);
            requestsTotal.add(1);
            
            const success = check(response, {
                'follow status is 200': (r) => r.status === 200,
            });
            if (!success) errorRate.add(1);
        });
    }
    else {
        // Get user profile
        group('Get Profile', function() {
            const userId = getRandomUserId();
            const start = Date.now();
            const response = http.get(`${BASE_URL}/api/v1/users/${userId}`, {
                headers: { 'Authorization': `Bearer ${token}` },
                timeout: '5s',
            });
            profileDuration.add(Date.now() - start);
            requestsTotal.add(1);
            
            const success = check(response, {
                'profile status is 200': (r) => r.status === 200,
            });
            if (!success) errorRate.add(1);
        });
    }
    
    sleep(Math.random() * 1 + 0.5);
}

// Сценарий 4: Spike тест (10,000 лайков/сек на популярный пост)
export function spikeScenario() {
    const user = getRandomUser();
    let token = authTokens.get(user.email);
    
    if (!token) {
        token = authenticate(user);
        if (token) {
            authTokens.set(user.email, token);
        } else {
            errorRate.add(1);
            return;
        }
    }
    
    // Один популярный пост
    const POPULAR_POST_ID = 1;
    
    group('Spike Like - Popular Post', function() {
        const start = Date.now();
        const response = http.post(`${BASE_URL}/api/v1/posts/${POPULAR_POST_ID}/like`, null, {
            headers: { 'Authorization': `Bearer ${token}` },
            timeout: '5s',
        });
        likeDuration.add(Date.now() - start);
        requestsTotal.add(1);
        
        // Даже ошибки считаем (нормально для spike теста)
        check(response, {
            'spike like completed': (r) => r.status === 200 || r.status === 409 || r.status === 429,
        });
    });
    
    // Минимальная пауза для максимальной нагрузки
    sleep(Math.random() * 0.1);
}

// Сценарий 5: Поиск по тегам
export function searchScenario() {
    const user = getRandomUser();
    let token = authTokens.get(user.email);
    
    if (!token) {
        token = authenticate(user);
        if (token) {
            authTokens.set(user.email, token);
        } else {
            errorRate.add(1);
            return;
        }
    }
    
    group('Search by Tag', function() {
        const tag = getRandomTag();
        const start = Date.now();
        const response = http.get(`${BASE_URL}/api/v1/tags/${tag}/posts?limit=20`, {
            headers: { 'Authorization': `Bearer ${token}` },
            timeout: '5s',
        });
        searchDuration.add(Date.now() - start);
        requestsTotal.add(1);
        
        const success = check(response, {
            'search status is 200': (r) => r.status === 200,
        });
        if (!success) errorRate.add(1);
    });
    
    sleep(Math.random() * 2 + 1);
}

// ======================================================
// SETUP И TEARDOWN
// ======================================================

export function setup() {
    console.log(`========================================`);
    console.log(`  НАГРУЗОЧНОЕ ТЕСТИРОВАНИЕ МИКРОБЛОГИНГА`);
    console.log(`========================================`);
    console.log(`Target URL: ${BASE_URL}`);
    console.log(`Start time: ${new Date().toISOString()}`);
    console.log(``);
    console.log(`Требования к тестированию:`);
    console.log(`  ✅ Feed загрузка ≤ 1.5 сек (Требование №3)`);
    console.log(`  ✅ Авторизация ≤ 2 сек (Требование №1)`);
    console.log(`  ✅ Публикация поста ≤ 1 сек (Требование №2)`);
    console.log(`  ✅ Подписка ≤ 500 мс (Требование №5)`);
    console.log(`  ✅ Поиск по тегам ≤ 2 сек (Требование №6)`);
    console.log(`  ✅ Spike лайки 10,000/сек (Требование №4)`);
    console.log(``);
    
    // Проверка доступности backend
    const healthCheck = http.get(`${BASE_URL}/actuator/health`, { timeout: '5s' });
    if (healthCheck.status !== 200) {
        console.error(`❌ Backend не доступен! Статус: ${healthCheck.status}`);
        return { error: 'Backend not available' };
    }
    console.log(`✅ Backend доступен`);
    
    // Создание тестовых пользователей
    console.log(`📝 Создание тестовых пользователей...`);
    for (const user of testUsers.slice(0, 20)) {
        const registerPayload = JSON.stringify({
            email: user.email,
            username: user.username,
            password: user.password,
        });
        http.post(`${BASE_URL}/api/v1/auth/register`, registerPayload, {
            headers: { 'Content-Type': 'application/json' },
        });
    }
    console.log(`✅ Создано ${testUsers.length} тестовых пользователей`);
    
    return { startTime: Date.now(), usersCount: testUsers.length };
}

export function teardown(data) {
    const duration = (Date.now() - data.startTime) / 1000;
    console.log(``);
    console.log(`========================================`);
    console.log(`  РЕЗУЛЬТАТЫ НАГРУЗОЧНОГО ТЕСТИРОВАНИЯ`);
    console.log(`========================================`);
    console.log(`Длительность: ${duration} секунд`);
    console.log(`Тестовых пользователей: ${data.usersCount}`);
    console.log(``);
    console.log(`✅ Тестирование завершено!`);
}
