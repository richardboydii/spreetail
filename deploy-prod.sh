#!/usr/bin/env bash

JQ="jq --raw-output --exit-status"
ACCT="086911230249"
HASH="$CIRCLE_SHA1"
BRANCH="$CIRCLE_BRANCH"
SERVICE="spreetail-prod-service"
IMAGE="$ACCT.dkr.ecr.us-east-1.amazonaws.com/spreetail:latest"
TASK_ARN="arn:aws:iam::086911230249:role/SpreeTailEcsRole"
FAMILY="spreetail-prod"
CLUSTER="spreetail-demo"

configure_aws_cli(){
	aws --version
	aws configure set default.region us-east-1
	aws configure set default.output json
}

make_task_def(){
    echo "Creating Task Definition"
	TASK_TEMPLATE='[
        {
        "executionRoleArn": "arn:aws:iam::086911230249:role/ecsTaskExecutionRole",
        "containerDefinitions": [
            {
            "dnsSearchDomains": null,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                "awslogs-group": "/ecs/spreetail-prod",
                "awslogs-region": "us-east-1",
                "awslogs-stream-prefix": "ecs"
                }
            },
            "entryPoint": null,
            "portMappings": [
                {
                "hostPort": 5000,
                "protocol": "tcp",
                "containerPort": 5000
                }
            ],
            "command": null,
            "linuxParameters": null,
            "cpu": 0,
            "environment": [],
            "ulimits": null,
            "dnsServers": null,
            "mountPoints": [],
            "workingDirectory": null,
            "dockerSecurityOptions": null,
            "memory": null,
            "memoryReservation": null,
            "volumesFrom": [],
            "image": "%s",
            "disableNetworking": null,
            "healthCheck": null,
            "essential": true,
            "links": null,
            "hostname": null,
            "extraHosts": null,
            "user": null,
            "readonlyRootFilesystem": null,
            "dockerLabels": null,
            "privileged": null,
            "name": "spreetail"
            }
        ],
        "placementConstraints": [],
        "memory": "512",
        "taskRoleArn": "arn:aws:iam::086911230249:role/SpreeTailEcsRole",
        "compatibilities": [
            "EC2",
            "FARGATE"
        ],
        "taskDefinitionArn": "arn:aws:ecs:us-east-1:086911230249:task-definition/spreetail-prod:2",
        "family": "spreetail-prod",
        "requiresAttributes": [
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "ecs.capability.execution-role-ecr-pull"
            },
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.18"
            },
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "ecs.capability.task-eni"
            },
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.ecr-auth"
            },
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.task-iam-role"
            },
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "ecs.capability.execution-role-awslogs"
            },
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.logging-driver.awslogs"
            },
            {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.19"
            }
        ],
        "requiresCompatibilities": [
            "FARGATE"
        ],
        "networkMode": "awsvpc",
        "cpu": "256",
        "revision": 2,
        "status": "ACTIVE",
        "volumes": []
        }
	]'

	TASK_DEF=$(printf "$TASK_TEMPLATE" $IMAGE)

    printf '=%.0s' {1..40}
    echo
    echo $TASK_DEF | jq .
    printf '=%.0s' {1..40}
    echo
}

register_definition() {
    echo "Registering Definition"
    printf '=%.0s' {1..40}
    echo
    if REVISION=$(aws ecs register-task-definition --container-definitions "$TASK_DEF" --network-mode="bridge" --task-role-arn "$TASK_ARN" --family $FAMILY | $JQ '.taskDefinition.taskDefinitionArn'); then
        echo "Revision Number: $REVISION"
        printf '=%.0s' {1..40}
        echo
    else
        echo "Failed to register task definition"
        return 1
    fi
}

deploy_cluster() {
    echo "Updating Service"
    echo
    if [[ $(aws ecs update-service --cluster $CLUSTER --service $SERVICE --task-definition $REVISION | \
                $JQ '.service.taskDefinition') != $REVISION ]]; then
        echo "Error updating service."
        echo
        return 1
    fi
}

main(){
    configure_aws_cli
    make_task_def
    register_definition
    deploy_cluster
}

main
