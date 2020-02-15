resource "aws_security_group" "workers" {
    name = "${var.project_name}-${var.stage}-workers-sg"
    description = "Airflow Celery Workers security group"
    vpc_id = "${aws_vpc.vpc.id}"

    ingress {
        from_port = 8793
        to_port = 8793
        protocol = "tcp"
        cidr_blocks = ["${var.base_cidr_block}/16"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-${var.stage}-workers-sg"
    }
}


resource "aws_ecs_task_definition" "workers" {
  family = "${var.project_name}-${var.stage}-workers"
  network_mode = "awsvpc"
  execution_role_arn = "${aws_iam_role.ecs_task_iam_role.arn}"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "2048" # the valid CPU amount for 2 GB is from from 256 to 1024
  container_definitions = <<EOF
[
  {
    "name": "airflow_workers",
    "image": ${aws_ecr_repository.docker_repository.repository_url}:${var.image_version},
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8793,
        "hostPort": 8793
      }
    ],
    "command": [
        "worker"
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
            "awslogs-stream-prefix": "workers"
        }
    }
  }
]
EOF
}
