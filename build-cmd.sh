#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

PROJECT="gperftools"
VERSION="2.4.6627f92"
SOURCE_DIR="$PROJECT"

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

echo "${VERSION}" > "${stage}/VERSION.txt"

pushd "$SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            load_vsvars
			
            build_sln "gperftools.sln" "Debug|Win32"
            build_sln "gperftools.sln" "Release|Win32"
			
            
            mkdir -p $stage/lib/release
            mkdir -p $stage/lib/debug
						
            cp Release/libtcmalloc_minimal.dll \
                $stage/lib/release
            cp Release/libtcmalloc_minimal.lib \
                $stage/lib/release

            cp Debug/libtcmalloc_minimal-debug.dll \
                $stage/lib/debug
            cp Debug/libtcmalloc_minimal-debug.lib \
                $stage/lib/debug
        ;;
        "windows64")
            load_vsvars
			
            build_sln "gperftools.sln" "Debug|x64"
            build_sln "gperftools.sln" "Release|x64"
			
            
            mkdir -p $stage/lib/release
            mkdir -p $stage/lib/debug
						
            cp x64/Release/libtcmalloc_minimal.dll \
                $stage/lib/release
            cp x64/Release/libtcmalloc_minimal.pdb \
                $stage/lib/release
            cp x64/Release/libtcmalloc_minimal.lib \
                $stage/lib/release

            cp x64/Debug/libtcmalloc_minimal-debug.dll \
                $stage/lib/debug
            cp x64/Debug/libtcmalloc_minimal.pdb \
                $stage/lib/debug
            cp x64/Debug/libtcmalloc_minimal-debug.lib \
                $stage/lib/debug
        ;;
        "darwin")
            DEVELOPER=$(xcode-select -print-path)
            opts='-arch i386 -arch x86_64 -iwithsysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk -mmacosx-version-min=10.7'
            export CFLAGS="$opts"
            export CXXFLAGS="$opts"
            export LDFLAGS="$opts"
            ./configure --prefix="$stage"
            make
            make install
            pushd "$stage"
                mv lib release
                mkdir -p lib
                mv release lib
                mkdir lib/debug
                mv lib/release/*debug* lib/debug
            popd
        ;;
        "linux")
            CFLAGS="-m32" CXXFLAGS="-m32" ./configure --prefix="$stage"
            make
            make install
            pushd "$stage"
                mv lib release
                mkdir -p lib
                mv release lib
                mkdir lib/debug
                mv lib/release/*debug* lib/debug
            popd
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp COPYING  "$stage/LICENSES/$PROJECT.txt"
popd

pass

