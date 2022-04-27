FROM maven:3.6.3-openjdk-8 AS namespace-manager-builder
ARG PRESTO_VERSION=0.258
ARG MAVEN_OPTS
RUN git clone --branch $PRESTO_VERSION --depth 1 https://github.com/prestodb/presto.git /presto && \
    cd /presto && \
    mvn clean install -pl presto-function-namespace-managers -am -DskipTests && \
    rm -rf /root/.m2

FROM openjdk:8u282-jre-buster
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

ARG PRESTO_VERSION=0.258
ENV HADOOP_HOME /opt/hadoop
ENV HIVE_HOME /opt/hive
ENV PRESTO_HOME /opt/presto
ENV PATH $PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin:$PRESTO_HOME/bin

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python-minimal \
        rsync \
        wait-for-it \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN \
    # Install Hadoop
    mkdir $HADOOP_HOME && \
    cd $HADOOP_HOME && \
    wget --progress=dot:giga https://archive.apache.org/dist/hadoop/core/hadoop-3.2.2/hadoop-3.2.2.tar.gz -O - | \
         tar -xz --strip-components=1 && \
    # Install Hive
    mkdir $HIVE_HOME && \
    cd $HIVE_HOME && \
    wget --progress=dot:giga https://archive.apache.org/dist/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz -O - | \
         tar -xz --strip-components=1 && \
    cd /tmp/ && \
    # Fix problem with incompatible Guava versions (see https://issues.apache.org/jira/browse/HIVE-22915)
    rm $HIVE_HOME/lib/guava-19.0.jar && \
    cp $HADOOP_HOME/share/hadoop/hdfs/lib/guava-27.0-jre.jar /opt/hive/lib/ && \
    # Install MySQL JDBC driver for Hive
    wget --progress=dot:giga https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.49.tar.gz -O - | \
         tar -xz --strip-components=1 && \
    cp mysql-connector-java-5.1.49.jar $HIVE_HOME/lib/mysql-connector-java.jar && \
    # Install Presto
    mkdir $PRESTO_HOME && \
    cd $PRESTO_HOME && \
    wget --progress=dot:giga https://repo1.maven.org/maven2/com/facebook/presto/presto-server/$PRESTO_VERSION/presto-server-$PRESTO_VERSION.tar.gz -O - | \
         tar -xz --strip-components=1 && \
    # Install Presto CLI
    wget --progress=dot:giga https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/$PRESTO_VERSION/presto-cli-$PRESTO_VERSION-executable.jar -O $PRESTO_HOME/bin/presto-cli && \
    chmod +x $PRESTO_HOME/bin/presto-cli

COPY hadoop/etc /opt/hadoop/etc
COPY hive/conf /opt/hive/conf
COPY presto/etc /opt/presto/etc
COPY scripts /scripts
COPY --from=namespace-manager-builder /presto/presto-function-namespace-managers/target/presto-function-namespace-managers-$PRESTO_VERSION/ /opt/presto/plugin/function-namespace-managers

RUN hdfs namenode -format && rm -rf /opt/hadoop/logs/*

ENTRYPOINT ["/scripts/entrypoint.sh"]
