FROM node:24-alpine3.22

RUN apk add --no-cache \
    git openssh openssl graphicsmagick tini tzdata ca-certificates libc6-compat \
    python3 make g++ \
    chromium nss freetype harfbuzz ttf-freefont font-noto-emoji

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN npm install -g \
      n8n@latest \
      puppeteer-core@latest \
      puppeteer-extra \
      puppeteer-extra-plugin-stealth \
      puppeteer-extra-plugin-user-preferences \
      puppeteer-extra-plugin-user-data-dir \
    && mkdir -p /home/node/.n8n

ENV NODE_ENV=production
ENV N8N_COMMUNITY_PACKAGES_ENABLED=true
ENV NODE_FUNCTION_ALLOW_EXTERNAL=puppeteer-core,puppeteer-extra,puppeteer-extra-plugin-stealth,puppeteer-extra-plugin-user-preferences,puppeteer-extra-plugin-user-data-dir
ENV NODE_PATH=/usr/local/lib/node_modules
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /home/node
EXPOSE 5678/tcp
ENTRYPOINT ["tini", "--", "n8n"]