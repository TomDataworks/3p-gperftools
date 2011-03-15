#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

PROJECT="google-perftools"
VERSION="1.7"
SOURCE_DIR="$PROJECT-$VERSION"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)/stage"
pushd "$SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            load_vsvars
            #build_sln "google-perftools.sln" "Debug|Win32" "zlibstat"
            #build_sln "google-perftools.sln" "Release|Win32" "zlibstat"
            
            build_sln "google-perftools.sln" "Debug|Win32"
            build_sln "google-perftools.sln" "Release|Win32"

            mkdir -p "$stage/lib/debug"
            mkdir -p "$stage/lib/release"

            cp "contrib/vstudio/vc10/x86/ZlibStatDebug/zlibstat.lib" \
                "$stage/lib/debug/zlibd.lib"
            cp "contrib/vstudio/vc10/x86/ZlibStatRelease/zlibstat.lib" \
                "$stage/lib/release/zlib.lib"
            mkdir -p "$stage/include/zlib"
            cp {zlib.h,zconf.h} "$stage/include/zlib"
        ;;
        "darwin")
        ;;
        "linux")
            CFLAGS="-m32" CXXFLAGS="-m32" ./configure --prefix="$stage"
            make
            make install
            pushd "$stage"
                mv lib release
                mkdir -p lib
                mv release lib
            popd
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp COPYING  "$stage/LICENSES/$PROJECT.txt"
popd

pass

