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
ARG QBT_VERSION="latest"
ARG BOOST_VERSION_MAJOR="1"
ARG BOOST_VERSION_MINOR="86"
ARG BOOST_VERSION_PATCH="0"
ARG LIBBT_CMAKE_FLAGS=""

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
    zlib-dev

# Set compiler and linker options for security and performance
ENV CFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS" \
    CXXFLAGS="-pipe -fstack-clash-protection -fstack-protector-strong -fno-plt -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS" \
    LDFLAGS="-gz -Wl,-O1,--as-needed,--sort-common,-z,now,-z,pack-relative-relocs,-z,relro"

# Step 3: Prepare and build Boost
RUN \
  wget -O boost.tar.gz "https://archives.boost.io/release/$BOOST_VERSION_MAJOR.$BOOST_VERSION_MINOR.$BOOST_VERSION_PATCH/source/boost_${BOOST_VERSION_MAJOR}_${BOOST_VERSION_MINOR}_${BOOST_VERSION_PATCH}.tar.gz" && \
  tar -xf boost.tar.gz && \
  mv boost_* boost

# Step 4: Clone and build custom libtorrent
RUN \
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
    -Ddeprecated-functions=OFF \
    $LIBBT_CMAKE_FLAGS && \
  cmake --build build -j $(nproc) && \
  cmake --install build

# Step 5: Clone and build qBittorrent
RUN \
  if [ "${QBT_VERSION}" = "devel" ]; then \
    git clone \
      --depth 1 \
      --recurse-submodules \
      https://github.com/qbittorrent/qBittorrent.git && \
    cd qBittorrent ; \
  else \
    wget "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-${QBT_VERSION}.tar.gz" && \
    tar -xf "release-${QBT_VERSION}.tar.gz" && \
    cd "qBittorrent-release-${QBT_VERSION}" ; \
  fi && \
  cmake \
    -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DBOOST_ROOT=/boost \
    -DGUI=OFF && \
  cmake --build build -j $(nproc) && \
  cmake --install build

# Verify qBittorrent binary
RUN ldd /usr/bin/qbittorrent-nox | sort -f

# Step 6: Create Software Bill of Materials (SBOM)
RUN \
  printf "Software Bill of Materials for building qbittorrent-nox\n\n" >> /sbom.txt && \
  echo "Boost $BOOST_VERSION_MAJOR.$BOOST_VERSION_MINOR.$BOOST_VERSION_PATCH" >> /sbom.txt && \
  cd libtorrent && \
  echo "libtorrent-rasterbar git $(git rev-parse HEAD)" >> /sbom.txt && \
  cd .. && \
  echo "qBittorrent ${QBT_VERSION}" >> /sbom.txt && \
  echo >> /sbom.txt && \
  apk list -I | sort >> /sbom.txt && \
  cat /sbom.txt

# Step 7: Runtime image
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

# Set the entrypoint
ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
