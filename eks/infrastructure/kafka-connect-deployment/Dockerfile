FROM confluentinc/cp-kafka-connect:7.5.0

USER root

# Download and install Debezium PostgreSQL connector
RUN curl -L https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.4.0.Final/debezium-connector-postgres-2.4.0.Final-plugin.tar.gz \
    | tar -xz -C /usr/share/confluent-hub-components/

# Download and install Debezium SQL Server connector
RUN curl -L https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/2.4.0.Final/debezium-connector-sqlserver-2.4.0.Final-plugin.tar.gz \
    | tar -xz -C /usr/share/confluent-hub-components/

# Install S3 connector via confluent-hub
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-s3:10.5.0

# Install Tabular Iceberg connector with AWS S3 Tables support
RUN yum install -y unzip && \
    cd /tmp && \
    curl -L https://github.com/tabular-io/iceberg-kafka-connect/releases/download/v0.6.19/iceberg-kafka-connect-runtime-0.6.19.zip -o iceberg.zip && \
    unzip iceberg.zip -d /usr/share/confluent-hub-components/ && \
    rm iceberg.zip && \
    cd /usr/share/confluent-hub-components/iceberg-kafka-connect-runtime-0.6.19/lib && \
    rm -f iceberg-aws-bundle-*.jar && \
    curl -O https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.7.1/iceberg-aws-bundle-1.7.1.jar && \
    cd /usr/share/confluent-hub-components/iceberg-kafka-connect-runtime-0.6.19 && \
    curl -O https://repo1.maven.org/maven2/software/amazon/s3tables/s3-tables-catalog-for-iceberg/0.1.3/s3-tables-catalog-for-iceberg-0.1.3-all.jar

# Set proper permissions
RUN chown -R appuser:appuser /usr/share/confluent-hub-components

USER appuser
