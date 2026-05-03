FROM rclone/rclone:1 AS rclone

FROM mysql:8.0

RUN microdnf install -y cronie gzip curl logrotate rsync && microdnf clean all

COPY --from=rclone /usr/local/bin/rclone /usr/bin/rclone

COPY backup.sh /backup.sh
COPY upload.sh /upload.sh
COPY sync-local.sh /sync-local.sh
COPY run.sh /run.sh
COPY notify.sh /notify.sh
COPY crontab /etc/cron.d/backup-cron
COPY logrotate.conf /etc/logrotate.d/mysql-backup

RUN chmod +x /backup.sh /upload.sh /sync-local.sh /run.sh /notify.sh && \
    chmod 0644 /etc/cron.d/backup-cron /etc/logrotate.d/mysql-backup && \
    crontab /etc/cron.d/backup-cron

CMD ["crond", "-n"]
