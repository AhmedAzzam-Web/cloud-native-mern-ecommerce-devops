FROM node:22-alpine3.22 AS dev
WORKDIR /app
ENV NODE_ENV=development
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 5173 
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]

FROM node:22-alpine3.22 AS builder
WORKDIR /app
COPY package.json package-lock.json ./
# can't add --only=production coz vite needs some devDependencies like vite and @vitejs/plugin-react
# --frozen-lockfile to enfore the matching between package.json & -lock.json an extra layer of enforcement
RUN npm ci --frozen-lockfile
COPY . .
RUN ["npm", "run", "build"]

FROM nginx:stable-alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
# Alpine includes wget
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/ || exit 1
ENTRYPOINT ["nginx", "-g", "daemon off;"]