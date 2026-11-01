'use strict';

// 把容器内的 127.0.0.1:9222-9232/9333 转到 macOS 上的 WorkBuddy。
// Docker Desktop 会把 host.docker.internal 上的连接送到宿主机的 127.0.0.1，
// 因此不需要把调试端口暴露到局域网。
const net = require('net');

const upstreamHost = process.env.WORKDADDY_CDP_UPSTREAM_HOST || 'host.docker.internal';
const ports = [];
for (let port = 9222; port <= 9232; port++) ports.push(port);
ports.push(9333);

function listen(port) {
  const server = net.createServer((socket) => {
    const upstream = net.connect(port, upstreamHost);
    const closeBoth = () => {
      socket.destroy();
      upstream.destroy();
    };
    upstream.on('error', closeBoth);
    socket.on('error', closeBoth);
    upstream.on('close', () => socket.destroy());
    socket.on('close', () => upstream.destroy());
    socket.pipe(upstream);
    upstream.pipe(socket);
  });
  server.on('error', (error) => {
    console.error(`[cdp-proxy] ${port} 监听失败: ${error.message}`);
  });
  server.listen(port, '127.0.0.1');
}

for (const port of ports) listen(port);
