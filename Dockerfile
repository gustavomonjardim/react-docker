#syntax=docker/dockerfile:1.4
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

RUN yarn global add pnpm

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod && \
    # Cache prod dependencies
    cp -R node_modules ./prod_node_modules && \
    # Install dev dependencies
    pnpm install --frozen-lockfile
# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY  . .

RUN yarn build


# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production


COPY --from=builder /app/build ./build
COPY --from=builder /app/pnpm-lock.yaml /app/package.json ./
COPY --from=deps /app/prod_node_modules ./node_modules


USER node

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME localhost

CMD ["yarn", "serve"]