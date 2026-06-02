// ОЧЕНЬ МАЛЕНЬКАЯ НАГРУЗКА ДЛЯ ТЕСТА
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = 'http://localhost:8080';

export const options = {
    vus: 10,  // Всего 10 пользователей
    duration: '30s',
    thresholds: {
        http_req_duration: ['p(95)<3000'],
        http_req_failed: ['rate<0.1'],
    },
};

export default function () {
    const response = http.get(`${BASE_URL}/api/v1/feed?limit=20`);
    check(response, { 'status is 200': (r) => r.status === 200 });
    sleep(1);
}
