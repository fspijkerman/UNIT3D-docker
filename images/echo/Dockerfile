FROM node:7-alpine

RUN apk add --update --no-cache bash \
	&& apk add --update --no-cache -t .build-deps python make g++ gcc \
	&& npm i -g laravel-echo-server \
	&& apk del .build-deps

WORKDIR /app

COPY rootfs /
RUN chmod +x /usr/local/bin/*

#ENTRYPOINT ["laravel-echo-server"]
ENTRYPOINT ["run.sh"]
CMD ["start"]
