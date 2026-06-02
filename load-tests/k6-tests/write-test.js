import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '1m', target: 10 },
        { duration: '5m', target: 25 },
        { duration: '2m', target: 0 },
    ],
    thresholds: {
        http_req_duration: ['p(95)<1000'],
        http_req_failed: ['rate<0.01'],
    },
};

export default function () {
    const payload = JSON.stringify({
        content: `Тестовый пост ${Date.now()} #loadtest`,
        mediaIds: [],
        tags: ['loadtest', 'k6'],
    });
    
    const response = http.post('http://localhost:8080/api/v1/posts', payload, {
        headers: { 'Content-Type': 'application/json' },
    });
    
    check(response, { 'post status 201': (r) => r.status === 201 });
    sleep(2);
}
