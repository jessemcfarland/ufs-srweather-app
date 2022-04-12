#!/usr/bin/env bash
set -e -u -x

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

declare workspace
if [[ -n "${WORKSPACE}" ]]; then
    workspace="${WORKSPACE}"
else
    workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

[[ -s "${workspace}/bin/ufs_model" ]] || [[ -s "${workspace}/bin/NEMS.exe" ]]
