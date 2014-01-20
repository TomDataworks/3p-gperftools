#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

PROJECT="gperftools"
VERSION="2.1"
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
        "darwin")
            opts='-arch i386 -iwithsysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5'
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

