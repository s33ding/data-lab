FROM confluentinc/cp-kafka-connect:7.5.0

USER root

# Download and install Debezium PostgreSQL connector
RUN curl -L https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.4.0.Final/debezium-connector-postgres-2.4.0.Final-plugin.tar.gz \
    | tar -xz -C /usr/share/confluent-hub-components/

# Install S3 connector via confluent-hub
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-s3:10.5.0

# Set proper permissions
RUN chown -R appuser:appuser /usr/share/confluent-hub-components

USER appuser
