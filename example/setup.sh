#!/bin/sh
ARCH=x86_64
#ARCH=arm64
PROJECT=sample
BUILDER="make"
TARGET=hl
#TARGET=jvm
CONFIG=Debug


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

GENERATOR=${BUILDER}

if [ ${BUILDER} = "make" ]; then
    GENERATOR="Unix Makefiles"
fi

if [ ${BUILDER} = "ninja" ]; then
    GENERATOR="Ninja"
fi



mkdir -p build/${TARGET}/${ARCH}/${CONFIG}
mkdir -p installed/${TARGET}/${ARCH}/${CONFIG}

mkdir -p build/${TARGET}/${ARCH}/${CONFIG}
pushd build/${TARGET}/${ARCH}/${CONFIG}
cmake -G"${GENERATOR}" -DTARGET_ARCH=${ARCH} -DTARGET_HOST=${TARGET} -DCMAKE_BUILD_TYPE=${CONFIG} -DCMAKE_INSTALL_PREFIX=../../../../installed/${TARGET}/${ARCH}/${CONFIG} ../../../.. 
popd

