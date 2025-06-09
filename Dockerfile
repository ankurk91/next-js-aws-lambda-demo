FROM public.ecr.aws/docker/library/node:22-bookworm-slim AS builder

WORKDIR /build
ENV DEBIAN_FRONTEND=noninteractive

COPY package*.json ./
RUN npm ci --no-audit

COPY . .

ARG NEXT_ASSET_PREFIX_URL
# Keep NODE_ENV line just before building, dont move this line up before "npm ci"
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_ASSET_PREFIX_URL=$NEXT_ASSET_PREFIX_URL
RUN npm run build -- --no-lint

FROM public.ecr.aws/aws-cli/aws-cli:latest AS uploader

WORKDIR /files

ARG NEXT_ASSET_BUCKET_NAME
ENV NEXT_ASSET_BUCKET_NAME=$NEXT_ASSET_BUCKET_NAME

COPY --from=builder /build/.next/static ./static

RUN --mount=type=secret,id=AWS_ACCESS_KEY_ID \
    --mount=type=secret,id=AWS_SECRET_ACCESS_KEY \
    --mount=type=secret,id=AWS_SESSION_TOKEN \
    --mount=type=secret,id=AWS_REGION \
    bash -c '\
      aws configure set aws_access_key_id "$(cat /run/secrets/AWS_ACCESS_KEY_ID)" && \
      aws configure set aws_secret_access_key "$(cat /run/secrets/AWS_SECRET_ACCESS_KEY)" && \
      aws configure set aws_session_token "$(cat /run/secrets/AWS_SESSION_TOKEN)" && \
      aws configure set region "$(cat /run/secrets/AWS_REGION)" \
    '

RUN aws sts get-caller-identity
RUN aws configure set default.s3.max_concurrent_requests 100 && \
    aws configure set default.retry_mode adaptive
RUN aws s3 sync ./static "s3://$NEXT_ASSET_BUCKET_NAME/_next/static" \
    --delete \
    --no-progress \
    --cache-control "public,max-age=604800,immutable"

# Workaround to ensure this stage will run
RUN touch assets-uploaded.txt

FROM public.ecr.aws/docker/library/node:22-bookworm-slim AS runner

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV KEEP_ALIVE_TIMEOUT=30
# Reserved for next.js standalome build
ENV PORT=5000

# curl is required for ECS health checks
# Other packages required for node-canvas npm package
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && update-ca-certificates --fresh \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY --from=builder --chown=node:node /build/.next/standalone ./
COPY --from=builder --chown=node:node /build/public ./public
# Workaround to ensure uploader stage is connected to final stage
COPY --from=uploader /files/assets-uploaded.txt ./

EXPOSE $PORT
USER node
CMD ["node", "server.js"]

