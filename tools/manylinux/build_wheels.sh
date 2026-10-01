#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
build_dir=${BUILD_DIR:-"$repo_root/build/manylinux_2_28-cp312"}
install_dir=${INSTALL_DIR:-"$repo_root/inst/manylinux_2_28-cp312"}
wheel_dir=${WHEEL_DIR:-"$build_dir/wheelhouse"}
python=${PYTHON:-python}
cmake=${CMAKE_COMMAND:-cmake}
ctest=${CTEST_COMMAND:-ctest}
jobs=${CMAKE_BUILD_PARALLEL_LEVEL:-$(nproc)}

"$cmake" -S "$repo_root/SuperProject" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX="$install_dir" \
    -DVSP_NO_GRAPHICS=ON \
    -DVSP_NO_HELP=ON \
    -DVSP_NO_DOC=ON \
    -DVSP_NO_PYDOC=ON \
    -DVSP_NO_VSPAERO=OFF \
    -DVSP_NO_API_WRAPPERS=OFF \
    -DPYTHON_EXECUTABLE="$python"

"$cmake" --build "$build_dir" --target OpenVSP --parallel "$jobs"

"$ctest" \
    --test-dir "$build_dir/OpenVSP-prefix/src/OpenVSP-build" \
    -R '^VsploadsControlSurface$' \
    --output-on-failure

rm -rf "$wheel_dir/raw" "$wheel_dir/final" "$wheel_dir/smoke"
mkdir -p "$wheel_dir/raw" "$wheel_dir/final" "$wheel_dir/smoke"

for package in degen_geom openvsp_config utilities openvsp; do
    "$python" -m pip wheel \
        --no-deps \
        --no-build-isolation \
        --wheel-dir "$wheel_dir/raw" \
        "$install_dir/python/$package"
done

cp "$wheel_dir/raw"/degen_geom-*.whl "$wheel_dir/final/"
cp "$wheel_dir/raw"/openvsp_config-*.whl "$wheel_dir/final/"
cp "$wheel_dir/raw"/utilities-*.whl "$wheel_dir/final/"
auditwheel repair \
    --plat manylinux_2_28_x86_64 \
    --wheel-dir "$wheel_dir/final" \
    "$wheel_dir/raw"/openvsp-*.whl

"$python" -m pip install \
    --no-index \
    --no-deps \
    --target "$wheel_dir/smoke" \
    "$wheel_dir/final"/*.whl

PYTHONPATH="$wheel_dir/smoke${PYTHONPATH:+:$PYTHONPATH}" "$python" - <<'PY'
from pathlib import Path

import openvsp_config

openvsp_config._IGNORE_IMPORTS = True
import openvsp

assert openvsp.GetVSPVersion()
package_dir = Path(openvsp.__file__).parent
for executable in ("vspaero", "vspaero_opt", "vsploads"):
    assert (package_dir / executable).is_file()
print(f"{openvsp.GetVSPVersion()} wheel import succeeded")
PY

auditwheel show "$wheel_dir/final"/openvsp-*.whl
sha256sum "$wheel_dir/final"/*.whl
