FROM node:22-alpine3.22 AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production
COPY . .
RUN ["npm", "run", "build"]

FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
EXPOSE 9001
USER node # already exist in this distroless base image
ENTRYPOINT ["node", "dist/index.js"] # distroless provides the Node runtime binary