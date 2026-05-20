FROM node:24-alpine3.22

RUN apk add --no-cache \
    git openssh openssl graphicsmagick tini tzdata ca-certificates libc6-compat \
    python3 make g++ \
    chromium nss freetype harfbuzz ttf-freefont font-noto-emoji

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# n8n + puppeteer toolkit installed globally so the sidecar can require them
RUN npm install -g \
      n8n@latest \
      puppeteer-core@latest \
      puppeteer-extra \
      puppeteer-extra-plugin-stealth \
      puppeteer-extra-plugin-user-preferences \
      puppeteer-extra-plugin-user-data-dir \
 && mkdir -p /home/node/.n8n /usr/local/lib/appbarber

# Sidecar HTTP service: AppBarber search via puppeteer-extra+stealth
COPY appbarber-search.js /usr/local/lib/appbarber/server.js

# Entrypoint: start sidecar in background, then n8n in foreground
RUN printf '#!/bin/sh\nset -e\nnode /usr/local/lib/appbarber/server.js > /tmp/sidecar.log 2>&1 &\nexec n8n\n' > /entrypoint.sh \
 && chmod +x /entrypoint.sh

ENV NODE_ENV=production
ENV NODE_PATH=/usr/local/lib/node_modules
ENV N8N_COMMUNITY_PACKAGES_ENABLED=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV SEARCH_PORT=8765

WORKDIR /home/node
EXPOSE 5678/tcp
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]