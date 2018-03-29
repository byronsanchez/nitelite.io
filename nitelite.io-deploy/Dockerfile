
FROM byronsanchez/wintersmith-docker
LABEL maintainer "Byron Sanchez <byron@hackbytes.io>"

RUN apk --no-cache add \
  sqlite

RUN npm install -g webpack \
  live-server \
  coffeescript \
  grunt-cli \
  postcss-cli

# Package directory
RUN mkdir /home/wintersmith/packages
# App directory
RUN mkdir /home/wintersmith/nitelite.io

WORKDIR /home/wintersmith/packages

# Tell node where it can find the dependencies since they're not installed in the usual location

# can be used with USER to install global packages to a user directory
#RUN echo "prefix = /home/wintersmith/packages" > ~/.npmrc
# tell node where to resolve modules in require() statements
ENV NODE_PATH /home/wintersmith/packages/node_modules
ENV PATH /home/wintersmith/packages/node_modules/.bin:$PATH

COPY ./nitelite.io-web/package.json /home/wintersmith/packages
#RUN chown -R wintersmith:wintersmith /home/wintersmith/packages
RUN npm install --prefix /home/wintersmith/packages

COPY ./nitelite.io-web/ /home/wintersmith/nitelite.io

# This probably won't matter since we're mount binding anyway, and I'm not using docker containers for deployment yet
#RUN chown -R wintersmith:wintersmith /home/wintersmith/nitelite.io

WORKDIR /home/wintersmith/nitelite.io

#USER wintersmith

CMD ["npm", "run", "start-watch"]

# TODO: PHP (or replace it so I don't have to maintain it)
# - PHP7
# - PECL YAML

#RUN apk add php7 php7-fpm php7-opcache
#RUN apk add --no-cache --virtual .build-deps \
#    g++ make autoconf yaml-dev
#RUN pecl channel-update pecl.php.net
#RUN pecl install yaml-2.0.0 && docker-php-ext-enable yaml
#RUN apk del --purge .build-deps

# PHP Modules
#RUN apk add php7-gd php7-mysqli php7-zlib php7-curl

#CMD["/start"]
#/etc/init.d/php-fpm start;
#exec nginx

# TODO: other (execs, etc.)
# /var/lib/nitelite/webserver as a persistent data store
# VOLUME /var/lib/nitelite/nitelite.io/
