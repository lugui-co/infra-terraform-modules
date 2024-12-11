variable "lambda_repo" {
    description = "repositorio de onde baixar os arquivos do lambda"

    type = string
}

variable "image_uri" {
    type = string
    description = "url do repositorio de ecs para usar na lambda. se nao for dado, um sera criado com uma imagem temporaria"
    default = null
}

variable "temp_folder" {
    description = "pasta para guardar os arquivos do lambda se for buildar"

    type = string
    default = null
}

variable "policy_file" {
    # type = object({
    #     file_path = string
    #     arguments = object({})
    # })

    description = "um objeto contendo o arquivo com as politicas para o lambda e os argumentos para ele caso precise. note que o modulo ja tem algumas politicas padro para os lambdas."

    default = null
}

variable "role_file" {
    type = string
    description = "um path para o arquivo com a role para o lambda. se nao for setado, o padrao vai ser usado"
    default = null
}

variable "iam_prefix" {
    type = string
    description = "prefixo para as politicas das lambdas. em caso de nome grande de mais"
    default = null
}

variable "memory_size" {
    type = number
    description = "quantidade de memoria em Mb para o lambda. o numero de cores sobe junto com a memoria"
    default = 128
}

variable "timeout" {
    type = number
    description = "tiemout do lambda. confira se ele bate com timouts de outras aplicacoes que dependam do lambda (tipo api gateway)"
    default = 3
}

variable "layers" {
    type = list(string)
    description = "layers de dependencias."
    default = null
}

variable "function_name" {
    type = string
    description = "coloque um nome para o lambda. recomendo usar o mesmo nome do repositorio"
}

variable "description" {
    type = string
    default = null
    description = "descreva o que a funcao faz. vai aparecer na pagina da aws."
}

variable "handler" {
    type = string
    description = "o entrypoint para o lambda. precisa do arquivo e o nome da funcao"
    default = "main.aws_lambda_handler"
}

# use docker para rodar como docker
variable "runtime" {
    type = string
    description = "que linguagem e versao voc vai usar para rodar"
}

variable "subnet_ids" {
    type = list(string)
    description = "lista de ids da subnet. se for vazio, o lambda nao vai usar vpc nenhuma"
    default = []
}

variable "security_group_ids" {
    type = list(string)
    description = "lista de ids dos security groups. se nao for fornecido, o lambda nao vai usar vpc"
    default = []
}

variable "build_script" {
    type = string
    description = "coloque o nome do script de build para a sua funcao. o script precisa ficar na raiz do repositorio e ser executavel por POSIX shell. Ele recebe como primeiro argumento o path de onde esta o repo da funcao (o local.function_dir)"
    default = null
}

variable "venvs" {
    description = "variaveis de ambiente para o lambda"
    type = map(string)
    default = {}

# exemplo:
# {
#     TERRAFORM_ENVIRONMENT = terraform.workspace
#     SERVER_IP = var.server_ip
# }
}

variable "force_clone" {
    type = bool
    default = false
    description = "forca o clone do repositorio independente do resultado do trigger"
}

variable "force_build" {
    type = bool
    default = false
    description = "forca o build do lambda independente do resultado do trigger"
}

variable "no_clone" {
    type = bool
    default = false
    description = "transforma o clonner em um no-op"
}

variable "no_build" {
    type = bool
    default = false
    description = "transforma o builder em um no-op"
}

variable "branch" {
    type = string
    default = null
    description = "forca o clone a usar uma branch especifica para o repositorio do lambda, em vez de usar a que tiver o nome do workspace do terraform"
}

variable "on_failure_maximum_event_age_in_seconds" {
    type = number
    default = 60
    description = "tempo maximo de vida que o lambda vai manter os parametros de invocacao assincrona na fila"
}

variable "maximum_retry_attempts" {
    type = number
    default = 0
    description = "quantidade de vezes que o lambda vai reiniciar e executar de novo em caso de falha. cuidado: dependendo de onde a falha ocorra (fim do programa) e o que o lambda faca (tipo mexer numa api ou bd), isso pode causar bugs e estados inconsistentes na base de dados"
}

variable "on_failure_notify" {
    type = string
    default = null
    description = "arn do recurso que vai receber a notificacao se a invoacao assincrona do lambda falhar"
}

variable "on_success_notify" {
    type = string
    default = null
    description = "arn do recurso que vai receber a notificacao se a invoacao assincrona do lambda der certo"
}

variable "ephemeral_storage" {
    type = number
    default = null
    description = "quanto de armazenamento efemero na /tmp que o lambda vai ter."
}

variable "use_lambda_url" {
    type = bool
    default = false
    description = "cria uma lambda url com as configuracoes padrao"
}

variable "lambda_url_authorization_type" {
    type = string
    default = "NONE"
    description = "o autenticador da url de lambda. padrao nenhum. use AWS_IAM para usar o autenticador de iam."
}

variable "lambda_url_cors" {
    description = "objeto com parametros de cors. se nao for setado, fica sem."
    type = object({
        allow_credentials = optional(bool, true)
        allow_origins = optional(list(string), ["*"])
        allow_methods = optional(list(string), ["*"])
        allow_headers = optional(list(string), ["date", "keep-alive"])
        expose_headers = optional(list(string), ["keep-alive", "date"])
        max_age = optional(number, 86400)
    })

    default = null
}

variable "tags" {
    default     = {}
    type        = map(string)
    description = "tags adicionais para o lambda"
}

data "aws_region" "region" {}

data "aws_caller_identity" "account_id" {}

locals {
    temp_folder = var.temp_folder != null ? var.temp_folder : "${path.module}/tmp"

    function_folder = element(split(".git", element(split("/", var.lambda_repo), length(split("/", var.lambda_repo)) - 1)), 0)

    function_dir = "${local.temp_folder}/${local.function_folder}"

    policy_file = {
        file_path = try(var.policy_file.file_path, "${local.function_dir}/function_policy.json")
        arguments = try(var.policy_file.arguments, try(jsondecode(file("${local.function_dir}/function_policy_arguments.json")), {}))
    }

    force_clone = var.force_clone ? timestamp() : var.force_clone

    force_build = var.force_build ? timestamp() : var.force_build
}