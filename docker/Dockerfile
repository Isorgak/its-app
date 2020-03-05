ARG WILDFLY_VERSION=18.0.0.Final
FROM jboss/wildfly:${WILDFLY_VERSION}

ENV STAGING dev
ENV WILDFLY_CONFIG_FOLDER=wildfly/${WILDFLY_VERSION}
ENV CONFIG_DIR /opt/jboss/wildfly/standalone/configuration
ENV DEPLOY_DIR /opt/jboss/wildfly/standalone/deployments

USER root

ENV HTTP_PROXY http://kruemel.ic3s.de:3128
ENV HTTPS_PROXY http://kruemel.ic3s.de:3128
ENV http_proxy http://kruemel.ic3s.de:3128
ENV https_proxy http://kruemel.ic3s.de:3128

RUN yum -y install wget && \
    wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-12.noarch.rpm && \
    rpm -ivh epel-release-7-12.noarch.rpm && \
    yum -y install \
    fortune-mod \
    libfonts \
    openssl \
    roboto-fontface-fonts \
    stix-fonts \
    wine-ms-sans-serif-fonts \
    woff

USER jboss

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

COPY ${WILDFLY_CONFIG_FOLDER}/standalone.xml \
     ${CONFIG_DIR}/

ENV JAVA_OPTS -Djavax.net.ssl.trustStore=${CONFIG_DIR}/cacerts -Djavax.net.ssl.trustStorePassword=changeit -Xms64m -Xmx1024m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=512m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true

# Needed ports for web access and management
EXPOSE 9990
EXPOSE 4142
EXPOSE 8443
EXPOSE 8080

RUN /opt/jboss/wildfly/bin/add-user.sh admin its23863 --silent && \
    keytool -genkeypair -alias localhost -keyalg RSA -keysize 2048 -validity 365 -keystore ${CONFIG_DIR}/cacerts -keypass changeit -storepass changeit -dname "CN=Server Administrator,O=mdex GmbH,C=de" && \
    keytool -printcert -rfc -sslserver www.google.com/recaptcha/api/siteverify > ${CONFIG_DIR}/recaptcha.pem && \
    keytool -importcert -noprompt -alias www.google.com -file ${CONFIG_DIR}/recaptcha.pem -storepass changeit -keystore ${CONFIG_DIR}/cacerts && \
    keytool -importkeystore -srckeystore ${CONFIG_DIR}/cacerts -destkeystore ${CONFIG_DIR}/cacerts -deststoretype pkcs12

ENTRYPOINT \
    /opt/jboss/wildfly/bin/standalone.sh -c standalone-mdex.xml -b "0.0.0.0" -bmanagement "0.0.0.0" --debug", "*:4142" -Dee8.preview.mode=true -Dhttp.proxyHost="kruemel.ic3s.de" -Dhttp.proxyPort=3128 -Dhttp.nonProxyHosts="localhost|127.0.0.1|*.mdex.de|*.ic3s.de" -Dhttp.keepalive=false