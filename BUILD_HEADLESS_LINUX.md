# Headless Linux x86_64 build

This recipe builds OpenVSP, its Python API, VSPAERO, and `vsploads` from source
without the GUI, help, or generated documentation. It uses the SuperProject so
the dependency versions shipped in `Libraries/` are built along with OpenVSP.
All generated files and the install prefix remain inside the checkout.

## Prerequisites

- A C++17 compiler with OpenMP support
- CMake 3.24 or newer and Ninja
- SWIG and Python development headers
- NumPy for the Python extension
- POSIX threads and `pkg-config`

The build was verified on x86_64 CentOS Stream 9 with GCC 11.5.0, OpenMP 4.5,
CMake 3.31.8, Ninja 1.13.2, SWIG 4.3.1, Python 3.12.14, and NumPy 2.5.3.
The Python API was also verified with Python 3.8.20 and NumPy 1.24.4.
OpenVSP and the SuperProject add `-fPIC` automatically on x86_64. STEPcode uses
its shipped lexer/parser sources, so `lemon`, Perplex, and re2c are not required.

An optional repository-local tool environment can provide everything except the
compiler and OpenMP runtime:

```bash
conda create --yes --prefix "$PWD/build/toolchain" --channel conda-forge \
    cmake=3.31.8 ninja=1.13.2 swig=4.3.1 python=3.12.14 numpy=2.5.3
```

For a Python 3.8 build, create the toolchain with:

```bash
conda create --yes --prefix "$PWD/build/toolchain-py38" --channel conda-forge \
    cmake=3.31.8 ninja=1.13.2 swig=4.3.1 python=3.8.20 numpy=1.24.4
```

Then use `build/toolchain-py38`, `build/headless-super-py38`, and `inst/headless-py38`
in place of `build/toolchain`, `build/headless-super`, and `inst/headless` in
the commands below.

## Configure and build

Run these commands from the repository root. Replace the compiler paths if a
different GCC installation is desired.

```bash
conda run --prefix "$PWD/build/toolchain" --no-capture-output cmake \
    -S SuperProject -B build/headless-super -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DCMAKE_INSTALL_PREFIX="$PWD/inst/headless" \
    -DVSP_NO_GRAPHICS=ON \
    -DVSP_NO_HELP=ON \
    -DVSP_NO_DOC=ON \
    -DVSP_NO_PYDOC=ON \
    -DVSP_NO_VSPAERO=OFF \
    -DVSP_NO_API_WRAPPERS=OFF \
    -DPYTHON_EXECUTABLE="$PWD/build/toolchain/bin/python"

conda run --prefix "$PWD/build/toolchain" --no-capture-output cmake \
    --build build/headless-super --target OpenVSP --parallel 24
```

The installed command-line artifacts are:

```text
inst/headless/vspscript
inst/headless/vspaero
inst/headless/vspaero_opt
inst/headless/vsploads
inst/headless/python/openvsp/openvsp/_vsp.so
```

The Python extension is built for the configured interpreter. A minimal import
from the install tree, without loading the optional plotting utilities, is:

```bash
PYTHONPATH="$PWD/inst/headless/python/openvsp:$PWD/inst/headless/python/openvsp_config" \
    "$PWD/build/toolchain/bin/python" -c \
    'import openvsp_config; openvsp_config._IGNORE_IMPORTS = True; import openvsp as vsp; print(vsp.GetVSPVersion()); print(vsp.GetVSPAEROPath())'
```

## Test

CTest files are in the nested OpenVSP build directory created by the
SuperProject. The `VsploadsControlSurface` regression generates control and
no-control models, runs one- and three-case steady VSPAERO sweeps, and slices
every case with the locally built `vsploads`:

```bash
conda run --prefix "$PWD/build/toolchain" --no-capture-output ctest \
    --test-dir build/headless-super/OpenVSP-prefix/src/OpenVSP-build \
    -R '^VsploadsControlSurface$' --output-on-failure
```
