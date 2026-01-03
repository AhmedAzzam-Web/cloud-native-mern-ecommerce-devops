FROM node:22-alpine3.22 AS dev
WORKDIR /app
ENV NODE_ENV=development
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
EXPOSE 9003
CMD ["npm", "run", "dev"]

FROM node:22-alpine3.22 AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production
COPY . .
RUN ["npm", "run", "build"]

FROM gcr.io/distroless/nodejs22-debian12 AS prod
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
USER 65532:65532 # Standard Distroless non-root user
EXPOSE 9003
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD [ "node", "-e", "require('http').get('http://localhost:9003/health', (res) => res.statusCode === 200 ? process.exit(0) : process.exit(1))" ]
ENTRYPOINT ["node", "dist/index.js"] # distroless provides the Node runtime binary