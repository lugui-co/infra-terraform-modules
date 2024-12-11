if [ -x "$(command -v apk)" ]; then
    docker pull public.ecr.aws/lambda/python:3.8

    docker tag public.ecr.aws/lambda/python:3.8 ${ECR_REGISTRY_ADDRESS}:latest

    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY_ADDRESS}

    docker push ${ECR_REGISTRY_ADDRESS}:latest

    docker logout ${ECR_REGISTRY_ADDRESS}

else
    sudo docker pull public.ecr.aws/lambda/python:3.8

    sudo docker tag public.ecr.aws/lambda/python:3.8 ${ECR_REGISTRY_ADDRESS}:latest

    aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REGISTRY_ADDRESS}

    sudo docker push ${ECR_REGISTRY_ADDRESS}:latest

    sudo docker logout ${ECR_REGISTRY_ADDRESS}
fi