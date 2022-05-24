FROM alpine:latest
LABEL maintainer="svilen@svilen.org"
RUN apk update
RUN apk upgrade
RUN apk add curl bash

WORKDIR /foseye

COPY entrypoint.sh ./
COPY *monitor.sh ./

RUN chmod +x *.sh

ENTRYPOINT ["/bin/bash","./entrypoint.sh"]