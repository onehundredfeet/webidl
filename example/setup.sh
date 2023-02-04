#!/bin/sh
ARCH=x86_64
PROJECT=sample
BUILDER="make"
TARGET=hl
CONFIG=Debug

if [ ${BUILDER} = "make" ]; then
    BUILDER="Unix Makefiles"
fi

while getopts b:c:a:t: flag
do
    case "${flag}" in
        b) BUILDER=${OPTARG};;
        c) CONFIG=${OPTARG};;
        a) ARCH=${OPTARG};;
        t) TARGET=${OPTARG};;
    esac
done


#TARGET=jvm
#ARCH=arm64

mkdir -p build/${TARGET}/${ARCH}/${CONFIG}
mkdir -p installed/${TARGET}/${ARCH}/${CONFIG}

mkdir -p build/${TARGET}/${ARCH}/${CONFIG}
pushd build/${TARGET}/${ARCH}/${CONFIG}
cmake -G"${BUILDER}" -DTARGET_ARCH=${ARCH} -DTARGET_HOST=${TARGET} -DCMAKE_BUILD_TYPE=${CONFIG} -DCMAKE_INSTALL_PREFIX=../../../../installed/${TARGET}/${ARCH}/${CONFIG} ../../../.. 
popd

