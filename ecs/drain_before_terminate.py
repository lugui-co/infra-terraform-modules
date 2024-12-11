from json import loads, dumps
from time import sleep
from boto3 import client
from os import getenv

SLEEP_TIME = int(getenv("SLEEP_TIME")) if getenv("SLEEP_TIME") else 3

ECS = client("ecs")
ASG = client("autoscaling")

def find_ecs_instance_info(instance_id, CLUSTER):
    paginator = ECS.get_paginator("list_container_instances")

    for list_resp in paginator.paginate(cluster=CLUSTER):
        arns = list_resp["containerInstanceArns"]

        if arns is None or not arns or len(arns) == 0 or "*" in arns or "" in arns:
            break

        desc_resp = ECS.describe_container_instances(cluster=CLUSTER, containerInstances=arns)

        for container_instance in desc_resp["containerInstances"]:
            if container_instance["ec2InstanceId"] != instance_id:
                continue

            print(f"Encontrada instancia com {container_instance['runningTasksCount']} tasks rodando.", flush=True)

            return container_instance["containerInstanceArn"], container_instance["status"], container_instance["runningTasksCount"]

    print("Nenhuma instancia rodando", flush=True)

    return None, None, 0

def lambda_handler(event, context):
    msg = loads(event["Records"][0]["Sns"]["Message"])

    try:
        instance_id = msg["EC2InstanceId"]

    except KeyError:
        print(f"Instancia nao encontrada. Nao veio o id da instancia na mensagem do lambda. saindo.", flush=True)

        return

    clustername = msg["NotificationMetadata"]

    lifecycle_hook = msg["LifecycleHookName"]

    asg_name = msg["AutoScalingGroupName"]

    while True:
        instance_arn, container_status, running_tasks = find_ecs_instance_info(instance_id, clustername)

        if instance_arn is None or container_status is None or running_tasks == 0:
            print("Nada rodando. completando o life cycle", flush=True)

            try:
                ASG.complete_lifecycle_action(LifecycleHookName=lifecycle_hook, AutoScalingGroupName=asg_name, LifecycleActionResult="CONTINUE", InstanceId=instance_id)

                print("ciclo completado. encerrando...", flush=True)

            except Exception as err:
                print(f"complete life cycle deu erro:\n{err}\nNinguem rodando quando fui chamada?", flush=True)

            return

        else:
            if container_status != "DRAINING":
                print(f"instancia e {container_status} mudando para DRAINING", flush=True)

                ECS.update_container_instances_state(cluster=clustername, containerInstances=[instance_arn], status="DRAINING")

                sleep(SLEEP_TIME)