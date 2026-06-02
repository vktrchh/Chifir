#!/usr/bin/env python3
"""
Простой mock backend для нагрузочного тестирования
Запуск: python3 mock_server.py
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
import random

class MockHandler(BaseHTTPRequestHandler):
    
    def send_json_response(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def do_GET(self):
        print(f"GET {self.path} - Started")
        start_time = time.time()
        
        # Имитация задержки обработки
        if '/api/v1/feed' in self.path:
            time.sleep(random.uniform(0.05, 0.2))  # 50-200ms задержка
            data = {
                "posts": [
                    {"id": i, "content": f"Test post {i}", "created_at": time.time()}
                    for i in range(20)
                ],
                "total": 100
            }
            self.send_json_response(200, data)
            
        elif '/api/v1/users/' in self.path:
            time.sleep(random.uniform(0.03, 0.1))
            data = {
                "id": self.path.split('/')[-1],
                "username": f"user_{random.randint(1,1000)}",
                "followers": random.randint(10, 1000),
                "following": random.randint(10, 500)
            }
            self.send_json_response(200, data)
            
        elif '/api/v1/tags/' in self.path and '/posts' in self.path:
            time.sleep(random.uniform(0.05, 0.15))
            data = {
                "posts": [
                    {"id": i, "content": f"Post with tag {i}"}
                    for i in range(20)
                ]
            }
            self.send_json_response(200, data)
            
        elif '/actuator/health' in self.path:
            data = {"status": "UP"}
            self.send_json_response(200, data)
            
        else:
            self.send_json_response(404, {"error": "Not found"})
        
        elapsed = (time.time() - start_time) * 1000
        print(f"GET {self.path} - Completed in {elapsed:.0f}ms")
    
    def do_POST(self):
        print(f"POST {self.path} - Started")
        start_time = time.time()
        
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else b'{}'
        
        if '/api/v1/auth/login' in self.path:
            time.sleep(random.uniform(0.1, 0.3))  # 100-300ms задержка
            data = {"token": f"mock_token_{random.randint(1000,9999)}"}
            self.send_json_response(200, data)
            
        elif '/api/v1/auth/register' in self.path:
            time.sleep(random.uniform(0.1, 0.2))
            data = {"user_id": random.randint(1, 10000), "message": "User created"}
            self.send_json_response(201, data)
            
        elif '/api/v1/posts' in self.path:
            time.sleep(random.uniform(0.05, 0.15))
            data = {"post_id": random.randint(1, 10000), "created_at": time.time()}
            self.send_json_response(201, data)
            
        elif '/like' in self.path:
            time.sleep(random.uniform(0.02, 0.05))
            data = {"message": "Liked"}
            self.send_json_response(200, data)
            
        elif '/follows/' in self.path:
            time.sleep(random.uniform(0.03, 0.08))
            data = {"message": "Followed"}
            self.send_json_response(200, data)
            
        else:
            self.send_json_response(404, {"error": "Not found"})
        
        elapsed = (time.time() - start_time) * 1000
        print(f"POST {self.path} - Completed in {elapsed:.0f}ms")
    
    def log_message(self, format, *args):
        pass  # Отключаем стандартное логирование

def run_server(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, MockHandler)
    print(f"🚀 Mock backend запущен на http://localhost:{port}")
    print(f"📊 Доступные эндпоинты:")
    print(f"   GET  /api/v1/feed")
    print(f"   GET  /api/v1/users/{{id}}")
    print(f"   GET  /api/v1/tags/{{tag}}/posts")
    print(f"   POST /api/v1/auth/login")
    print(f"   POST /api/v1/auth/register")
    print(f"   POST /api/v1/posts")
    print(f"   POST /api/v1/posts/{{id}}/like")
    print(f"   POST /api/v1/follows/{{id}}")
    print(f"\nНажмите Ctrl+C для остановки")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
