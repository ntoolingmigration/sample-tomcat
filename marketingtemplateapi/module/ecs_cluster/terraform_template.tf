{
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
    "aws_ecs_cluster": {
      "main": {
        "name": "${var.aws_ecs_cluster_name}"
      }
    },
    "aws_ecs_service": {
      "main": {
        "cluster": "${var.aws_ecs_cluster_name}",
        "desired_count": "${var.app_count}",
        "launch_type": "${var.ecs_service_launch_type}",
        "load_balancer": [
          {
            "container_name": "app",
            "container_port": "${var.app_port}",
            "target_group_arn": "${var.aws_alb_target_group_app}"
          }
        ],
        "name": "${var.aws_ecs_service_name}",
        "network_configuration": [
          {
            "security_groups": [
              "${var.aws_security_group_ecs_tasks}"
            ],
            "subnets": [
              "${var.aws_subnet_private_ids}"
            ]
          }
        ],
        "task_definition": "${aws_ecs_task_definition.app.arn}"
      }
    },
    "aws_ecs_task_definition": {
      "app": {
        "container_definitions": "${file(\"../networking/service_definition.json\")}",
        "cpu": "${var.fargate_cpu}",
        "execution_role_arn": "${var.ecs_task_execition_role}",
        "family": "app",
        "memory": "${var.fargate_memory}",
        "network_mode": "awsvpc",
        "requires_compatibilities": "${var.ecs_task_capabilities}"
      }
    }
  },
  "terraform": {
    "backend": {
      "s3": {
        "bucket": "marketingtemplateapi-s3-bucket",
        "key": "ecs/terraform.tfstate",
        "region": "us-east-1"
      }
    }
  },
  "variable": {
    "access_key": {
      "description": "Provider AWS Access Key"
    },
    "app_count": {
      "default": 1,
      "description": "Number of docker containers to run"
    },
    "app_port": {
      "default": 8080,
      "description": "Port exposed by the docker image to redirect traffic to"
    },
    "aws_alb_target_group_app": {
      "description": "AWS ALB Target Group APP"
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
      "description": "AWS Security Group ECS Tasks ID",
      "type": "list"
    },
    "aws_subnet_private_ids": {
      "description": "AWS Private Subnets",
      "type": "list"
    },
    "ecs_service_launch_type": {
      "default": "FARGATE",
      "description": "ECS Service Launch Type"
    },
    "ecs_task_capabilities": {
      "default": [
        "FARGATE"
      ],
      "description": "ECS Task Capabilities"
    },
    "ecs_task_execition_role": {
      "default": "arn:aws:iam::618217587453:role/ecsTaskExecutionRole",
      "description": "ECS Task Execution Role"
    },
    "fargate_cpu": {
      "default": 256,
      "description": "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
    },
    "fargate_memory": {
      "default": 512,
      "description": "Fargate instance memory to provision (in MiB)"
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