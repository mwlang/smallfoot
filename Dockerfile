FROM crystallang/crystal:0.29.0 as system

RUN apt-get update && \
  apt-get install -y iputils-ping libnss3 libgconf-2-4 chromium-browser build-essential curl libreadline-dev libevent-dev libssl-dev libxml2-dev libyaml-dev libgmp-dev git golang-go postgresql postgresql-contrib locales && \
  # Set up node and yarn
  curl --silent --location https://deb.nodesource.com/setup_11.x | bash - && \
  apt-get install -y nodejs && \
  npm install -g yarn && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM system as shard-dependencies
WORKDIR /app
COPY shard* /app/
RUN shards install && \
  cd lib/lucky_cli && \
  shards install && \
  crystal build src/lucky.cr -o /app/bin/lucky

FROM shard-dependencies as assets-pipeline
WORKDIR /app
COPY ["package.json", "webpack*", "./"]
COPY src/js/ ./src/js/
COPY src/css/ ./src/css/
RUN yarn install && yarn prod && rm -rf /app/node_modules

FROM assets-pipeline as build

WORKDIR /app
COPY . /app

RUN shards build --production
RUN ldd /app/bin/smallfoot | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;' && \
  ldd /bin/bash | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;' && \
  ldd /bin/ls | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;' && \
  ldd /bin/ping | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;' && \
  ldd /bin/sh | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

FROM scratch

COPY --from=build /app/deps /
COPY --from=build /usr/lib/crystal/ /usr/lib/crystal/
COPY --from=build /bin/ping /bin/ls /bin/sh /bin/bash /bin/ls /bin/readlink /bin/ 
COPY --from=build /usr/bin/which /usr/bin/diff /usr/bin/shards /usr/bin/crystal /usr/bin/basename /usr/bin/dirname /usr/bin/

WORKDIR /app
COPY --from=build /app .
