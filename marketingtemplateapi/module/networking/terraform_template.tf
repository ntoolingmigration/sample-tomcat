{
  "data": {
    "aws_availability_zones": {
      "available": {}
    }
  },
  "output": {
    "aws_alb_target_group_app": {
      "value": "${aws_alb_target_group.app.id}"
    },
    "aws_security_group_ecs_tasks": {
      "value": "${aws_security_group.ecs_tasks.id}"
    },
    "aws_subnet_private_ids": {
      "value": "${aws_subnet.private.*.id}"
    },
    "vpc_main": {
      "value": "${aws_vpc.main.id}"
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
    "aws_alb": {
      "main": {
        "name": "marketingtemplateapi-sg",
        "security_groups": [
          "${aws_security_group.lb.id}"
        ],
        "subnets": [
          "${aws_subnet.public.*.id}"
        ]
      }
    },
    "aws_alb_listener": {
      "front_end": {
        "default_action": [
          {
            "target_group_arn": "${aws_alb_target_group.app.id}",
            "type": "forward"
          }
        ],
        "load_balancer_arn": "${aws_alb.main.id}",
        "port": "${var.alb_port}",
        "protocol": "HTTP"
      }
    },
    "aws_alb_target_group": {
      "app": {
        "name": "marketingtemplateapi-tg",
        "port": "${var.alb_port}",
        "protocol": "HTTP",
        "target_type": "ip",
        "vpc_id": "${aws_vpc.main.id}"
      }
    },
    "aws_eip": {
      "gw": {
        "count": "${var.az_count}",
        "depends_on": [
          "aws_internet_gateway.gw"
        ],
        "vpc": true
      }
    },
    "aws_internet_gateway": {
      "gw": {
        "vpc_id": "${aws_vpc.main.id}"
      }
    },
    "aws_nat_gateway": {
      "gw": {
        "allocation_id": "${element(aws_eip.gw.*.id, count.index)}",
        "count": "${var.az_count}",
        "subnet_id": "${element(aws_subnet.public.*.id, count.index)}"
      }
    },
    "aws_route": {
      "internet_access": {
        "destination_cidr_block": "0.0.0.0/0",
        "gateway_id": "${aws_internet_gateway.gw.id}",
        "route_table_id": "${aws_vpc.main.main_route_table_id}"
      }
    },
    "aws_route_table": {
      "private": {
        "count": "${var.az_count}",
        "route": [
          {
            "cidr_block": "0.0.0.0/0",
            "nat_gateway_id": "${element(aws_nat_gateway.gw.*.id, count.index)}"
          }
        ],
        "vpc_id": "${aws_vpc.main.id}"
      }
    },
    "aws_route_table_association": {
      "private": {
        "count": "${var.az_count}",
        "route_table_id": "${element(aws_route_table.private.*.id, count.index)}",
        "subnet_id": "${element(aws_subnet.private.*.id, count.index)}"
      }
    },
    "aws_security_group": {
      "ecs_tasks": {
        "description": "allow inbound access from the ALB only",
        "egress": [
          {
            "cidr_blocks": [
              "0.0.0.0/0"
            ],
            "from_port": 0,
            "protocol": "-1",
            "to_port": 0
          }
        ],
        "ingress": [
          {
            "from_port": "${var.app_port}",
            "protocol": "tcp",
            "security_groups": [
              "${aws_security_group.lb.id}"
            ],
            "to_port": "${var.app_port}"
          }
        ],
        "name": "marketingtemplateapi-task",
        "vpc_id": "${aws_vpc.main.id}"
      },
      "lb": {
        "description": "controls access to the ALB",
        "egress": [
          {
            "cidr_blocks": [
              "0.0.0.0/0"
            ],
            "from_port": 0,
            "protocol": "-1",
            "to_port": 0
          }
        ],
        "ingress": [
          {
            "cidr_blocks": [
              "0.0.0.0/0"
            ],
            "from_port": 80,
            "protocol": "tcp",
            "to_port": 80
          }
        ],
        "name": "marketingtemplateapi-sg",
        "vpc_id": "${aws_vpc.main.id}"
      }
    },
    "aws_subnet": {
      "private": {
        "availability_zone": "${data.aws_availability_zones.available.names[count.index]}",
        "cidr_block": "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}",
        "count": "${var.az_count}",
        "vpc_id": "${aws_vpc.main.id}"
      },
      "public": {
        "availability_zone": "${data.aws_availability_zones.available.names[count.index]}",
        "cidr_block": "${cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)}",
        "count": "${var.az_count}",
        "map_public_ip_on_launch": true,
        "vpc_id": "${aws_vpc.main.id}"
      }
    },
    "aws_vpc": {
      "main": {
        "cidr_block": "${var.cidr_block}"
      }
    }
  },
  "terraform": {
    "backend": {
      "s3": {
        "bucket": "marketingtemplateapi-s3-bucket",
        "key": "networking/terraform.tfstate",
        "region": "us-east-1"
      }
    }
  },
  "variable": {
    "access_key": {
      "description": "Provider AWS Access Key"
    },
    "alb_port": {
      "default": 80,
      "description": "ALB Port"
    },
    "app_port": {
      "default": 8080,
      "description": "Port exposed by the docker image to redirect traffic to"
    },
    "az_count": {
      "default": 2,
      "description": "Number of AZs to cover in a given AWS region"
    },
    "cidr_block": {
      "default": "172.17.0.0/16",
      "description": "Classless Inter-Domain Routing Subnet"
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