FROM alpine:latest

RUN apk add --no-cache bash curl jq socat

WORKDIR /app

COPY vault_token_exporter.sh /app/

RUN chmod +x /app/vault_token_exporter.sh

CMD ["/app/vault_token_exporter.sh"]
