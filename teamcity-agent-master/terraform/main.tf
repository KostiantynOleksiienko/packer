# To add a new account, login to find out its profile id:

#   ➜  ~ maws login "Team 01"
#   retrieved credentials writing to profile 586712400841_Mesosphere-PowerUser
#   export AWS_PROFILE=586712400841_Mesosphere-PowerUser
#   ➜  ~ 

# Then add a provider and module instance like you see below.

# ToolsInfra AWS account.

provider "aws" {
  alias = "testinfra"
  region = "us-west-2"
}

module "agent-roles-testinfra" {
  source = "./agent-roles"

  providers = {
    aws = "aws.testinfra"
  }
}

# Team 01 AWS account.

provider "aws" {
  alias = "team01"
  region = "us-west-2"
  profile = "586712400841_Mesosphere-PowerUser"
}

module "agent-roles-team01" {
  source = "./agent-roles"

  providers = {
    aws = "aws.team01"
  }
}
