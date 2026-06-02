#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import time
import random

class FastMockHandler(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'
    
    def log_message(self, format, *args):
        pass
    
    def send_json(self, code, data):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Connection', 'keep-alive')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def do_GET(self):
        if '/api/v1/feed' in self.path:
            time.sleep(random.uniform(0.01, 0.03))
            self.send_json(200, {
                "posts": [{"id": i, "content": f"Post {i}"} for i in range(20)],
                "total": 1000
            })
        elif '/actuator/health' in self.path:
            self.send_json(200, {"status": "UP"})
        elif '/api/v1/users/' in self.path:
            self.send_json(200, {
                "id": self.path.split('/')[-1],
                "username": f"user_{random.randint(1,1000)}",
                "followers": random.randint(10, 1000)
            })
        elif '/api/v1/tags/' in self.path and '/posts' in self.path:
            self.send_json(200, {
                "posts": [{"id": i, "content": f"Post with tag"} for i in range(20)]
            })
        else:
            self.send_json(404, {"error": "Not found"})
    
    def do_POST(self):
        if '/api/v1/auth/login' in self.path:
            time.sleep(random.uniform(0.01, 0.02))
            self.send_json(200, {"token": f"token_{random.randint(1000,9999)}", "accessToken": f"token_{random.randint(1000,9999)}"})
        elif '/api/v1/auth/register' in self.path:
            self.send_json(201, {"user_id": random.randint(1,10000), "message": "User created"})
        elif '/api/v1/posts' in self.path:
            time.sleep(random.uniform(0.005, 0.01))
            self.send_json(201, {"id": random.randint(1,10000), "post_id": random.randint(1,10000), "created_at": time.time()})
        elif '/like' in self.path:
            self.send_json(200, {"message": "Liked"})
        elif '/follows/' in self.path:
            self.send_json(200, {"message": "Followed"})
        else:
            self.send_json(404, {"error": "Not found"})

def run_server():
    server = ThreadingHTTPServer(('0.0.0.0', 8080), FastMockHandler)
    print("🚀 FAST Mock backend запущен на http://localhost:8080")
    print("📊 Оптимизирован для высокой нагрузки")
    print("✅ Готов к полному нагрузочному тестированию")
    server.serve_forever()

if __name__ == '__main__':
    run_server()
