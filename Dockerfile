FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install build-essential curl file git ruby-full locales --no-install-recommends -y && \
    rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -f UTF-8 en_US.UTF-8

RUN useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

USER linuxbrew
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"

USER root
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

RUN chmod -R 777 "/home/linuxbrew/.linuxbrew/bin"
RUN which brew

USER linuxbrew
RUN brew install swiftlint
RUN brew install sonar-scanner
RUN pip3 install mobsfscan --break-system-packages
RUN brew uninstall sonar-scanner

USER root
ARG SONAR_SCANNER_HOME=/opt/sonar-scanner
ARG SONAR_SCANNER_VERSION=5.0.1.3006
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    HOME=/tmp \
    XDG_CONFIG_HOME=/tmp \
    SONAR_SCANNER_HOME=${SONAR_SCANNER_HOME} \
    SONAR_USER_HOME=${SONAR_SCANNER_HOME}/.sonar \
    PATH=${SONAR_SCANNER_HOME}/bin:${PATH} \
    SRC_PATH=/usr/src \
    SCANNER_WORKDIR_PATH=/tmp/.scannerwork \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
RUN apt update
RUN apt install wget
WORKDIR /opt
RUN wget -U "scannercli" -q -O /opt/sonar-scanner-cli.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip;
RUN unzip sonar-scanner-cli.zip;
RUN mv sonar-scanner-${SONAR_SCANNER_VERSION} ${SONAR_SCANNER_HOME}; 
RUN apt install openjdk-17-jre -y
RUN mkdir -p "${SRC_PATH}" "${SONAR_USER_HOME}" "${SONAR_USER_HOME}/cache" "${SCANNER_WORKDIR_PATH}"; \
chown -R scanner-cli:scanner-cli "${SONAR_SCANNER_HOME}" "${SRC_PATH}" "${SCANNER_WORKDIR_PATH}"; \
chmod -R 555 "${SONAR_SCANNER_HOME}"; \
chmod -R 754 "${SRC_PATH}" "${SONAR_USER_HOME}" "${SCANNER_WORKDIR_PATH}";


COPY --chown=scanner-cli:scanner-cli bin /usr/bin/

VOLUME [ "/tmp/cacerts" ]

WORKDIR ${SRC_PATH}


ENTRYPOINT ["/usr/bin/entrypoint.sh"]

CMD ["sonar-scanner"]
