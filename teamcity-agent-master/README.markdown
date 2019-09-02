Teamcity Agent
==============

## TeamCity Builds
This repo is automatically built by TeamCity whenever a new change is created.

See The [TeamCity project](https://teamcity.mesosphere.io/project.html?projectId=SecureAcl_TeamCity&tab=projectOverview) for builds.

## Details

Ubuntu Installer script for OVH and Packer configuration to create TeamCity build agent AMIs.

https://www.packer.io/

To upload the installer script for use in OVH:

    aws --region us-east-1 --profile production s3 cp install.bash $(cat ovh-installer-bucket)

The path name is used in the OVH installer profile. Since the file is public it's crucial to keep the URL secret.




## Windows Agent

#### Resources
1. https://github.com/oerazo/packer-windows-ami
2. https://david-obrien.net/2016/12/packer-and-aws-windows-server-2016/
3. https://docs.python.org/3.5/using/windows.html
