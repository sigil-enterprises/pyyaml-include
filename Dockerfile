# Watermarked by tc from github.com/sigil-enterprises/sigil-toolchain@v0.39.2
#
FROM python:3.10-slim-bookworm AS base

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive \
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1

# Pin uv version — update to latest stable: https://github.com/astral-sh/uv/releases
COPY --from=ghcr.io/astral-sh/uv:0.6.14 /uv /usr/local/bin/uv

RUN apt-get update && apt-get install -y --no-install-recommends \
      git make git-lfs \
 && rm -rf /var/lib/apt/lists/*

ARG ORGANIZATION
COPY pyproject.toml uv.lock README.md ./

RUN --mount=type=secret,id=github_token \
  --mount=type=secret,id=nexus_username \
  --mount=type=secret,id=nexus_password \
  GIT_CONFIG_COUNT=1 \
  GIT_CONFIG_KEY_0="url.https://x-access-token:$(cat /run/secrets/github_token)@github.com/$ORGANIZATION/.insteadOf" \
  GIT_CONFIG_VALUE_0="https://github.com/sigil-enterprises/" \
  NEXUS_USER=$(cat /run/secrets/nexus_username 2>/dev/null) \
  NEXUS_PASS=$(cat /run/secrets/nexus_password 2>/dev/null) \
  && if [ -n "$NEXUS_USER" ] && [ -n "$NEXUS_PASS" ]; then \
       UV_INDEX_URL="https://${NEXUS_USER}:${NEXUS_PASS}@nexus.opvance.com/repository/pypi-group/simple/" \
       SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0 uv sync --system --frozen; \
     else \
       SETUPTOOLS_SCM_PRETEND_VERSION=0.0.0 uv sync --system --frozen; \
     fi

RUN groupadd --gid 1000 app \
 && useradd --uid 1000 --gid app --create-home app \
 && chown -R app:app /app

USER app

ENTRYPOINT ["make"]
CMD ["help"]


FROM base AS build

# Copy source on top of the pre-built base.  Any code change only
# invalidates this COPY layer — all heavy installs are in the base image.
COPY . .
