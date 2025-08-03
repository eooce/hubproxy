FROM alpine:3.20

WORKDIR /app

COPY start.sh ./

EXPOSE 5000/tcp

RUN apk update && apk upgrade && \
    apk add --no-cache curl bash libc6-compat && \
    chmod +x start.sh

CMD ["sh", "-c", "./start.sh & tail -f /dev/null"]
