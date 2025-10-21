FROM node:20-alpine
WORKDIR /app

# 复制 package.json 并安装依赖
COPY package.json ./
RUN npm i --omit=dev

# 复制源代码（新的分层结构）
COPY src ./src

EXPOSE 3000

# 使用新的入口文件
CMD ["node", "src/server.js"]
