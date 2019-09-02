resource "aws_iam_policy" "integration-testing" {
  name        = "DCOSIntegrationTests"
  path        = "/"
  description = "Allows TeamCity agents to run integration tests."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DCOSIntegrationTests",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "ec2:*",
                "elasticloadbalancing:*",
                "cloudwatch:*",
                "autoscaling:*",
                "iam:*",
                "s3:*",
                "cloudformation:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "teamcity-agent" {
  name = "teamcity-agent"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "teamcity-agent" {
    name       = "teamcity-agent"
    roles      = ["${aws_iam_role.teamcity-agent.name}"]
    policy_arn = "${aws_iam_policy.integration-testing.arn}"
}
