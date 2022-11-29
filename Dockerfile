FROM mysql:8.0

ARG MYSQL_ALLOW_EMPTY_PASSWORD=1
ENV MYSQL_ALLOW_EMPTY_PASSWORD=1

RUN mkdir /var/lib/mysql-no-volume \
    && chown -R mysql:mysql /var/lib/mysql-no-volume \
    && chmod 1777 /var/lib/mysql-no-volume

RUN mysqld --initialize-insecure --datadir=/var/lib/mysql-no-volume/data

COPY script.sh /usr/local/bin
RUN chmod +x /usr/local/bin/script.sh
# RUN rm /entrypoint.sh && ln -s usr/local/bin/script.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["script.sh"]

CMD mysqld --datadir=/var/lib/mysql-no-volume/data
# CMD mysqld --datadir=/var/lib/mysql
