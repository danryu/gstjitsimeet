#!/bin/bash
set -e

# Build script for gstjitsimeet plugin using static GStreamer
# Uses static GStreamer installation at /Users/dan/code/gstreamer-build/install
# Builds danryu/coop dependency first (macOS-aware fork)

echo "=================================================="
echo "Building gstjitsimeet Plugin"
echo "=================================================="

# Configuration
GSTREAMER_INSTALL="/Users/dan/code/gstreamer-build/install"
PROJECT_DIR="$(pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
DEPS_DIR="${PROJECT_DIR}/deps"
COOP_INSTALL="${DEPS_DIR}/coop-install"

echo "GStreamer installation: ${GSTREAMER_INSTALL}"
echo "Project directory: ${PROJECT_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Dependencies directory: ${DEPS_DIR}"
echo "Coop installation: ${COOP_INSTALL}"

# Step 1: Clone and build submod utility (danryu/submod - kdev branch)
echo ""
echo "Step 1: Setting up submod utility..."
mkdir -p "${DEPS_DIR}"
cd "${DEPS_DIR}"

if [ ! -d "submod" ]; then
    echo "Cloning danryu/submod (kdev branch)..."
    git clone -b kdev https://github.com/danryu/submod.git
else
    echo "submod directory already exists"
    cd submod
    git fetch origin
    git checkout kdev
    git pull
    cd ..
fi

echo "submod utility ready at: ${DEPS_DIR}/submod"

# Step 2: Build coop dependency (danryu/coop - kdev branch)
echo ""
echo "Step 2: Building coop dependency..."

if [ ! -d "coop" ]; then
    echo "Cloning danryu/coop (kdev branch)..."
    git clone -b kdev https://github.com/danryu/coop.git
else
    echo "coop directory already exists"
    cd coop
    git fetch origin
    git checkout kdev
    git pull
    cd ..
fi

cd coop
echo "Building coop (kdev branch)..."
if [ -d "build" ]; then
    rm -rf build
fi

meson setup build --prefix="${COOP_INSTALL}" --buildtype=release --default-library=static
ninja -C build
ninja -C build install

echo "coop built and installed to: ${COOP_INSTALL}"
cd "${PROJECT_DIR}"

# Step 3: Initialize gstjitsimeet submodules with submod
echo ""
echo "Step 3: Initializing gstjitsimeet submodules..."
"${DEPS_DIR}/submod/submod" clone

echo "Submodules initialized"

# Step 4: Verify GStreamer installation exists
echo ""
echo "Step 4: Verifying GStreamer installation..."
if [ ! -d "${GSTREAMER_INSTALL}" ]; then
    echo "ERROR: GStreamer installation not found at ${GSTREAMER_INSTALL}"
    exit 1
fi

if [ ! -f "${GSTREAMER_INSTALL}/lib/pkgconfig/gstreamer-1.0.pc" ]; then
    echo "ERROR: GStreamer pkg-config files not found"
    echo "Expected: ${GSTREAMER_INSTALL}/lib/pkgconfig/gstreamer-1.0.pc"
    exit 1
fi

echo "GStreamer installation verified"

# Step 5: Set up environment for static GStreamer and coop
echo ""
echo "Step 5: Setting up build environment..."
export PKG_CONFIG_PATH="${COOP_INSTALL}/lib/pkgconfig:${GSTREAMER_INSTALL}/lib/pkgconfig:${GSTREAMER_INSTALL}/lib/gstreamer-1.0/pkgconfig:${PKG_CONFIG_PATH}"
export PATH="${GSTREAMER_INSTALL}/bin:${PATH}"
export LD_LIBRARY_PATH="${GSTREAMER_INSTALL}/lib:${GSTREAMER_INSTALL}/lib/gstreamer-1.0:${LD_LIBRARY_PATH}"
export DYLD_LIBRARY_PATH="${GSTREAMER_INSTALL}/lib:${GSTREAMER_INSTALL}/lib/gstreamer-1.0:${DYLD_LIBRARY_PATH}"

echo "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"
echo "Verifying pkg-config can find dependencies..."
pkg-config --modversion gstreamer-1.0 || {
    echo "ERROR: pkg-config cannot find gstreamer-1.0"
    exit 1
}
echo "GStreamer version: $(pkg-config --modversion gstreamer-1.0)"

pkg-config --modversion coop || {
    echo "ERROR: pkg-config cannot find coop"
    exit 1
}
echo "coop version: $(pkg-config --modversion coop)"

# Step 6: Clean previous build if exists
echo ""
echo "Step 6: Cleaning previous build..."
if [ -d "${BUILD_DIR}" ]; then
    echo "Removing previous build directory..."
    rm -rf "${BUILD_DIR}"
fi

# Step 7: Configure with Meson
echo ""
echo "Step 7: Configuring build with Meson..."
meson setup "${BUILD_DIR}" \
    --prefix="${GSTREAMER_INSTALL}" \
    --buildtype=release \
    --default-library=static
    # --libdir=lib

echo ""
echo "Meson configuration complete"

# Step 8: Build the plugin
echo ""
echo "Step 8: Building gstjitsimeet plugin..."
ninja -C "${BUILD_DIR}"

echo ""
echo "Build completed successfully!"

# Step 9: Install the plugin
echo ""
echo "Step 9: Installing plugin to GStreamer plugin directory..."
ninja -C "${BUILD_DIR}" install

echo ""
echo "Installation complete!"

# Step 10: Verify the static library was built
echo ""
echo "Step 10: Verifying static library build..."
STATIC_LIB="${BUILD_DIR}/libgstjitsimeet.a"
if [ -f "${STATIC_LIB}" ]; then
    echo "Static library built successfully!"
    ls -lh "${STATIC_LIB}"
else
    echo "WARNING: Static library not found at expected location"
    echo "Checking build directory for library files..."
    find "${BUILD_DIR}" -name "libgstjitsimeet.*" -type f
fi

# Step 11: Show library info
echo ""
echo "Step 11: Static library information..."
if [ -f "${STATIC_LIB}" ]; then
    echo "Library size: $(ls -lh "${STATIC_LIB}" | awk '{print $5}')"
    echo "Library location: ${STATIC_LIB}"
    echo ""
    echo "Object files in library:"
    ar -t "${STATIC_LIB}" | head -n 10
    if [ $(ar -t "${STATIC_LIB}" | wc -l) -gt 10 ]; then
        echo "... (and $(expr $(ar -t "${STATIC_LIB}" | wc -l) - 10) more)"
    fi
fi

echo ""
echo "=================================================="
echo "BUILD SUCCESSFUL!"
echo "=================================================="
echo ""
echo "Static library built: ${BUILD_DIR}/libgstjitsimeet.a"
echo "Installed to: ${GSTREAMER_INSTALL}/lib/"
echo ""