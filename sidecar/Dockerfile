# AppBarber search sidecar — runs puppeteer-extra+stealth in own process.
# Deploy as separate Railway service from the same repo (Root Directory: sidecar/).
FROM node:24-alpine3.22

RUN apk add --no-cache \
    chromium nss freetype harfbuzz ca-certificates ttf-freefont font-noto-emoji \
    tini

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./

ENV NODE_ENV=production
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV SEARCH_PORT=8765

EXPOSE 8765
ENTRYPOINT ["tini", "--", "node", "server.js"]
