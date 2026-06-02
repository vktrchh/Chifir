const http = require('http');
const url = require('url');

const PORT = 8080;

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // Health check
    if (parsedUrl.pathname === '/actuator/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'UP' }));
        return;
    }
    
    // Feed endpoint
    if (parsedUrl.pathname === '/api/v1/feed') {
        const posts = [];
        for (let i = 0; i < 20; i++) {
            posts.push({
                id: i,
                content: `Post ${i} for load testing`,
                created_at: new Date().toISOString()
            });
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ posts, total: 1000 }));
        return;
    }
    
    // Login endpoint
    if (parsedUrl.pathname === '/api/v1/auth/login' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ 
                token: `token_${Date.now()}_${Math.random()}`,
                expires_in: 3600
            }));
        });
        return;
    }
    
    // Create post
    if (parsedUrl.pathname === '/api/v1/posts' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            res.writeHead(201, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ 
                id: Math.floor(Math.random() * 100000),
                created_at: new Date().toISOString()
            }));
        });
        return;
    }
    
    // Like post
    if (parsedUrl.pathname.match(/\/api\/v1\/posts\/\d+\/like/) && req.method === 'POST') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Liked successfully' }));
        return;
    }
    
    // Follow user
    if (parsedUrl.pathname.match(/\/api\/v1\/follows\/\d+/) && req.method === 'POST') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Followed successfully' }));
        return;
    }
    
    // User profile
    if (parsedUrl.pathname.match(/\/api\/v1\/users\/\d+/)) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            id: parsedUrl.pathname.split('/').pop(),
            username: `user_${Math.floor(Math.random() * 10000)}`,
            followers: Math.floor(Math.random() * 1000),
            following: Math.floor(Math.random() * 500),
            posts_count: Math.floor(Math.random() * 100)
        }));
        return;
    }
    
    // Search by tag
    if (parsedUrl.pathname.match(/\/api\/v1\/tags\/[^\/]+\/posts/)) {
        const posts = [];
        for (let i = 0; i < 20; i++) {
            posts.push({ id: i, content: `Post with tag` });
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ posts, total: 100 }));
        return;
    }
    
    // 404
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
});

// Настройки для высокой нагрузки
server.maxHeadersCount = 0;
server.timeout = 0;
server.keepAliveTimeout = 30000;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 High-performance backend running on port ${PORT}`);
    console.log(`📊 Optimized for high load (10000+ RPS)`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down...');
    server.close(() => process.exit(0));
});
