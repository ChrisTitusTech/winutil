ARG NODE_VERSION=24
FROM node:${NODE_VERSION}-bookworm-slim

RUN corepack enable

WORKDIR /app

# Keeps Playwright's browsers out of root's home so the node user can reach them.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Deps first for layer caching; lifecycle scripts stay on since Astro/Vite need some.
COPY package*.json ./
RUN npm ci

COPY . .

# Browsers and their system libraries for Playwright tests; needs root for apt-get.
# --no-install fails the build rather than fetching an unpinned Playwright if it's missing from package.json.
RUN npx --no-install playwright install --with-deps chromium firefox webkit \
    && rm -rf /var/lib/apt/lists/*

# Run as a non-root user for defense-in-depth.
RUN chown -R node:node /app "$PLAYWRIGHT_BROWSERS_PATH"
USER node

EXPOSE 4321
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
