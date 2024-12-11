variable "cluster_name" {
    type = string
    description = "nome do cluster de ecs. os servicos descritos no objeto services serao executados nele"
}

variable "vpc_id" {
    type = string
    description = "o id da vpc para os servicos no cluster"
}

variable "container_insights" {
    type = bool
    default = false
    description = "liga o container insights em todo o cluster do ecs"
}

variable "services" {
    description = "um objeto contendo os parametros dos servicos que o cluster vai rodar"
}

# exemplo da variavel services
# [
#     {
#         "name" = "crud de dados"
#         "task_definition" = "algum path aqui" // ou null
#         "iam_policy" = "algum path aqui" // ou null
#         "memory" = 10240
#         "cpu" = 4096
#         "subnet_ids" = ["subnet 1", "subnet_2", ...]
#         "public_ip" = false // ou null
#         "security_group_ids" = ["sg_1", "sg_2", ...] // ou null
#         "no_spot" = false // ou null
#         "no_fargate" = false // ou null
#         start_time = 5
#         stop_time = 5
#         health_check_grace_period_seconds = 0
#         network_mode = "awsvpc"
#         ephemeral_storage = 20
#         entryPoint = ["sh", "-c"] // ou null. padrao e null (o padrao da imagem)
#         command = ["sleep", "10"] // ou null. padrao e null (o padrao da imagem)
#         volumes =[
#             {
#                 host: "um path"
#                 container: "outro path"
#                 efs_id: "id do efs a ser atachado na tarefa" // ou null.
#                 iam: ENABLED ou DISABLED - para usar iam para acessar o efs. so necessario se for usar iam como autenticador com access point. // padrao DISABLED
#                 access_point_id: id do access point do efs caso use // padrao null
#             }, ...
#         ]
#         ec2 = { // ou null
#             "ami" = "codigo da ami aqui. opcional. vai vir a ami de ecs se n botar"
#             "instance_type" = "que tipo de instancia vc quer. tipo. t2.nano"
#             "user_data" = "o user data para rodar na instancia. melhor nao mudar"
#             "ebs_optimized" = true
#             "http_endpoint" = "endpoint de infos da ec2. nao muda se vc n sabe o que esta fazendo. O ecs precisa para se alistar no cluster (default enabled)"
#             "http_tokens" = "pedir por token de acesso para o endpoint de infos da ec2. nao muda se vc n sabe o que esta fazendo. (default required)"
#             "desired_capacity" = 1
#             "min_size" = 1
#             "max_size" = 1
#         }
#         "load_balancers" = false # ou null
#             ou ainda:
#            "load_balancers" = {
#                "certificate" = "arn do certificado aqui"
#                "certificate_policy" = "nome da politica"
#                "subnets" = ["sn-1", ...]
#                "security_groups" = ["sg-1", ...] // ou null. nao usar se for network
#                "internal" = false ou null
#                "idle_timeout" = 60
#                "port" = porta que da listen no servico
#                "target_port" = porta para o servico mesmo da port se null
#                "type" = "application" || "network" default to application
#                   "health_check" = {
#                         enabled = true
#                         healthy_threshold = 3
#                         interval = 300
#                         matcher = "200-299"
#                         path = "/"
#                         port = 80
#                         timeout = 10
#                         unhealthy_threshold = 3
#                   }
#            }
#         "discovery_service" = true // ou null
#         "environment_variables" = [ // ou null
#             {
#                 "name": "AWS_DEFAULT_REGION",
#                 "value": "${REGION}"
#             }
#             ],
#         "secrets": [{ // ou null
#             "name": "secret_variable_name",
#             "valueFrom": "arn:aws:ssm:region:acount:parameter/parameter_name",
#             "kmsKey": "and da chave no kms" // ou null
#          }],
#         "resource_requirements": [ // ou null
#             {
#                 "type": "GPU",
#                 "value": "1"
#             }
#         ]
#         ports = [1,2,3...] // ou null
#         image = "blah:latest" // ou null
#         security_options = { // deixa null
#             privileged = false
#             read_only = true
#             docker_security_options = ["no-new-privileges"]
#             linux_parameters= {
#                 "capabilities": {
#                         "drop": ["ALL"]
#                     }
#             }
#         }
#     }
# ]

variable "tags" {
    default     = {}
    type        = map(string)
    description = "tags adicionais para o ecs"
}

data "aws_region" "region" {}

data "aws_caller_identity" "current" {}

locals {
    servicos_na_ec2 = [for services in var.services : services if can(services.ec2)]
    servicos_com_alb = [for services in var.services : services if can(services.load_balancers)]
    servicos_com_https_no_alb = [for servico in local.servicos_com_alb : servico if can(servico.load_balancers.certificate)]
    servicos_com_discovery = [for services in var.services : services if try(services.discovery_service, false) == true]
    servicos_com_sg_interno = [for services in var.services : services if !can(services.security_group_ids)]
    servicos_com_repositorio = [for services in var.services : services if !can(services.image)]
}