Changelog
=========
- 2019-06-13: teamcity-agent-* files
  - Updated the names of the teamcity-agents files reflecting the Teamcity Accounts.
  - Remove oracle-java8-installer as it is no longer supported.
- 2018-05-21: mesosphere-teamcity-agent
  - Update docker version from 17.05.0 to 18.03.1-ce (2018-04-26)
- 2017-12-12: mesosphere-teamcity-agent
  - Update docker version from 1.12.3 to 17.05.0
- 2015-05-21: mesosphere-teamcity-agent-15
  - Update docker version from 1.5.0 to 1.6.2
  - Update to Ubuntu 14.04.2 HVM SSD AMI ami-76b2a71e (release: 20150506)
  - Image built with Packer 0.7.5
  - Make sure noninteractive is set for apt operations, to prevent prompts from
    breaking the Packer build
- 2015-04-03: mesosphere-teamcity-agent-14
  - Add pxz and remake
  - Add Maven 3.2.x
  - Add Protobuf Compiler 2.5.0
- 2015-03-27: mesosphere-teamcity-agent-11
  - Updated to Ubuntu 14.04.2 HVM SSD AMI ami-d05e75b8 (release: 20150325)
  - Auto-mount second ephemeral disk on /teamcity
  - Use teamcity mount for teamcity working state
- 2015-03-03: mesosphere-teamcity-agent-9
  - Added python3, pip3, and tox to default build
- 2015-02-27: mesosphere-teamcity-agent-8
  - Updated to Ubuntu 14.04.2 HVM SSD AMI ami-1ac79a72 (release: 20150225.2)
  - Enabled AUFS support with linux-image-extras and aufs-tools package
  - Configure docker to use ephemeral /mnt partition for storage
