FROM alpine:3.19

# Instalar pg_dump (postgresql-client) y awscli
RUN apk add --no-cache postgresql-client aws-cli bash ca-certificates curl

WORKDIR /app

COPY backup.sh /app/backup.sh
RUN chmod +x /app/backup.sh

CMD ["/app/backup.sh"]
