# story: e58s07
# Agent image for the A/B eval sandbox. Nothing from the host is baked in: the runner mounts
# only the run's workdir and its fresh $AB_HOME. Egress is the internal network (no internet)
# plus the allowlisting proxy, so the only reachable host is the model provider.
FROM node@sha256:c86ecead9e55a5210ac1727de38a4ca840bf03dcaf34dc9749addbf383b1920c

ARG PI_VERSION=1.5.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends bash ca-certificates curl git python3 \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g --no-audit --no-fund "@earendil-works/pi-coding-agent@${PI_VERSION}" \
 && npm cache clean --force

# Node 24 ignores HTTP(S)_PROXY in fetch() unless this is set; without it the container cannot
# reach the proxy at all. The grading container sets --network none, so the proxy is irrelevant there.
ENV NODE_USE_ENV_PROXY=1 \
    HTTPS_PROXY=http://bp-ab-proxy:8888 \
    HTTP_PROXY=http://bp-ab-proxy:8888 \
    NO_PROXY=localhost,127.0.0.1

# node:24-bookworm-slim already ships uid 1000 as `node`; reuse it instead of creating a user.
RUN mkdir -p /work /home/node/.pi/agent \
 && chown -R node:node /work /home/node

# The workdir comes from a host mount owned by another uid; without this, git in the container
# refuses to run against it ("dubious ownership").
RUN git config --system --add safe.directory '*'

USER node
WORKDIR /work
CMD ["bash"]
