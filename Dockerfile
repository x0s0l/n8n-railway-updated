# n8n + chromium from a fresh node:alpine base. Bypasses the upstream
# n8nio/n8n image which strips its package manager and blocks any further
# apt/apk installations.
FROM node:24-alpine3.22

RUN apk add --no-cache \
    git \
    openssh \
    openssl \
    graphicsmagick \
    tini \
    tzdata \
    ca-certificates \
    libc6-compat \
    python3 \
    make \
    g++ \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    font-noto-emoji

# n8n + data dir
RUN npm install -g n8n@latest --omit=dev \
 && mkdir -p /home/node/.n8n

ENV NODE_ENV=production
ENV N8N_COMMUNITY_PACKAGES_ENABLED=true
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /home/node

# Stay as root: matches the original Shinyduo template + plays nice with
# the existing Railway persistent volume permissions. The puppeteer node
# launches chromium with --no-sandbox so root execution is OK.

EXPOSE 5678/tcp
ENTRYPOINT ["tini", "--", "n8n"]