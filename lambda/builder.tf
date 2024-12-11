resource "null_resource" "cloner" {
    count = var.runtime == "docker" || var.no_clone ? 0 : 1

    provisioner "local-exec" {
        command = var.no_clone ? "ls" : templatefile("${path.module}/clone_repo.sh", {
            TEMP_DIR = local.temp_folder
            GIT_REPO = var.lambda_repo
            FUNCTION_FOLDER = local.function_folder
            BRANCH_NAME = var.branch == null ? terraform.workspace : var.branch
        })
    }

    triggers = {
        force_clone = local.force_clone

        file_exists = fileexists("${local.function_dir}/main.zip")
    }
}

resource "null_resource" "builder" {
    count = var.runtime == "docker" || var.no_build || var.no_clone ? 0 : 1

    depends_on = [
        null_resource.cloner
    ]

    provisioner "local-exec" {
        command = var.build_script == null ? templatefile("${path.module}/lambda_build.sh", {
            WORKING_DIR = local.function_dir
            RUNTIME = var.runtime
        }) : "sh ${local.function_dir}/${var.build_script} ${local.function_dir}"
    }

    triggers = {
        force_build = local.force_build
        file_exists = fileexists("${local.function_dir}/main.zip")
    }
}
