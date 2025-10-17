FROM node:lts-alpine as builder

RUN apk add --no-cache git python3 py3-pip make g++

WORKDIR /app

RUN git clone https://github.com/zone-eu/zone-mta-template ./

RUN npm install @zone-eu/zone-mta
RUN npm install --production
RUN npm install @zone-eu/zonemta-wildduck

FROM node:lts-alpine as app

ENV NODE_ENV production

RUN apk add --no-cache tini

WORKDIR /app
COPY --from=builder /app /app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "index.js", "--config=config/zonemta.toml"]
