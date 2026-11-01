FROM node:22-bookworm-slim

WORKDIR /app

# 守护进程只用 Node 内置模块（含 node:sqlite），不需要安装依赖。
COPY scripts ./scripts
COPY schemas ./schemas
COPY docker ./docker

ENV NODE_ENV=production \
    WBSWITCH_PROFILE=workbuddy-cn \
    WBSWITCH_PORT=47900 \
    WBSWITCH_BIND_HOST=0.0.0.0 \
    WBSWITCH_DATA_DIR=/host-config/WorkDaddy

EXPOSE 47900

HEALTHCHECK --interval=10s --timeout=3s --start-period=8s --retries=8 \
  CMD node -e "fetch('http://127.0.0.1:47900/api/status').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "docker/entrypoint.js"]
