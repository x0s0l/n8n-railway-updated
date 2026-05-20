# Multi-stage: chromium + deps come from a fresh alpine layer because the
# upstream n8n image strips its package manager (apk) for security.
FROM alpine:3.22 AS chromium-stage
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto-emoji

FROM n8nio/n8n:latest

USER root

# Copy chromium binary + its runtime libs from the alpine stage
COPY --from=chromium-stage /usr/bin/chromium /usr/bin/chromium
COPY --from=chromium-stage /usr/lib/chromium /usr/lib/chromium
COPY --from=chromium-stage /usr/share/fonts /usr/share/fonts
COPY --from=chromium-stage /etc/fonts /etc/fonts

# Required shared libs (musl-compatible since both stages are alpine 3.22)
COPY --from=chromium-stage /usr/lib/libnss3.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libnssutil3.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libsmime3.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libsoftokn3.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libfreebl3.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libplc4.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libplds4.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libnspr4.so /usr/lib/
COPY --from=chromium-stage /usr/lib/libfreetype.so* /usr/lib/
COPY --from=chromium-stage /usr/lib/libharfbuzz.so* /usr/lib/

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV N8N_COMMUNITY_PACKAGES_ENABLED=true

USER node
