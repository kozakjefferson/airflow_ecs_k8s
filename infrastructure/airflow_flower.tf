resource "aws_security_group" "flower" {
    name = "${var.project_name}-${var.stage}-flower-sg"
    description = "Allow all inbound traffic for Flower"
    vpc_id = "${aws_vpc.vpc.id}"

    ingress {
        from_port = 5555
        to_port = 5555
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-${var.stage}-flower-sg"
    }
}


resource "aws_ecs_task_definition" "flower" {
  family = "${var.project_name}-${var.stage}-flower"
  network_mode = "awsvpc"
  execution_role_arn = "${aws_iam_role.ecs_task_iam_role.arn}"
  requires_compatibilities = ["FARGATE"]
  cpu = "512" # the valid CPU amount for 2 GB is from from 256 to 1024
  memory = "1024"
  container_definitions = <<EOF
[
  {
    "name": "airflow_flower",
    "image": ${aws_ecr_repository.docker_repository.repository_url}:${var.image_version} ,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5555,
        "hostPort": 5555
      }
    ],
    "command": [
        "flower"
    ],
    "environment": [
      {
        "name": "REDIS_HOST",
        "value": ${aws_elasticache_cluster.celery_backend.cache_nodes.0.address}
      },
      {
        "name": "REDIS_PORT",
        "value": "6379"
      },
      {
        "name": "POSTGRES_HOST",
        "value": ${aws_db_instance.metadata_db.address}
      },
      {
        "name": "POSTGRES_PORT",
        "value": "5432"
      },
      {
          "name": "POSTGRES_USER",
          "value": "airflow"
      },
      {
          "name": "POSTGRES_PASSWORD",
          "value": ${random_string.metadata_db_password.result}
      },
      {
          "name": "POSTGRES_DB",
          "value": "airflow"
      },
      {
        "name": "FERNET_KEY",
        "value": "dJVGvyvi36_C2Gx2rnyWDglYvdPmkoeUDl1GlcSvunE="
      },
      {
        "name": "AIRFLOW_BASE_URL",
        "value": "http://localhost:8080"
      },
      {
        "name": "ENABLE_REMOTE_LOGGING",
        "value": "False"
      },
      {
        "name": "STAGE",
        "value": "${var.stage}"
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${var.log_group_name}/${var.project_name}-${var.stage}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "flower"
        }
    }
  }
]
EOF
}
