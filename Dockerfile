FROM ubuntu:20.04

USER root

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install python 3.10
RUN apt-get update && apt-get install wget curl software-properties-common unzip zip -y && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && apt-get install python3.10-full python3.10-venv -y && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Install poetry
ENV PATH="/root/.local/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | python - && \
    poetry config virtualenvs.create false

# Install ipykernel
RUN pip install ipykernel

# Install Java 8
RUN apt-get install openjdk-8-jdk -y

# Removed the .cache to save space
RUN rm -rf /root/.cache && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

# Install spark (3.3.1) with hadoop support
RUN wget https://archive.apache.org/dist/spark/spark-3.3.1/spark-3.3.1-bin-hadoop3.tgz && \
    tar xvf spark-3.3.1-bin-hadoop3.tgz && \
    mv spark-3.3.1-bin-hadoop3/ /opt/spark && \
    rm spark-3.3.1-bin-hadoop3.tgz
ENV SPARK_HOME=/opt/spark \
    PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbi \
    PYSPARK_DRIVER_PYTHON=/usr/bin/python3.10 \
    PYSPARK_PYTHON=/usr/bin/python3.10

# Download extra spark/azure/hadoop libraries (https://learn.microsoft.com/en-us/azure/synapse-analytics/spark/apache-spark-33-runtime)
RUN curl -o $SPARK_HOME/jars/spark-avro_2.12-3.3.1.jar https://repo1.maven.org/maven2/org/apache/spark/spark-avro_2.12/3.3.1/spark-avro_2.12-3.3.1.jar && \
    curl -o $SPARK_HOME/jars/delta-core_2.12-2.2.0.jar https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.2.0/delta-core_2.12-2.2.0.jar && \
    curl -o $SPARK_HOME/jars/delta-storage-2.2.0.jar https://repo1.maven.org/maven2/io/delta/delta-storage/2.2.0/delta-storage-2.2.0.jar && \
    curl -o $SPARK_HOME/jars/hadoop-azure-3.3.3.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/3.3.3/hadoop-azure-3.3.3.jar && \
    curl -o $SPARK_HOME/jars/hadoop-azure-datalake-3.3.3.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure-datalake/3.3.3/hadoop-azure-datalake-3.3.3.jar && \
    curl -o $SPARK_HOME/jars/wildfly-openssl-1.0.7.Final.jar https://repo1.maven.org/maven2/org/wildfly/openssl/wildfly-openssl/1.0.7.Final/wildfly-openssl-1.0.7.Final.jar && \
    curl -o $SPARK_HOME/jars/azure-data-lake-store-sdk-2.3.9.jar https://repo1.maven.org/maven2/com/microsoft/azure/azure-data-lake-store-sdk/2.3.9/azure-data-lake-store-sdk-2.3.9.jar && \
    curl -o $SPARK_HOME/jars/azure-keyvault-core-1.0.0.jar https://repo1.maven.org/maven2/com/microsoft/azure/azure-keyvault-core/1.0.0/azure-keyvault-core-1.0.0.jar && \
    curl -o $SPARK_HOME/jars/azure-storage-7.0.1.jar https://repo1.maven.org/maven2/com/microsoft/azure/azure-storage/7.0.1/azure-storage-7.0.1.jar && \
    curl -o $SPARK_HOME/jars/azure-eventhubs-3.3.0.jar https://repo1.maven.org/maven2/com/microsoft/azure/azure-eventhubs/3.3.0/azure-eventhubs-3.3.0.jar


# Install sdkman && hadoop (3.3.0)
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN curl -s https://get.sdkman.io | bash
RUN chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh"
RUN source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install hadoop
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64 \
    HADOOP_HOME=/root/.sdkman/candidates/hadoop/current
RUN curl -o $HADOOP_HOME/share/hadoop/common/hadoop-azure-3.3.0.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/3.3.0/hadoop-azure-3.3.0.jar && \
    curl -o $HADOOP_HOME/share/hadoop/common/wildfly-openssl-1.0.7.Final.jar https://repo1.maven.org/maven2/org/wildfly/openssl/wildfly-openssl/1.0.7.Final/wildfly-openssl-1.0.7.Final.jar
