provider "aws" {
  region = "us-west-2"  # Update with your desired region
}

resource "aws_instance" "example_instance" {
  ami           = "ami-0c94855ba95c71c99"  # Update with your desired AMI ID
  instance_type = "t2.micro"                # Update with your desired instance type

  tags = {
    Name = "example-instance"
  }
}

resource "aws_ssm_maintenance_window" "example_maintenance_window" {
  name               = "example-maintenance-window"
  allow_unassociated_targets = true
  duration           = 2
  cutoff             = 1
  schedule_timezone  = "UTC"
  schedule           = "cron(0 2 ? * SAT *)"  # Update with your desired maintenance window schedule
}

resource "aws_ssm_association" "example_drift_detection" {
  name = "example-drift-detection"
  instance_id = aws_instance.example_instance.id
  parameters = {
    AssociationId           = aws_ssm_association.example_drift_detection.id
    RuleSetName             = "aws-ec2-ami-ruleset"
    SnapshotOwner           = "self"
    RulesPackageArn         = "arn:aws:ssm:us-west-2::document/AWS-AMI-RULES"
    DocumentVersion         = "$DEFAULT"
    ScheduleExpression      = "cron(0 3 ? * SAT *)"  # Update with your desired drift detection schedule
    ScheduleTimezone        = "UTC"
    MaxConcurrency          = "1"
    MaxErrors               = "1"
    ComplianceSeverity      = "HIGH"
    WaitTimeForInstanceReady = "PT5M"
  }
  targets = [
    {
      key    = "WindowId"
      values = [aws_ssm_maintenance_window.example_maintenance_window.id]
    }
  ]
}

data "aws_ssm_parameter" "example_qualys_script" {
  name = "/qualys/script"
}

resource "aws_ssm_document" "example_qualys_script" {
  name          = "example-qualys-script"
  document_type = "Command"
  content       = data.aws_ssm_parameter.example_qualys_script.value
}

resource "aws_ssm_association" "example_qualys_script" {
  name = "example-qualys-script"
  instance_id = aws_instance.example_instance.id
  parameters = {
    commands            = [
      aws_ssm_document.example_qualys_script.name,
    ]
    executionTimeout    = ["3600"]
    outputS3BucketName  = ["example-qualys-output-bucket"]
    outputS3KeyPrefix   = ["qualys-output/"]
    serviceRoleArn      = ["arn:aws:iam::123456789012:role/qualys-s3-role"]
    DocumentVersion     = ["$DEFAULT"]
    ScheduleExpression  = ["cron(0 4 ? * SAT *)"]  # Update with your desired Qualys scan schedule
    ScheduleTimezone    = ["UTC"]
    MaxConcurrency      = ["1"]
    MaxErrors           = ["1"]
    ComplianceSeverity  = ["HIGH"]
    TargetType          = ["INSTANCE"]
    AssociationId       = [aws_ssm_association.example_qualys_script.id]
  }
  targets = [
    {
      key    = "WindowId"
      values = [aws_ssm_maintenance_window.example_maintenance_window.id]
    }
  ]
}
