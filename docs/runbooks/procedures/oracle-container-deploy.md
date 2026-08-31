# Procedure: Deploy Oracle Autonomous AI Database Free Container

## Purpose

Deploy the Oracle Autonomous AI Database Free container used as the management repository and APEX/ORDS platform for this project.

This procedure stops when Oracle is healthy and reachable. Project schema installation and validation are separate steps.

## Supported path

The documented reference path is:

- Ubuntu Server LTS;
- Docker Engine;
- Oracle Autonomous AI Database Free 26ai;
- an operator workstation with SQLcl and a browser.

The Ubuntu host may be a VM or physical system. The project does not depend on a particular hypervisor.

The runtime host does **not** need Git, SQLcl, VS Code, or the project repository. Those belong on the operator workstation.

```text
Operator workstation
Git / SQLcl / browser
        |
        v
Ubuntu Server LTS
        |
        v
Docker
        |
        v
Oracle ADB Free
Database + ORDS/APEX
```

Other Linux distributions may work, but Ubuntu Server LTS is the path documented and tested here.

## Guardrails

- Do not store passwords, wallets, certificates, or generated runtime data in Git.
- Do not use employer-derived hostnames, credentials, code, names, or data.
- Keep runtime state separate from source-controlled project files.
- Do not expose the container directly to the public Internet.
- Stop if required CPU, memory, storage, FUSE access, or container capabilities are unavailable.
- Treat the host as disposable. Do not turn it into a special system that can only be rebuilt from memory.

## Reference values

The project was validated with:

```text
IMAGE=ghcr.io/oracle/adb-free:latest-26ai
CONTAINER_NAME=oracle-estate-adb
WORKLOAD_TYPE=ATP
HOST_HTTPS_PORT=8443
HOST_DB_PORT=1521
VOLUME_NAME=oracle-estate-adb-data
```

`latest-26ai` is a convenient lab tag, not an immutable artifact. Oracle may update what that tag points to. Record the image actually used when repeatability across time matters.

The validated deployment uses an 8 GiB Docker memory ceiling. The host still needs enough additional memory for Ubuntu and normal operation.

The container requires:

- `/dev/fuse`;
- `SYS_ADMIN` capability;
- persistent storage for `/u01/data`;
- container port `1522` for database connectivity;
- container port `8443` for ORDS/APEX.

## 1. Verify the host

Confirm Ubuntu and Docker:

```bash
cat /etc/os-release
docker --version
docker info >/dev/null
```

Confirm available resources and FUSE:

```bash
free -h
nproc
ls -l /dev/fuse
```

Check the example host ports before using them:

```bash
ss -lnt | grep -E ':8443|:1521' || true
```

**PASS:** Ubuntu is available, Docker works, `/dev/fuse` exists, the host has reasonable capacity, and the selected ports are available or intentionally remapped.

**STOP:** Resolve the host or Docker problem before continuing. A broken Docker installation is not an Oracle Estate Operations deployment problem.

## 2. Create runtime secret storage

Choose a runtime path outside the Git working tree:

```bash
export LAB_ROOT=/opt/oracle-estate-lab
sudo mkdir -p "${LAB_ROOT}/secrets"
sudo chown "$(id -u):$(id -g)" "${LAB_ROOT}" "${LAB_ROOT}/secrets"
chmod 700 "${LAB_ROOT}/secrets"
```

The exact path is not important. The separation from source control is.

Create:

```text
${LAB_ROOT}/secrets/adb.env
```

with:

```text
ADMIN_PASSWORD=<strong-password>
WALLET_PASSWORD=<strong-password>
```

Protect it:

```bash
chmod 600 "${LAB_ROOT}/secrets/adb.env"
```

Oracle requires the ADMIN password to meet its current password policy. Use Oracle's current container documentation if that policy changes.

**PASS:** Secrets are available to Docker and remain outside source control.

**STOP:** Do not continue if credentials would be stored in the repository.

## 3. Pull the Oracle image

```bash
export IMAGE=ghcr.io/oracle/adb-free:latest-26ai
docker pull "${IMAGE}"
```

Confirm it is present:

```bash
docker images | grep adb-free
```

**PASS:** The image is present locally.

**STOP:** Do not continue if the image pull failed or the image source is unclear.

## 4. Prepare persistent storage

Create a Docker volume:

```bash
export VOLUME_NAME=oracle-estate-adb-data
docker volume create "${VOLUME_NAME}"
```

The validated 26ai image runs as UID/GID `1001:1001`. Confirm the image identity if needed:

```bash
docker run --rm --entrypoint id "${IMAGE}"
```

Prepare the volume for the Oracle user:

```bash
VOLUME_PATH=$(docker volume inspect "${VOLUME_NAME}" --format '{{ .Mountpoint }}')
sudo chown -R 1001:1001 "${VOLUME_PATH}"
ls -ld "${VOLUME_PATH}"
```

Use numeric IDs. Host account and group names do not need to match the container.

**PASS:** The volume exists and is writable by the Oracle container user.

**STOP:** Do not continue if `/u01/data` will not be writable.

## 5. Start the container

```bash
export CONTAINER_NAME=oracle-estate-adb
export WORKLOAD_TYPE=ATP
export HOST_DB_PORT=1521
export HOST_HTTPS_PORT=8443

docker run -d \
  --name "${CONTAINER_NAME}" \
  --memory=8g \
  --env-file "${LAB_ROOT}/secrets/adb.env" \
  -e WORKLOAD_TYPE="${WORKLOAD_TYPE}" \
  -p "${HOST_DB_PORT}:1522" \
  -p "${HOST_HTTPS_PORT}:8443" \
  --cap-add SYS_ADMIN \
  --device /dev/fuse \
  --volume "${VOLUME_NAME}:/u01/data" \
  "${IMAGE}"
```

The image also supports other interfaces, including a Mongo-compatible API. V1 does not use them, so do not expose extra ports without a reason.

## 6. Wait for Oracle readiness

Check state and logs:

```bash
docker ps --filter "name=${CONTAINER_NAME}"
docker logs --tail 100 "${CONTAINER_NAME}"
docker stats --no-stream "${CONTAINER_NAME}"
```

`running` is not the same as ready. First initialization can take several minutes while Oracle initializes the database, wallets, certificates, and ORDS.

**PASS:** The container reports healthy, Oracle initializes successfully, ORDS starts, and the host remains within its resource budget.

**STOP:** Stop on repeated health failures, initialization errors, storage errors, or unacceptable host memory pressure.

## 7. Verify ORDS/APEX

From the operator workstation, open:

```text
https://<LAB_HOST>:<HOST_HTTPS_PORT>/ords/apex
```

A self-signed certificate warning is expected in a local lab unless you replace the default certificate.

**PASS:** The ORDS/APEX endpoint responds.

**STOP:** Do not proceed to the project database deployment until the endpoint is reachable.

## 8. Verify database connectivity

From the operator workstation, verify SQLcl can connect using the local wallet or client configuration appropriate to the container.

Keep wallet and TNS material on the operator side. Do not copy them onto the Ubuntu host simply to make the architecture symmetrical.

Once client connectivity works, continue with [Deploy Database Schema with SQLcl](../deploy-database-schema.md).

**PASS:** SQLcl reaches the database from the operator workstation.

**STOP:** Do not compensate for client connectivity problems by installing development tooling or storing operator credentials on the runtime host.

## Failure handling

If deployment fails:

1. stop at the failed gate;
2. capture the relevant non-secret command output or logs;
3. decide whether the problem is Ubuntu, Docker, the Oracle image, storage, networking, or the project deployment;
4. remove a failed container before retrying;
5. if first-time initialization left an unusable volume, recreate the volume deliberately rather than trying random repair commands;
6. update this procedure only when the finding is reusable for another operator.

## Cleanup

For a disposable lab, remove abandoned containers, volumes, images, and runtime directories when they are no longer needed. Retain only the credentials and runtime state required by the active lab.

## Completion criteria

This procedure is complete when:

- the Oracle ADB Free container is healthy;
- persistent database state is in the Docker volume;
- ORDS/APEX is reachable;
- SQLcl can reach the database from the operator workstation;
- no secrets are stored in Git;
- the Ubuntu host does not depend on development tooling or undocumented configuration.

At that point the Oracle platform is ready for the repository's install, seed, and validation steps.
