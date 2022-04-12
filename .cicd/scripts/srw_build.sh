#!/usr/bin/env bash
set -e -u -x

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

declare workspace
if [[ -n "${WORKSPACE}" ]]; then
    workspace="${WORKSPACE}"
else
    workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

build_dir="${workspace}/build"

source "${workspace}/etc/lmod-setup.sh" "${SRW_PLATFORM}"

module use "${workspace}/modulefiles"
module load "build_${SRW_PLATFORM}_${SRW_COMPILER}"

mkdir "${build_dir}"
pushd "${build_dir}"
    cmake -DCMAKE_INSTALL_PREFIX="${workspace}" "${workspace}"
    make -j "${MAKE_JOBS}"
popd
