# 第一阶段：构建应用--
FROM node:18-alpine AS build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 第二阶段：部署到 Nginx
FROM nginx:alpine AS production-stage
# 复制构建产物
COPY --from=build-stage /app/dist /usr/share/nginx/html
# 复制自定义 Nginx 配置（若需处理 history 路由模式）
COPY nginx.conf /etc/nginx/conf.d/nginx.conf
# 暴露端口9006
EXPOSE 9006
# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
