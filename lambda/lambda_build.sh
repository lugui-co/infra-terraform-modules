if [ -d "${WORKING_DIR}" ]; then
    cd "${WORKING_DIR}";

    if [ -d ./main.zip ]; then
        rm ./main.zip;
    fi

    if [ -d ./code_not_found.texto ]; then
        rm ./code_not_found.texto;
    fi

    if echo "${RUNTIME}" | grep -q "node"; then
        npm i --only=production;

    elif echo "${RUNTIME}" | grep -q "go"; then
        WORKING_DIR=".."

        mkdir -p .go;

        mkdir -p build;

        export GOPATH="$(pwd)/.go";

        export CGO_ENABLED=0;

        CGO_ENABLED=0 GOPATH="$(pwd)/.go" go mod download;

        CGO_ENABLED=0 GOPATH="$(pwd)/.go" go build -trimpath -ldflags="-s -w" -o ./build/main ./*.go;

        if [ -d ./assets ]; then
            cp -r ./assets/* ./build;
        fi

        cd build;

        touch .lambdaignore;

        7z a -mx=9 -mfb=64 -xr'@.lambdaignore' -xr'!.lambdaignore' -r main.zip .;

        mv ./main.zip ..;

        exit 0;

    elif echo "${RUNTIME}" | grep -q "python"; then
        if [ -d ./requirements.txt ]; then
            pip install --no-cache --target ./package -r ./requirements.txt;
        fi

    else
        echo "runtime nao reconhecido. fechando builder";
        exit 1;
    fi

else
    echo "-------------------------------------------";
    echo "diretorio nao encontrado: ${WORKING_DIR}";
    echo "confira se voce clonou ele e a branch alvo do CICD existe";
    echo "-------------------------------------------";
    mkdir -p "${WORKING_DIR}";
    cd "${WORKING_DIR}";
    echo "o repo nao foi encontrado. verifique se a branch para este ambiente esta criada." > code_not_found.texto;

fi

touch .lambdaignore;

7z a -mx=9 -mfb=64 -xr'@.lambdaignore' -xr'!.lambdaignore' -xr'!.*' -xr'!*.md' -xr'!*git*' -xr'!*.txt' -xr'!*.h' -xr'!*.hpp' -xr'!*.c' -xr'!*.cpp' -xr'!*.zip' -xr'!*.rar' -xr'!*.sh' -xr'!*.dist-info' -xr'!*.whl' -xr'!*/python/lib/python3.8/site-packages/bin/*' -xr'!*/python/lib/python3.8/site-packages/share/*' -xr'!*__pycache__*' -xr'!*.pyc' -xr'!*.pyo' -xr'!package.json' -xr'!package-lock.json' -xr'!*.go' -xr'!go.mod' -xr'!go.sum' -xr'!function_policy.json' -xr'!function_policy_arguments.json' -r main.zip .;