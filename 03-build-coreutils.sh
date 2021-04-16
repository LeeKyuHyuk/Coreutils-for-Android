#!/bin/bash
#
# Linux Tools for Android coreutils build script
# Optional parameteres below:
set -o nounset
set -o errexit

export LC_ALL=POSIX
export PARALLEL_JOBS=`cat /proc/cpuinfo | grep cores | wc -l`
export CONFIG_TARGET="arm-linux-musleabi"
export CONFIG_HOST=`echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/'`
export CONFIG_LINUX_ARCH="arm"

export WORKSPACE_DIR=$PWD
export SOURCES_DIR=$WORKSPACE_DIR/sources
export OUTPUT_DIR=$WORKSPACE_DIR/out
export BUILD_DIR=$OUTPUT_DIR/build
export TOOLS_DIR=$OUTPUT_DIR/tools
export SYSROOT_DIR=$TOOLS_DIR/$CONFIG_TARGET/sysroot
export ANDROID_TOOLS_DIR=$OUTPUT_DIR/android-tools

export CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc"
export CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++"
export AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar"
export AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as"
export LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld"
export RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib"
export READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf"
export STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip"
export PATH="$TOOLS_DIR/bin:$TOOLS_DIR/sbin:$PATH"

# End of optional parameters

function step() {
  echo -e "\e[7m\e[1m>>> $1\e[0m"
}

function success() {
  echo -e "\e[1m\e[32m$1\e[0m"
}

function error() {
  echo -e "\e[1m\e[31m$1\e[0m"
}

function extract() {
  case $1 in
    *.tgz) tar -zxf $1 -C $2 ;;
    *.tar.gz) tar -zxf $1 -C $2 ;;
    *.tar.bz2) tar -jxf $1 -C $2 ;;
    *.tar.xz) tar -Jxf $1 -C $2 ;;
  esac
}

function check_environment {
  if ! [[ -d $SOURCES_DIR ]] ; then
    error "Please download tarball files!"
    error "Run './01-download-packages.sh'"
    exit 1
  fi
}

function check_tarballs {
    LIST_OF_TARBALLS="
      coreutils-8.32.tar.xz
    "

    for tarball in $LIST_OF_TARBALLS ; do
        if ! [[ -f $SOURCES_DIR/$tarball ]] ; then
            error "Can't find '$tarball'!"
            exit 1
        fi
    done
}

function timer {
  if [[ $# -eq 0 ]]; then
    echo $(date '+%s')
  else
    local stime=$1
    etime=$(date '+%s')
    if [[ -z "$stime" ]]; then stime=$etime; fi
    dt=$((etime - stime))
    ds=$((dt % 60))
    dm=$(((dt / 60) % 60))
    dh=$((dt / 3600))
    printf '%02d:%02d:%02d' $dh $dm $ds
  fi
}

check_environment
check_tarballs
total_build_time=$(timer)

rm -rf $BUILD_DIR $ANDROID_TOOLS_DIR
mkdir -pv $BUILD_DIR $ANDROID_TOOLS_DIR

step "[1/1] Coreutils 8.32"
extract $SOURCES_DIR/coreutils-8.32.tar.xz $BUILD_DIR
( cd $BUILD_DIR/coreutils-8.32 && \
    ac_cv_lbl_unaligned_fail=yes \
    ac_cv_func_mmap_fixed_mapped=yes \
    ac_cv_func_memcmp_working=yes \
    ac_cv_have_decl_malloc=yes \
    gl_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_calloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes \
    lt_cv_sys_lib_search_path_spec="" \
    ac_cv_c_bigendian=no \
    CONFIG_SITE=/dev/null \
    MAKEINFO=true \
    ./configure \
    --target=$CONFIG_TARGET \
  	--host=$CONFIG_TARGET \
  	--build=$CONFIG_HOST \
  	--prefix=/coreutils \
  	--enable-static \
  	--disable-shared \
  	--enable-no-install-program=kill,uptime)
make -j$PARALLEL_JOBS SHARED=0 CFLAGS='-static -std=gnu99 -static-libgcc -static-libstdc++ -fPIC' -C $BUILD_DIR/coreutils-8.32
make -j$PARALLEL_JOBS DESTDIR=$ANDROID_TOOLS_DIR install -C $BUILD_DIR/coreutils-8.32
rm -rf $BUILD_DIR/coreutils-8.32

success "\nTotal Coreutils build time: $(timer $total_build_time)\n"
