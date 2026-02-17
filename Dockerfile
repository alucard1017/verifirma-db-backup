FROM postgres:18-alpine

# Esta imagen ya trae pg_dump 18.x instalado
RUN apk add --no-cache aws-cli bash ca-certificates curl

WORKDIR /app

COPY backup.sh /app/backup.sh
RUN chmod +x /app/backup.sh

CMD ["/app/backup.sh"]
