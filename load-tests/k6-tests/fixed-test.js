import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 10 },   // Медленный старт
        { duration: '1m', target: 50 },    // Средняя нагрузка
        { duration: '30s', target: 0 },    // Спад
    ],
    thresholds: {
        http_req_duration: ['p(95)<1000'],
        http_req_failed: ['rate<0.05'],
    },
};

export default function () {
    // Только GET запросы для начала
    const response = http.get('http://localhost:8080/api/v1/feed');
    check(response, { 'status is 200': (r) => r.status === 200 });
    sleep(1);
}
