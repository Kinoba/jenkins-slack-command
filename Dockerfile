FROM ruby:2.6-alpine3.9

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive

RUN apk update && \
    apk upgrade && \
    apk add --no-cache build-base ruby-dev && \
    rm -rf /var/cache/apk/*

RUN gem install rails \
                foreman \
                bundler

RUN addgroup -S rubyrunner && adduser -S rubyrunner -G rubyrunner

COPY . /home/rubyrunner

RUN cd /home/rubyrunner \
    && bundle install --no-color

USER rubyrunner
WORKDIR /home/rubyrunner

CMD ["foreman", "start"]
