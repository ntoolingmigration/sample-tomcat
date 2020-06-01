{
    "data": {
        "template_file": {
            "buildspec": {
                "template": "${file(\"./buildspec.yml\")}",
                "vars": [
                    {
                        "cluster_name": "${var.aws_ecs_cluster_name}",
                        "region": "${var.region}",
                        "repository_url": "${var.aws_ecr_repository}",
                        "security_group_ids": "[${var.aws_security_group_ecs_tasks}]",
                        "subnet_id": "${var.aws_subnet_private_ids}"
                    }
                ]
            },
            "codebuild_policy": {
                "template": "${file(\"./policies/codebuild_policy.json\")}",
                "vars": [
                    {
                        "aws_s3_bucket_arn": "${aws_s3_bucket.source.arn}"
                    }
                ]
            },
            "codepipeline_policy": {
                "template": "${file(\"./policies/codepipeline.json\")}",
                "vars": [
                    {
                        "aws_s3_bucket_arn": "${aws_s3_bucket.source.arn}"
                    }
                ]
            }
        }
    },
    "provider": {
        "aws": {
            "__DEFAULT__": {
                "access_key": "${var.access_key}",
                "region": "${var.region}",
                "secret_key": "${var.secret_key}"
            }
        }
    },
    "resource": {
        "aws_codebuild_project": {
            "nextgenapp_build": {
                "artifacts": [
                    {
                        "type": "CODEPIPELINE"
                    }
                ],
                "build_timeout": "20",
                "environment": [
                    {
                        "compute_type": "BUILD_GENERAL1_SMALL",
                        "image": "aws/codebuild/docker:1.12.1",
                        "privileged_mode": true,
                        "type": "LINUX_CONTAINER"
                    }
                ],
                "name": "marketingtemplateapi-cb",
                "service_role": "${aws_iam_role.codebuild_role.arn}",
                "source": [
                    {
                        "buildspec": "${data.template_file.buildspec.rendered}",
                        "type": "CODEPIPELINE"
                    }
                ]
            }
        },
        "aws_codepipeline": {
            "pipeline": {
                "artifact_store": [
                    {
                        "location": "${aws_s3_bucket.source.bucket}",
                        "type": "S3"
                    }
                ],
                "name": "marketingtemplateapi-pipeline",
                "role_arn": "${aws_iam_role.codepipeline_role.arn}",
                "stage": [
                    {
                        "action": {
                            "category": "Source",
                            "configuration": {
                                "Branch": "master",
                                "Owner": "${var.git_org}",
                                "Repo": "${var.git_project}"
                            },
                            "name": "Source",
                            "output_artifacts": [
                                "source"
                            ],
                            "owner": "ThirdParty",
                            "provider": "GitHub",
                            "version": "1"
                        },
                        "name": "Source"
                    },
                    {
                        "action": {
                            "category": "Build",
                            "configuration": {
                                "ProjectName": "marketingtemplateapi-cb"
                            },
                            "input_artifacts": [
                                "source"
                            ],
                            "name": "Build",
                            "output_artifacts": [
                                "imagedefinitions"
                            ],
                            "owner": "AWS",
                            "provider": "CodeBuild",
                            "version": "1"
                        },
                        "name": "Build"
                    },
                    {
                        "action": {
                            "category": "Deploy",
                            "configuration": {
                                "ClusterName": "${var.aws_ecs_cluster_name}",
                                "FileName": "imagedefinitions.json",
                                "ServiceName": "${var.aws_ecs_service_name}"
                            },
                            "input_artifacts": [
                                "imagedefinitions"
                            ],
                            "name": "Deploy",
                            "owner": "AWS",
                            "provider": "ECS",
                            "version": "1"
                        },
                        "name": "Production"
                    }
                ]
            }
        },
        "aws_iam_role": {
            "codebuild_role": {
                "assume_role_policy": "${file(\"./policies/codebuild_role.json\")}",
                "name": "marketingtemplateapi-cbr"
            },
            "codepipeline_role": {
                "assume_role_policy": "${file(\"./policies/codepipeline_role.json\")}",
                "name": "marketingtemplateapi-cpr"
            }
        },
        "aws_iam_role_policy": {
            "codebuild_policy": {
                "name": "marketingtemplateapi-cbp",
                "policy": "${data.template_file.codebuild_policy.rendered}",
                "role": "${aws_iam_role.codebuild_role.id}"
            },
            "codepipeline_policy": {
                "name": "marketingtemplateapi-cpp",
                "policy": "${data.template_file.codepipeline_policy.rendered}",
                "role": "${aws_iam_role.codepipeline_role.id}"
            }
        },
        "aws_s3_bucket": {
            "source": {
                "acl": "private",
                "bucket": "marketingtemplateapi-s3-bucket",
                "force_destroy": true
            }
        }
    },
    "terraform": {
        "backend": {
            "s3": {
                "bucket": "marketingtemplateapi-s3-bucket",
                "key": "pipeline/terraform.tfstate",
                "region": "us-east-1"
            }
        }
    },
    "variable": {
        "access_key": {
            "description": "Provider AWS Access Key"
        },
        "aws_ecr_repository": {
            "description": "AWS ECR One Repository Name"
        },
        "aws_ecs_cluster_name": {
            "default": "tf_aws_ecs-cluster",
            "description": "AWS ECS Cluster name"
        },
        "aws_ecs_service_name": {
            "default": "tf_aws_service",
            "description": "AWS ECS Service name"
        },
        "aws_security_group_ecs_tasks": {
            "description": "AWS Security Group ECS Tasks ID"
        },
        "aws_subnet_private_ids": {
            "description": "AWS Private Subnets"
        },
        "git_org": {
            "default": "icitv2",
            "description": "GIT URL Owner or Organization Name"
        },
        "git_project": {
            "default": "sample-jboss",
            "description": "GIT URL Project Name"
        },
        "region": {
            "default": "us-east-1",
            "description": "The AWS region to create things in."
        },
        "secret_key": {
            "description": "Provider AWS Secret Key"
        }
    }
}