FROM rclone/rclone:1 AS rclone

FROM mysql:8.0

RUN microdnf install -y cronie gzip curl logrotate rsync && microdnf clean all

COPY --from=rclone /usr/local/bin/rclone /usr/bin/rclone

COPY scripts/ /scripts/
COPY crontab /etc/cron.d/backup-cron
COPY logrotate.conf /etc/logrotate.d/mysql-backup

RUN chmod +x /scripts/*.sh && \
    chmod 0644 /etc/cron.d/backup-cron /etc/logrotate.d/mysql-backup && \
    crontab /etc/cron.d/backup-cron

CMD ["crond", "-n"]
