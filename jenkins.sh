#!/bin/bash

set -eux
#
# Собирает DEB-пакет VisitorCounter с детектором голов
#
# Окружение:
#   BRANCH - ветка, из которой собирается само приложение.

BRANCH=${BRANCH:-}
if [ "${BRANCH}" == "master" ]; then
    BRANCH=""
fi

BUILD_NUMBER=${BUILD_NUMBER:-"1"}

# Проверка определения переменной ${BUILD_TYPE}, если не задана, то устанавливаем значение release.
BUILD_TYPE=${BUILD_TYPE:-"release"}
BUILD_TYPE=${1:-${BUILD_TYPE}}


CWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "${CWD}"

PACKAGE_DIR="${CWD}/package"
SOURCE_DIR="${CWD}"


# Считываем метаданные приложения
# NAME, VERSION, DESCRIPTION
source "${SOURCE_DIR}/metadata.sh"

build() {
    echo "Building ${NAME} module..."
    cd "${SOURCE_DIR}"
    rm -rf build
    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
    make -j$(nproc)
       
    echo "Building ${NAME} module... OK"
}

build

rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Versioning is in format 'VERSION~BRANCH-REVISION'.
# Branch comes after the tilde `~` symbol, so '1.0~my_experiment' comes before '1.0'.
# Revision comes after the last hyphen.

PACKAGE_VERSION="$VERSION"
if [ -n "${BRANCH}" ]; then
    PACKAGE_VERSION="${PACKAGE_VERSION}~${BRANCH}"
fi

PACKAGE_NAME="ivideon-${NAME}"
PACKAGE_NAME_DEV="ivideon-${NAME}-dev"


# make main package
rm -rf "${SOURCE_DIR}/tmp"
mkdir -p "${SOURCE_DIR}/tmp"
cp -P "${SOURCE_DIR}"/build/*.so "${SOURCE_DIR}/tmp/"

fpm -f \
    -t deb \
    -s dir \
    -C "${CWD}/tmp" \
    --name "${PACKAGE_NAME}" \
    --version "${PACKAGE_VERSION}" \
    --description "${DESCRIPTION}" \
    --iteration "${BUILD_NUMBER}" \
    --prefix "/usr/local/lib" \
    --after-install "${CWD}/after-install.sh" \
    -p "${PACKAGE_DIR}"
    
rm -rf "${CWD}"/tmp
mkdir -p "${SOURCE_DIR}/tmp"
mkdir -p "${SOURCE_DIR}/tmp/share/tkDNN"
cp -P -r "${SOURCE_DIR}/cmake" "${SOURCE_DIR}/tmp/share/tkDNN/"
cp -P -r "${SOURCE_DIR}/include" "${SOURCE_DIR}/tmp/"

fpm -f \
    -t deb \
    -s dir \
    -C "${CWD}/tmp" \
    --name "${PACKAGE_NAME_DEV}" \
    --version "${PACKAGE_VERSION}" \
    --description "${DESCRIPTION}" \
    --iteration "${BUILD_NUMBER}" \
    --prefix "/usr/local" \
    -p "${PACKAGE_DIR}" \
    --depends "${PACKAGE_NAME}"    
    
rm -rf "${CWD}"/tmp
