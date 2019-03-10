FROM cassandra:3.11

COPY docker-entrypoint.sh /usr/local/bin/
COPY ready-probe.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/ready-probe.sh