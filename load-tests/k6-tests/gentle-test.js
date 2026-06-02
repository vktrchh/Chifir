import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    gentle: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 10 },   // Медленный разогрев
        { duration: '30s', target: 20 },   // Максимум 20 пользователей
        { duration: '10s', target: 0 },    // Плавное снижение
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],     // 95% запросов < 500ms
    http_req_failed: ['rate<0.01'],       // < 1% ошибок
  },
};

export default function () {
  // Только GET запросы (без авторизации)
  const response = http.get('http://localhost:8080/api/v1/feed');
  
  check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  sleep(2);  // Больше паузы между запросами
}
