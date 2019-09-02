#!/bin/bash
set -euo pipefail

function _wget {
  wget --progress=dot -e dotbytes=1M $@
}

function installOracleJDK8 {(
  cd /opt
  _wget https://downloads.mesosphere.io/java/jdk-8u51-linux-x64.tar.gz
  tar xzf jdk-*-linux-x64.tar.gz
  rm jdk-*-linux-x64.tar.gz

  echo -E "env.JDK_18=$(find /opt/ -maxdepth 1 -name jdk1.8.0_\*)" >> /opt/teamcity-agent/conf/buildAgent.properties
  echo -E "env.JDK_18_x64=$(find /opt/ -maxdepth 1 -name jdk1.8.0_\*)" >> /opt/teamcity-agent/conf/buildAgent.properties

)}

function installTeamCityAgent {(
  mkdir /opt/teamcity-agent
  cd /opt/teamcity-agent
  _wget https://teamcity.mesosphere.io/update/buildAgent.zip
  unzip buildAgent.zip
  rm buildAgent.zip

  mkdir /teamcity
  sed 's/^serverUrl=.*/serverUrl=https:\/\/teamcity.mesosphere.io/' /opt/teamcity-agent/conf/buildAgent.dist.properties > /opt/teamcity-agent/conf/buildAgent.properties
  sed -i 's#^workDir=.*#workDir=/teamcity/work#' /opt/teamcity-agent/conf/buildAgent.properties
  sed -i 's#^tempDir=.*#tempDir=/teamcity/temp#' /opt/teamcity-agent/conf/buildAgent.properties
  sed -i 's#^systemDir=.*#systemDir=/teamcity/system#' /opt/teamcity-agent/conf/buildAgent.properties

  echo '' >> /opt/teamcity-agent/conf/buildAgent.properties
  echo -E "etc.issue=$(cat /etc/issue | tr '\n' ' ')" >> /opt/teamcity-agent/conf/buildAgent.properties
  chmod ug+x /opt/teamcity-agent/bin/*.sh

  cat > /etc/systemd/system/teamcity-agent.service <<EOF
[Unit]
Description=TeamCity Agent
After=network.target

[Service]
Environment=JAVA_HOME=/opt/jdk1.8.0_51
ExecStart=/opt/teamcity-agent/bin/agent.sh run
Restart=always
RestartSec=15
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

  chmod 0644 /etc/systemd/system/teamcity-agent.service
  systemctl enable teamcity-agent
)}

function moveCredentialFilesIntoPlace() {
  # The file provisioner provided by packer will only upload files as the user
  # that it uses to ssh to the box.  This means that the files can only be
  # written some place the current user can write to.
  # To work around this fact, the whole directory is uploaded into /tmp
  # and the files can then be moved into place by this script.
  # See https://github.com/mitchellh/packer/issues/1551 for details.

  mkdir -p /root/.m2
  mv /tmp/agent-fs/root/.m2/settings-security.xml /root/.m2/settings-security.xml
  echo -n -e "MVN_SETTINGS_SECURITY=mesosphere\n" >> /opt/teamcity-agent/conf/buildAgent.properties

  mv /tmp/agent-fs/root/.gnupg /root/.gnupg
  echo -n -e "GPG2_KEYS=marathon-client\n" >> /opt/teamcity-agent/conf/buildAgent.properties

  rm -rf /tmp/agent-fs

}

function chmodCredentialFiles() {

  ownAnd600 /root/.m2/settings-security.xml

  ownAnd600 /root/.gnupg
}

function addTeamcityIamProperty() {

  local role=${TEAMCITY_AGENT_IAM_ROLE:-""}
  if [ -n ${role} ]; then
    echo -E "IAM_ROLE=$role" >> /opt/teamcity-agent/conf/buildAgent.properties
  fi

}

function shouldInstallCredentials() {
  ${SHOULD_INSTALL_CREDENTIALS:-false}
}

function main {
  export DEBIAN_FRONTEND=noninteractive
  env | sort

  sed -i.bak -r 's/\/\/.*(archive|security).ubuntu.com/\/\/old-releases.ubuntu.com/g' /etc/apt/sources.list

  apt-get update
  apt-get install -y \
    git \
    gnupg2 \
    libcurl3 \
    liblz4-tool \
    lzop \
    python-pip \
    python3 \
    python3-pip \
    python3-venv \
    unzip

  installTeamCityAgent

  echo -n -e "GPG2=/usr/bin/gpg2\n" >> /opt/teamcity-agent/conf/buildAgent.properties

  apt-get autoremove -y

  installOracleJDK8
  shouldInstallCredentials && moveCredentialFilesIntoPlace && chmodCredentialFiles
  addTeamcityIamProperty

  echo "cat /opt/teamcity-agent/conf/buildAgent.properties"
  cat /opt/teamcity-agent/conf/buildAgent.properties
}

function ownAnd600() {
  # Own it all
  chown root:root -R "${1}"
  # set directories to 700
  find "${1}" -type d -exec chmod 0700 {} \;
  # set all files to 600
  find "${1}" -type f -exec chmod 0600 {} \;
}

main "$@"
