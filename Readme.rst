.. image:: docs/img/GhostTracker_logo.png
   :alt: GhostTracker Logo

.. image:: docs/img/GhostTracker.png
   :alt: GhostTracker Working Screenshot

=====================================
GhostTracker for qBittorrent-nox Docker Image
=====================================

.. image:: https://github.com/qbittorrent/docker-qbittorrent-nox/actions/workflows/release.yaml/badge.svg
   :target: https://github.com/qbittorrent/docker-qbittorrent-nox/actions

Repository on Docker Hub: https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox  
Repository on GitHub: https://github.com/qbittorrent/docker-qbittorrent-nox

This project builds a Docker image for `qBittorrent-nox` based on a custom version of libtorrent called `GhostTracker`. The custom libtorrent disables tracker reporting of uploads, downloads, and completion events while retaining full functionality for downloading torrents.

.. note::
   For more detailed information about qBittorrent's Docker images, visit the original repository:
   https://github.com/qbittorrent/docker-qbittorrent-nox

Supported Architectures
-----------------------
* linux/386
* linux/amd64
* linux/arm/v6
* linux/arm/v7
* linux/arm64/v8
* linux/riscv64

Reporting Bugs
--------------
* If the problem is related to Docker, report it to:
  https://github.com/qbittorrent/docker-qbittorrent-nox/issues
* If the problem is with qBittorrent itself, report it to:
  https://github.com/qbittorrent/qBittorrent/issues

Usage
-----

0. **Prerequisites**

   * Install Docker: https://docs.docker.com/get-docker/
   * Optionally, install Docker Compose: https://docs.docker.com/compose/install/

1. **Download the Repository**

   Clone this repository or download it as a `.zip`:
   https://github.com/qbittorrent/docker-qbittorrent-nox/archive/refs/heads/main.zip

2. **Edit the `.env` File**

   Open the `.env` file in the repository and configure the following variables:

   - ``QBT_LEGAL_NOTICE``: Confirm the legal notice (`confirm` to accept).
   - ``QBT_VERSION``: Specify the qBittorrent version (e.g., `5.0.3`).
   - ``QBT_WEBUI_PORT``: WebUI port (e.g., `8085`).
   - ``QBT_CONFIG_PATH``: Full path for storing qBittorrent configurations.
   - ``QBT_DOWNLOADS_PATH``: Full path for torrent downloads.
   - ``PUID``: User ID for the container.
   - ``PGID``: Group ID for the container.
   - ``TZ``: Time zone (e.g., `Europe/Paris`).

   .. tip::
      To find the correct ``PUID`` and ``PGID``:
      
      - SSH into your NAS or host machine.
      - Run: ``id <your-username>``
      - Example output: ``uid=1029(jbesclapez) gid=100(users)``
      - Use the UID value as ``PUID`` (e.g., `1029`) and GID value as ``PGID`` (e.g., `100`).

3. **Run the Image**

   - Using Docker Compose:
     .. code-block:: shell

        docker compose up -d

   - Using Docker CLI:
     .. code-block:: shell

        docker run \
          -t \
          --name qbittorrent-nox \
          --rm \
          --stop-timeout 1800 \
          -e QBT_LEGAL_NOTICE=confirm \
          -e QBT_VERSION=5.0.3 \
          -e QBT_WEBUI_PORT=8085 \
          -e TZ=Europe/Paris \
          -v /path/to/config:/config \
          -v /path/to/downloads:/downloads \
          -p 6881:6881/tcp \
          -p 6881:6881/udp \
          -p 8085:8085/tcp \
          qbittorrentofficial/qbittorrent-nox:5.0.3

4. **Access the WebUI**

   Open your browser and navigate to:
   ``http://<NAS-IP>:8085``

   - Default username: ``admin``
   - Password for qBittorrent >= 4.6.1:
     qBittorrent generates a temporary password and prints it to the logs. Run:
     .. code-block:: shell

        docker logs qbittorrent-nox

   - Change the password after logging in:
     Navigate to `Tools > Options... > Web UI > Authentication`.

5. **Stop the Container**

   - Using Docker Compose:
     .. code-block:: shell

        docker compose down

   - Using Docker CLI:
     .. code-block:: shell

        docker stop qbittorrent-nox

Manual Build
------------
Refer to the `manual_build` folder for detailed instructions:
https://github.com/qbittorrent/docker-qbittorrent-nox/tree/main/manual_build

Debugging
---------
To attach a debugger to the running process, follow these steps:

1. **Modify the Docker Compose File**:
   Remove the `read-only` mode and add `--cap-add=SYS_PTRACE`.

2. **Install Debugging Tools**:
   .. code-block:: shell

      docker exec -it <container-id> /bin/sh
      apk add gdb musl-dbg

3. **Attach gdb**:
   .. code-block:: shell

      ps -a  # Find the PID of qbittorrent-nox
      gdb -p <PID>
