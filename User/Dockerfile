FROM node:18-alpine

WORKDIR /app

ENV NODE_ENV=development

COPY package*.json ./

RUN npm ci

COPY . .

EXPOSE 9001

CMD ["npm", "run", "dev"]