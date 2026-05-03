FROM python:3-alpine

RUN apk add --no-cache ca-certificates

COPY --from=ghcr.io/twin/gatus:stable /gatus /gatus

COPY config/csv2config.py /scripts/csv2config.py
COPY config/project2csv.py /scripts/project2csv.py
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh /scripts/csv2config.py /scripts/project2csv.py

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/gatus"]
