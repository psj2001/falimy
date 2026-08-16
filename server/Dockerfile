# Falimy API — production image
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY src ./src

ENV NODE_ENV=production
ENV USE_MEMORY_MONGO=false
EXPOSE 3000

CMD ["node", "src/index.js"]
