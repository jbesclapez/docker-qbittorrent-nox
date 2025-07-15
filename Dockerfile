# Step 1: Create an up-to-date base image for dependencies
FROM alpine:latest AS base

RUN \
  apk --no-cache --update-cache upgrade && \
  apk --no-cache add \
    7zip \
    bash \
    curl \
    doas \
    libcrypto3 \
    libssl3 \
    python3 \
    qt6-qtbase \
    qt6-qtbase-sqlite \
    tini \
    tzdata \
    zlib

# Step 2: Image for building qBittorrent and libtorrent
FROM base AS builder

# Define build arguments for qBittorrent and Boost versions
ARG QBT_VERSION="5.1.2"
ARG QBT_TAG="release-5.1.2"
ARG BOOST_VERSION_MAJOR="1"
ARG BOOST_VERSION_MINOR="86"
ARG BOOST_VERSION_PATCH="0"
ARG LIBTORRENT_ARTIFACT_URL=""
ARG GHOSTRACKERS_VERSION="5.1.2"

# Check environment variables
RUN \
  if [ -z "${QBT_VERSION}" ]; then \
    echo 'Error: Missing QBT_VERSION variable. Check your build arguments.' && \
    exit 1 ; \
  fi

# Install build dependencies
RUN \
  apk add --no-cache \
    cmake \
    git \
    g++ \
    make \
    ninja \
    openssl-dev \
    qt6-qtbase-dev \
    qt6-qttools-dev \
    qt6-qtbase-private-dev \
    pkgconfig \
    zlib-dev \
    sed \
    unzip \
    wget \
    github-cli

# Set compiler and linker options for security and performance
ENV CFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS" \
    CXXFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS" \
    LDFLAGS="-gz -Wl,-O1,--as-needed,--sort-common,-z,now,-z,pack-relative-relocs,-z,relro"

# Step 3: Prepare and build Boost
RUN \
  wget -O boost.tar.gz "https://archives.boost.io/release/$BOOST_VERSION_MAJOR.$BOOST_VERSION_MINOR.$BOOST_VERSION_PATCH/source/boost_${BOOST_VERSION_MAJOR}_${BOOST_VERSION_MINOR}_${BOOST_VERSION_PATCH}.tar.gz" && \
  tar -xf boost.tar.gz && \
  mv boost_* boost

# Copy the artifact download script
COPY scripts/download-libtorrent-artifacts.sh /tmp/download-libtorrent-artifacts.sh
RUN chmod +x /tmp/download-libtorrent-artifacts.sh

# Step 3.5: Fix Qt6 private headers path issue
RUN \
  # Create missing Qt6 directories and fix paths
  QT6_VERSION=$(pkg-config --modversion Qt6Core 2>/dev/null || echo "6.8.3") && \
  echo "Qt6 version detected: $QT6_VERSION" && \
  mkdir -p "/usr/include/qt6/QtCore/${QT6_VERSION}" && \
  if [ -d "/usr/include/qt6/QtCore" ] && [ ! -d "/usr/include/qt6/QtCore/${QT6_VERSION}/QtCore" ]; then \
    cp -r /usr/include/qt6/QtCore/* "/usr/include/qt6/QtCore/${QT6_VERSION}/" 2>/dev/null || true ; \
  fi && \
  # Create symlinks for Qt6 compatibility
  ln -sf /usr/include/qt6/QtCore "/usr/include/qt6/QtCore/${QT6_VERSION}/QtCore" 2>/dev/null || true

# Step 4: Download and install pre-built GhostTrackers libtorrent
RUN \
  if [ -n "${LIBTORRENT_ARTIFACT_URL}" ] && [ "${LIBTORRENT_ARTIFACT_URL}" != "" ]; then \
    echo "Attempting to download pre-built GhostTrackers libtorrent from: ${LIBTORRENT_ARTIFACT_URL}" && \
    cd /tmp && \
    if /tmp/download-libtorrent-artifacts.sh "${LIBTORRENT_ARTIFACT_URL}" "/usr"; then \
      echo "✅ Successfully installed pre-built GhostTrackers libtorrent" ; \
    else \
      echo "⚠️  Artifact download failed, falling back to building from source" && \
      cd / && \
      git clone \
        --branch "GhostTrackers" \
        --depth 1 \
        --recurse-submodules \
        https://github.com/jbesclapez/libtorrent.git && \
      cd libtorrent && \
      cmake \
        -B build \
        -G Ninja \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_CXX_STANDARD=20 \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
        -DBOOST_ROOT=/boost \
        -Ddeprecated-functions=OFF && \
      cmake --build build -j $(nproc) && \
      cmake --install build ; \
    fi ; \
  else \
    echo "No artifact URL provided, building GhostTrackers libtorrent from source" && \
    git clone \
      --branch "GhostTrackers" \
      --depth 1 \
      --recurse-submodules \
      https://github.com/jbesclapez/libtorrent.git && \
    cd libtorrent && \
    cmake \
      -B build \
      -G Ninja \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_CXX_STANDARD=20 \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
      -DBOOST_ROOT=/boost \
      -Ddeprecated-functions=OFF && \
    cmake --build build -j $(nproc) && \
    cmake --install build ; \
  fi

# Step 5: Download and patch qBittorrent source
RUN \
  if [ "${QBT_VERSION}" = "devel" ]; then \
    git clone \
      --depth 1 \
      --recurse-submodules \
      https://github.com/qbittorrent/qBittorrent.git && \
    cd qBittorrent ; \
  else \
    wget "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/${QBT_TAG}.tar.gz" && \
    tar -xf "${QBT_TAG}.tar.gz" && \
    cd "qBittorrent-${QBT_TAG}" ; \
  fi

# Step 6: Patch qBittorrent to show GhostTrackers version
RUN \
  if [ "${QBT_VERSION}" = "devel" ]; then \
    cd qBittorrent ; \
  else \
    cd "qBittorrent-${QBT_TAG}" ; \
  fi && \
  # Patch the version string to include GhostTrackers
  if [ -f "src/base/version.h.in" ]; then \
    sed -i 's/@PROJECT_VERSION@/@PROJECT_VERSION@ GhostTrackers/g' src/base/version.h.in ; \
  fi && \
  # Patch CMakeLists.txt to set a custom version string
  if [ -f "CMakeLists.txt" ]; then \
    sed -i '/project(qbittorrent/a set(PROJECT_VERSION "${PROJECT_VERSION} GhostTrackers")' CMakeLists.txt ; \
  fi && \
  # Alternative: patch the about dialog directly if version.h.in doesn't work
  if [ -f "src/gui/aboutdialog.cpp" ]; then \
    sed -i 's/QBT_VERSION/QBT_VERSION " GhostTrackers"/g' src/gui/aboutdialog.cpp 2>/dev/null || true ; \
  fi && \
  # Patch webui version display
  if [ -f "src/webui/api/appcontroller.cpp" ]; then \
    sed -i 's/QBT_VERSION/QBT_VERSION " GhostTrackers"/g' src/webui/api/appcontroller.cpp 2>/dev/null || true ; \
  fi && \
  # Add libtorrent version information
  echo "Patching completed for version ${GHOSTRACKERS_VERSION} GhostTrackers"

# Step 7: Build qBittorrent
RUN \
  if [ "${QBT_VERSION}" = "devel" ]; then \
    cd qBittorrent ; \
  else \
    cd "qBittorrent-${QBT_TAG}" ; \
  fi && \
  cmake \
    -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DBOOST_ROOT=/boost \
    -DGUI=OFF \
    -DCMAKE_PREFIX_PATH=/usr/lib/qt6 \
    -DQT_FEATURE_private_tests=OFF \
    -Wno-dev && \
  cmake --build build -j $(nproc) && \
  cmake --install build

# Verify qBittorrent binary
RUN ldd /usr/bin/qbittorrent-nox | sort -f

# Step 8: Create Software Bill of Materials (SBOM)
RUN \
  printf "Software Bill of Materials for qbittorrent-nox GhostTrackers\n\n" >> /sbom.txt && \
  echo "Boost $BOOST_VERSION_MAJOR.$BOOST_VERSION_MINOR.$BOOST_VERSION_PATCH" >> /sbom.txt && \
  cd libtorrent && \
  echo "libtorrent-rasterbar GhostTrackers $(git rev-parse HEAD)" >> /sbom.txt && \
  cd .. && \
  echo "qBittorrent ${QBT_VERSION} GhostTrackers" >> /sbom.txt && \
  echo "Build Date: $(date -u)" >> /sbom.txt && \
  echo >> /sbom.txt && \
  apk list -I | sort >> /sbom.txt && \
  cat /sbom.txt

# Step 9: Runtime image
FROM base

# Create a non-root user for qBittorrent
RUN \
  adduser \
    -D \
    -H \
    -s /sbin/nologin \
    -u 1000 \
    qbtUser && \
  echo "permit nopass :root" >> "/etc/doas.d/doas.conf"

# Copy qBittorrent binary and SBOM
COPY --from=builder /usr/bin/qbittorrent-nox /usr/bin/qbittorrent-nox
COPY --from=builder /sbom.txt /sbom.txt

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Add labels for better identification
LABEL org.opencontainers.image.title="qBittorrent-nox GhostTrackers" \
      org.opencontainers.image.description="qBittorrent-nox with GhostTrackers libtorrent - stealth torrent client" \
      org.opencontainers.image.vendor="GhostTrackers" \
      qbittorrent.variant="ghostrackers" \
      libtorrent.variant="ghostrackers"

# Set the entrypoint
ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
