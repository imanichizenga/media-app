FROM alpine:3.24
RUN apk add --no-cache pgbouncer && apk upgrade --no-cache && adduser -D -H -u 10002 -s /sbin/nologin bouncer
# RDS certificate authorities, pinned by digest at build time.
ARG RDS_CA_SHA256
ADD https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /etc/ssl/rds.pem
RUN chmod 444 /etc/ssl/rds.pem && if [ -n "$RDS_CA_SHA256" ]; then echo "$RDS_CA_SHA256  /etc/ssl/rds.pem" | sha256sum -c -; fi
COPY entrypoint.sh /entrypoint.sh
USER 10002
EXPOSE 6432
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
