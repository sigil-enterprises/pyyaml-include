FROM python:3.13.5-slim-bookworm AS base

WORKDIR /app
RUN apt update && apt install -y git make

ARG ORGANIZATION=sigil-enterprises
ENV DEBIAN_FRONTEND=noninteractive

ENTRYPOINT ["make"]

FROM base AS build

COPY . .
RUN --mount=type=secret,id=github_token \
  git config --global url."https://$(cat /run/secrets/github_token):@github.com/$ORGANIZATION/".insteadOf "ssh://git@github.com/sigil-enterprises/" \
  && make setup
