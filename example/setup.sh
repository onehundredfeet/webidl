#!/bin/sh
ARCH=x86_64
#ARCH=arm64
PROJECT=sample
BUILDER="make"
TARGET=hl
#TARGET=jvm
CONFIG=Debug

if [ ${BUILDER} = "make" ]; then
    BUILDER="Unix Makefiles"
fi

if [ ${BUILDER} = "ninja" ]; then
    BUILDER="Ninja"
fi

while getopts p:b:c:a:t: flag
do
    case "${flag}" in
        p) PROJECT=${OPTARG};;
        b) BUILDER=${OPTARG};;
        c) CONFIG=${OPTARG};;
        a) ARCH=${OPTARG};;
        t) TARGET=${OPTARG};;
    esac
done




mkdir -p build/${TARGET}/${ARCH}/${CONFIG}
mkdir -p installed/${TARGET}/${ARCH}/${CONFIG}

mkdir -p build/${TARGET}/${ARCH}/${CONFIG}
pushd build/${TARGET}/${ARCH}/${CONFIG}
cmake -G"${BUILDER}" -DTARGET_ARCH=${ARCH} -DTARGET_HOST=${TARGET} -DCMAKE_BUILD_TYPE=${CONFIG} -DCMAKE_INSTALL_PREFIX=../../../../installed/${TARGET}/${ARCH}/${CONFIG} ../../../.. 
popd

