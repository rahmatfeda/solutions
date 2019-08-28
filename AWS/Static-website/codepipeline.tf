##provisioning CodeCommit Repo

resource "aws_codecommit_repository" "codecommit" {
  repository_name = "staticweb"
  
}



#provisioning CodePipeline

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "code-bucket"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_codepipeline" "codepipeline" {
    name     = "staticweb"
    role_arn = "${aws_iam_role.codepipeline_role.arn}"
    artifact_store {
    location = "${aws_s3_bucket.codepipeline_bucket.bucket}"
    type     = "S3"
    }

    stage {
        name = "Source"
        action {
            category         = "Source"
            configuration    = {
                "BranchName"           = "master"
                "PollForSourceChanges" = "false"
                "RepositoryName"       = "${aws_codecommit_repository.codecommit.id}"
            }
            input_artifacts  = []
            name             = "Source"
            output_artifacts = [
                "SourceArtifact",
            ]
            owner            = "SnapPay"
            provider         = "CodeCommit"
            version = 1
        }
        
    }
    stage {
        name = "Deploy"

        action {
            category         = "Deploy"
            configuration    = {
                "BucketName" = "${aws_s3_bucket.website.id}"
                "Extract"    = "true"
            }
            input_artifacts  = [
                "SourceArtifact",
            ]
            name             = "Deploy"
            output_artifacts = []
            owner            = "SnapPay"
            provider         = "S3"
            run_order        = 1
            version          = 1
        }
    }
    
}