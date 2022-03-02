FROM eclipse-temurin:11

ARG kafka_version=3.1.0
ARG scala_version=2.13
ARG glibc_version=2.31-r0
ARG vcs_ref=unspecified
ARG build_date=unspecified
ARG LOG_DIR=/tmp
ARG KAFKA_HEAP_OPTS="-Xms512m -Xmx1g"
# ARG zookeeper_version=3.7.0
LABEL org.label-schema.name="kafka" \
      org.label-schema.description="Apache Kafka" \
      org.label-schema.build-date="${build_date}" \
      org.label-schema.vcs-url="https://github.com/zOS-Application-RI/multiarch-kafka" \
      org.label-schema.vcs-ref="${vcs_ref}" \
      org.label-schema.version="${scala_version}_${kafka_version}" \
      org.label-schema.schema-version="1.0" \
      maintainer="Ashish1981"

ENV KAFKA_VERSION=$kafka_version \
    SCALA_VERSION=$scala_version \
    # ZOOKEEPER_VERSION=${zookeeper_version} \
    KAFKA_HOME=/opt/kafka \
    GLIBC_VERSION=$glibc_version \
    PATH=${PATH}:${KAFKA_HOME}/bin

ADD /*.sh /tmp/
USER root
RUN apt-get update && apt-get full-upgrade -y && apt install -y \
    supervisor \
    curl \
    jq \
    docker \
    wget \
    make \
    build-essential  \
    && chmod a+x /tmp/*.sh \
    && cp -rf /tmp/*.sh /usr/bin/ \
    # && wget https://mirrors.estointernet.in/apache/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
    && wget https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
    && tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
    && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
    && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} 
    
# Use tini as subreaper in Docker container to adopt zombie processes
ARG TINI_VERSION=v0.19.0
COPY tini_pub.gpg ${KAFKA_HOME}/tini_pub.gpg
RUN curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture) -o /sbin/tini \
    && curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture).asc -o /sbin/tini.asc \
    && gpg --no-tty --import ${KAFKA_HOME}/tini_pub.gpg \
    && gpg --verify /sbin/tini.asc \
    && rm -rf /sbin/tini.asc /root/.gnupg \
    && chmod +x /sbin/tini
COPY tini-shim.sh /bin/tini
RUN chmod +x /bin/tini

COPY /supervisor/supervisord.conf /etc/supervisord.conf
RUN chmod 777 /etc/supervisord.conf
RUN mkdir -p /var/log/supervisord \
    && chmod a+w /var/log/supervisord/ \
    && mkdir -p /opt/kafka/logs \
    && chmod a+w /opt/kafka/logs


COPY /server.properties $KAFKA_HOME/config/server.properties
# VOLUME ["/kafka"]
#ADD scripts/start-kafka.sh /usr/bin/start-kafka.sh
# Supervisor config
# ADD supervisor/kafka.conf supervisor/zookeeper.conf /etc/supervisor/conf.d/
# 2181 is zookeeper, 9092 is kafka
EXPOSE 2181 9092
# CMD ["supervisord", "-n"]
ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]