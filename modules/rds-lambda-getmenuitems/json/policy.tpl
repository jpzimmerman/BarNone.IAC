{
  "Version": "2012-10-17",
  "Statement": [
      { 
          "Effect": "Allow", 
          "Action": [
            "rds-db:connect" 
          ],
          "Resource": [
            "${db-instance-arn}" 
          ] 
      },
      {
          "Effect": "Allow",
          "Action": [
              "rds:Describe*",
              "rds:ListTagsForResource",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeAvailabilityZones",
              "ec2:DescribeInternetGateways",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeSubnets",
              "ec2:DescribeVpcAttribute",
              "ec2:DescribeVpcs"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "cloudwatch:GetMetricStatistics",
              "cloudwatch:ListMetrics",
              "cloudwatch:GetMetricData",
              "logs:DescribeLogStreams",
              "logs:GetLogEvents",
              "devops-guru:GetResourceCollection"
          ],
          "Resource": "*"
      },
      {
          "Action": [
              "devops-guru:SearchInsights",
              "devops-guru:ListAnomaliesForInsight"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Condition": {
              "ForAllValues:StringEquals": {
                  "devops-guru:ServiceNames": [
                      "RDS"
                  ]
              },
              "Null": {
                  "devops-guru:ServiceNames": "false"
              }
          }
      },
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:CreateSecret"
        ],
        "Resource": "*"
      }
  ]
}