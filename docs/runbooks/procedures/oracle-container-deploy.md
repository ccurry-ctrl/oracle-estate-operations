# Procedure: Deploy Oracle Autonomous AI Database Free Container

## Purpose
Deploy the local Oracle Autonomous AI Database Free container used as the management repository and APEX/ORDS platform for this project.

## Scope
This procedure documents the supported reference path for the project: **Ubuntu Linux with Docker**.

Other Linux distributions or container runtimes may work, but they are outside the documented path. Environment-specific values such as hostname, IP address, filesystem location, and optional ingress remain operator choices.

This container represents the **management repository**, not one of the fictional Oracle database targets modeled by the project.

## Operator Guardrails
- Do not store passwords, wallets, certificates, or generated runtime data in Git.
- Do not use production or employer-derived hostnames, SIDs, schema names, credentials, or data.
- Keep persistent runtime state outside the Git working tree.
- Prefer a disposable lab filesystem.
- Stop if the host cannot provide the required memory, CPU, FUSE device access, or container capabilities.
- Do not expose the container directly to the public Internet.

## Supported Reference Platform
The documented deployment path assumes:

- Ubuntu Linux
- Docker Engine
- Git for source control
- operator access sufficient to run Docker and create the selected runtime directory

Validated project image:

```text
ghcr.io/oracle/adb-free:latest-26ai
```

Oracle Autonomous AI Database Free includes:

- Oracle APEX
- ORDS
- Database Actions
- optional Mongo-compatible API
- database connectivity on container port `1522`
- HTTPS for ORDS/APEX on container port `8443`
- `SYS_ADMIN` capability and `/dev/fuse` access

The reference deployment uses an 8 GiB Docker memory ceiling. Host capacity must be evaluated independently before starting the container.

## Deployment Variables
Choose these values for the target environment before running the procedure.

```text
CONTAINER_NAME=oracle-estate-adb
WORKLOAD_TYPE=ATP
HOST_HTTPS_PORT=8443
HOST_DB_PORT=1521
LAB_HOST=<hostname-or-ip>
LAB_ROOT=/path/to/runtime/oracle-estate-operations
IMAGE=ghcr.io/oracle/adb-free:latest-26ai
VOLUME_NAME=oracle-estate-adb-data
```

Example only for the Stack.Idlewood reference lab:

```text
LAB_HOST=stack
LAB_ROOT=/srv/workshop/oracle-estate-operations
```

The example values are not requirements. A second operator should be able to select an appropriate hostname and filesystem path without knowing anything about Stack.Idlewood.

## Related Procedures
- [Lab Deployment](../lab-deployment.md)
- Schema deployment procedure: planned
- Sample data load procedure: planned
- APEX workspace/application procedure: planned
- Lab validation procedure: planned

## 1. Verify Host Prerequisites

Confirm Ubuntu:

```bash
cat /etc/os-release
```

Confirm Docker is installed and usable:

```bash
docker --version
docker info >/dev/null
```

Confirm available memory and CPU:

```bash
free -h
nproc
```

Confirm FUSE is available:

```bash
ls -l /dev/fuse
```

Confirm the selected host ports are not already listening:

```bash
ss -lnt | grep -E ':8443|:1521' || true
```

### PASS
- Host is Ubuntu Linux.
- Docker responds successfully.
- Host has sufficient resources for the lab.
- `/dev/fuse` exists and is accessible.
- Selected ports are available or intentionally remapped.

### STOP
Do not continue if Docker, required resources, FUSE access, or port assignments are unresolved.

## 2. Create Runtime and Secret Storage

Create local runtime paths outside the Git repository:

```bash
export LAB_ROOT=/path/to/runtime/oracle-estate-operations
mkdir -p "${LAB_ROOT}/secrets"
chmod 700 "${LAB_ROOT}/secrets"
```

Do not store generated Oracle database files directly in the Git working tree.

### PASS
Runtime and secret storage exist outside the Git working tree.

### STOP
Do not continue if runtime state or credentials would be stored in the repository.

## 3. Obtain the Oracle Container Image

```bash
export IMAGE=ghcr.io/oracle/adb-free:latest-26ai
docker pull "${IMAGE}"
```

Verify:

```bash
docker images | grep adb-free
```

### PASS
The `latest-26ai` image is present locally.

### STOP
Do not continue if the image pull fails or the image source is unclear.

## 4. Prepare Credentials

Create an untracked local env file such as:

```text
/path/to/runtime/oracle-estate-operations/secrets/adb.env
```

Example structure:

```text
ADMIN_PASSWORD=<strong-password>
WALLET_PASSWORD=<strong-password>
```

Do not commit this file.

The `ADMIN_PASSWORD` must satisfy Oracle's policy:

- 12 to 30 characters
- at least one uppercase letter
- at least one lowercase letter
- at least one number
- must not contain the username `ADMIN`

Lock down the file:

```bash
chmod 600 "${LAB_ROOT}/secrets/adb.env"
```

### PASS
Credentials meet Oracle policy and are available to Docker without being committed to Git.

### STOP
Do not continue if credential validation is uncertain or secrets would be stored in tracked files.

## 5. Create and Prepare Persistent Volume

Create a Docker-managed volume:

```bash
export VOLUME_NAME=oracle-estate-adb-data
docker volume create "${VOLUME_NAME}"
```

The 26ai image runs as:

```text
uid=1001(oracle)
gid=1001(oinstall)
```

Confirm if needed:

```bash
docker run --rm --entrypoint id "${IMAGE}"
```

A newly created local Docker volume may be owned by `root:root`, which prevents the `oracle` user from writing `/u01/data`. Prepare the volume ownership using numeric IDs:

```bash
VOLUME_PATH=$(docker volume inspect "${VOLUME_NAME}" --format '{{ .Mountpoint }}')
chown -R 1001:1001 "${VOLUME_PATH}"
ls -ld "${VOLUME_PATH}"
```

Use numeric UID/GID values rather than host account names because the host may resolve GID `1001` to a different local group name.

### PASS
The Docker volume exists and its data directory is owned by UID/GID `1001:1001`.

### STOP
Do not continue if `/u01/data` would not be writable by the image's `oracle` user.

## 6. Start the Container

```bash
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

Notes:

- Oracle also provides a Mongo-compatible API on port `27017`. It is not required for project V1 and should remain unexposed unless a later requirement justifies it.
- Host port values are examples and may be remapped.
- A future Compose implementation may replace this command after the manual path is fully validated.

## 7. Verify Container State

Check the container:

```bash
docker ps --filter "name=${CONTAINER_NAME}"
```

Review startup logs:

```bash
docker logs --tail 100 "${CONTAINER_NAME}"
```

Monitor resource usage:

```bash
docker stats --no-stream "${CONTAINER_NAME}"
free -h
```

Do not treat `running` alone as readiness. First initialization may take several minutes while Oracle unpacks database files, generates wallets/certificates, initializes the database, and starts ORDS.

### PASS
- container health reports `healthy`
- Oracle database starts successfully
- ORDS reports successful initialization
- host remains within the planned resource budget

### STOP
Stop if the container exits, repeatedly fails health checks, reports unresolved initialization errors, cannot write `/u01/data`, or causes unacceptable host memory pressure.

## 8. Verify APEX / ORDS

From a browser with network access to the host, open:

```text
https://<LAB_HOST>:<HOST_HTTPS_PORT>/ords/apex
```

The container uses a self-signed certificate by default, so a browser certificate warning is expected in a local lab unless a trusted certificate is added later.

### PASS
The APEX endpoint responds and the APEX landing/login workflow is reachable.

### STOP
Do not proceed to schema or application deployment until the ORDS/APEX endpoint is reachable.

## 9. Record Deployment Outcome

Record only non-secret deployment facts:

- Oracle image and tag
- Ubuntu version
- Docker version
- mapped ports
- Docker memory ceiling
- volume name
- deployment date
- observed steady-state memory
- validation result
- justified deviations

Do not record passwords, wallet contents, private certificates, or host-specific secrets.

## Failure Handling
If deployment fails:

1. Stop at the failed gate.
2. Capture the failing command and relevant non-secret logs.
3. Remove the failed container before retrying.
4. If failure occurred during first-time database initialization, recreate the persistent volume unless the failure is known not to have modified database state.
5. Determine whether the failure is host-specific, Docker-specific, image-specific, or project-specific.
6. Update this procedure only when the finding is reusable beyond one host.

## Cleanup
After the validated deployment path is established:

- remove obsolete Oracle images no longer required
- remove failed/test containers
- remove abandoned volumes
- remove temporary runtime directories that are no longer used
- retain only credentials required for the active lab and keep them outside Git

## Completion Criteria
This procedure is complete when:

- the Oracle Autonomous AI Database Free 26ai container reports healthy,
- persistent runtime state is stored in the prepared Docker volume,
- APEX/ORDS is reachable,
- no secrets have been committed,
- the host remains healthy,
- the deployment can be explained and repeated from this document alone.

## Portability Notes
The project aims for **practical portability**, not support for every possible platform.

Documented assumptions:
- Ubuntu Linux
- Docker
- required host resources and capabilities
- persistent runtime storage
- APEX/ORDS reachability
- no secrets in source control

Environment-specific choices:
- hostname or IP address
- filesystem paths for local secrets/runtime notes
- host port mappings
- DNS and optional reverse proxy/ingress configuration

Operators using another distribution or container runtime are welcome to adapt the procedure, but those combinations are not part of the project's validated reference path.
