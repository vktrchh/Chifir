import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '1m', target: 100 },
        { duration: '3m', target: 500 },
        { duration: '5m', target: 1000 },
        { duration: '2m', target: 0 },
    ],
    thresholds: {
        http_req_duration: ['p(95)<1500'],
        http_req_failed: ['rate<0.01'],
    },
};

export default function () {
    const response = http.get('http://localhost:8080/api/v1/feed?limit=20');
    check(response, { 'status is 200': (r) => r.status === 200 });
    sleep(0.2);
}
