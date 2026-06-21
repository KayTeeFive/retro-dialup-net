FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV UID=65533
ENV GID=65533

RUN apt-get update && apt-get install -y \
    mgetty \
    ppp \
    iproute2 \
    iputils-ping \
    net-tools \
    procps \
    iptables \
    && rm -rf /var/lib/apt/lists/*

# mgetty expects spool dirs
RUN mkdir -p /var/spool/mgetty /var/log/mgetty

# create 'dial' user

RUN groupadd -g ${GID} dial && \
    useradd -r -u  ${UID} -g ${GID} \
    -s /usr/sbin/nologin \
    -d /nonexistent \
    dial

RUN usermod -a -G dialout dial


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]