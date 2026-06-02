# locustfile.py - Тестирование с Locust
# РАСПОЛОЖЕНИЕ: ~/load-tests/locust-tests/locustfile.py
# ЗАПУСК: locust -f locustfile.py --host=http://localhost:8080

from locust import HttpUser, task, between, events
import random
import json

class MicroblogUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Логин при старте каждого пользователя"""
        response = self.client.post("/api/v1/auth/login", json={
            "email": "test1@example.com",
            "password": "Test123!"
        })
        if response.status_code == 200:
            self.token = response.json().get("token")
    
    @task(70)  # 70% запросов - чтение ленты
    def get_feed(self):
        headers = {"Authorization": f"Bearer {self.token}"} if hasattr(self, 'token') else {}
        self.client.get("/api/v1/feed?limit=20", headers=headers)
    
    @task(10)  # 10% - создание поста
    def create_post(self):
        headers = {"Authorization": f"Bearer {self.token}"} if hasattr(self, 'token') else {}
        self.client.post("/api/v1/posts", 
            json={
                "content": f"Test post {random.randint(1, 10000)} #loadtest",
                "mediaIds": []
            },
            headers=headers)
    
    @task(15)  # 15% - лайк
    def like_post(self):
        headers = {"Authorization": f"Bearer {self.token}"} if hasattr(self, 'token') else {}
        post_id = random.randint(1, 1000)
        self.client.post(f"/api/v1/posts/{post_id}/like", headers=headers)
    
    @task(5)  # 5% - подписка
    def follow_user(self):
        headers = {"Authorization": f"Bearer {self.token}"} if hasattr(self, 'token') else {}
        user_id = random.randint(1, 100)
        self.client.post(f"/api/v1/follows/{user_id}", headers=headers)

# Запуск:
# locust -f locustfile.py --host=http://localhost:8080 --users=100 --spawn-rate=10
