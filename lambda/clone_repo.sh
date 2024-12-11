if [ ! -d "${TEMP_DIR}" ]; then
    mkdir -p "${TEMP_DIR}"
fi

cd "${TEMP_DIR}"

if [ ! -d "${FUNCTION_FOLDER}" ]; then
    git clone --recursive --single-branch --branch "${BRANCH_NAME}" "${GIT_REPO}"
fi

cd "${FUNCTION_FOLDER}"
git checkout "${BRANCH_NAME}"
git pull
git submodule sync
git submodule update --init