FROM alpine:3.20

WORKDIR /app

COPY . .

EXPOSE 5000/tcp

RUN apk update && apk upgrade && \
    apk add --no-cache curl bash && \
    chmod +x start.sh

CMD ["sh", "-c", "./start.sh & tail -f /dev/null"]
