# Procedure: Deploy Oracle Autonomous AI Database Free Container

## Purpose
Deploy the Oracle Autonomous AI Database Free container used as the management repository and APEX/ORDS platform for this project.

## Scope
This procedure documents the supported runtime path for the project: **Ubuntu Linux with Docker**.

The Oracle host is the **runtime plane**. It provides the container runtime, persistent storage, network access, and host resources required to run the lab database.

Source control and database deployment tooling belong on the **operator workstation/control plane**. The runtime host does not require Git, SQLcl, VS Code, a project repository clone, or database wallets used by the operator workstation.

Other Linux distributions or container runtimes may work, but they are outside the documented path. Hostname, IP address, filesystem location, port mappings, DNS, and optional ingress remain environment-specific choices.

This container represents the **management repository**, not one of the fictional Oracle database targets modeled by the project.

## Operator Guardrails
- Do not store passwords, wallets, certificates, or generated runtime data in Git.
- Do not use production or employer-derived hostnames, SIDs, schema names, credentials, code, or data.
- Keep persistent runtime state separate from source-controlled project files.
- The runtime host does not require a clone of this repository.
- Prefer a disposable lab filesystem for host-side runtime support files.
- Stop if the host cannot provide the required memory, CPU, FUSE device access, container capabilities, or persistent storage.
- Do not expose the container directly to the public Internet.

## Responsibility Boundary

### Operator workstation / control plane
The operator workstation is responsible for:

- Git and repository management
- VS Code or another editor
- SQLcl or another approved Oracle client
- database wallets and client connection configuration
- running project schema deployment and validation scripts
- reviewing and committing source changes

### Oracle runtime host
The runtime host is responsible for:

- Ubuntu Linux
- Docker Engine
- Oracle ADB Free container execution
- Docker-managed persistent database storage
- local secret file used to initialize/start the container
- required FUSE and container capabilities
- network reachability for database and HTTPS endpoints

Keeping this boundary explicit prevents development tooling from becoming an unnecessary dependency of the Oracle host.

## Supported Reference Platform
The documented runtime path assumes:

- Ubuntu Linux
- Docker Engine
- operator access sufficient to run Docker and create the selected runtime directory
- sufficient host memory and CPU
- `/dev/fuse` access

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
- a runtime requirement for `SYS_ADMIN` capability and `/dev/fuse` access

The validated reference deployment uses an 8 GiB Docker memory ceiling. Host capacity must be evaluated independently before starting the container.

## Deployment Variables
Choose values appropriate for the target environment before running the procedure.

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

The values are implementation choices, not project naming requirements. A second operator should be able to select an appropriate hostname and filesystem path without knowledge of the original development lab.

## Related Procedures and Project Artifacts
- [Lab Deployment](../lab-deployment.md)
- [Database Schema Deployment](../deploy-database-schema.md)
- [Seed Data Design](../../seed-data-design.md)

The container procedure stops at a healthy, reachable Oracle platform. Schema creation, project validation, seed loading, and application deployment are separate concerns and should remain separate procedures or implementation steps.

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

Create host-side runtime support paths:

```bash
export LAB_ROOT=/path/to/runtime/oracle-estate-operations
mkdir -p "${LAB_ROOT}/secrets"
chmod 700 "${LAB_ROOT}/secrets"
```

The runtime host does not need a Git working tree. Treat `${LAB_ROOT}` as runtime support storage, not as a source checkout.

Persistent Oracle database files will be stored in the Docker-managed volume created later in this procedure.

### PASS
Runtime support and secret storage exist independently of source control.

### STOP
Do not continue if credentials or generated runtime state would be stored in tracked project files.

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

Create a local runtime env file such as:

```text
/path/to/runtime/oracle-estate-operations/secrets/adb.env
```

Example structure:

```text
ADMIN_PASSWORD=<strong-password>
WALLET_PASSWORD=<strong-password>
```

Do not commit or copy this file into the project repository.

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
Credentials meet Oracle policy and are available to Docker without being stored in source control.

### STOP
Do not continue if credential validation is uncertain or secrets would be stored in tracked files.

## 5. Create and Prepare Persistent Volume

Create a Docker-managed volume:

```bash
export VOLUME_NAME=oracle-estate-adb-data
docker volume create "${VOLUME_NAME}"
```

The validated 26ai image runs as:

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
- This documented `docker run` path is the validated baseline. A later Compose implementation should reproduce the same requirements rather than replace them with different assumptions.

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

## 9. Verify Control-Plane Connectivity

After the runtime platform is healthy, return to the operator workstation and confirm that the Oracle client can connect using the locally stored wallet/client configuration.

Do not copy the operator wallet into the runtime host merely to satisfy this procedure.

The project database layer is then deployed and validated from the control plane using the documented schema deployment procedure and the repository scripts:

```text
deploy/install.sql
deploy/validate.sql
```

`deploy/install.sql` is an installation path, not a destructive reset path. It intentionally stops on SQL errors. Re-running it against already-existing project schemas can therefore fail at schema creation rather than silently replacing existing objects.

If a clean reinstall is required, perform an explicit, deliberate lab reset before running the installer again. A future reset procedure may formalize that destructive operation; the container deployment procedure must not silently drop project schemas.

### PASS
- control-plane Oracle client reaches the database
- project deployment can proceed from the workstation
- no workstation wallet or Git tooling is required on the Oracle host

### STOP
Do not compensate for client connectivity or schema deployment problems by adding broad tooling, credentials, or source-control dependencies to the runtime host.

## 10. Record Deployment Outcome

Record only non-secret deployment facts:

- Oracle image and tag
- Ubuntu version
- Docker version
- mapped ports
- Docker memory ceiling
- volume name
- deployment date
- observed steady-state memory
- runtime validation result
- justified deviations

Do not record passwords, wallet contents, private certificates, or host-specific secrets.

## Failure Handling
If deployment fails:

1. Stop at the failed gate.
2. Capture the failing command and relevant non-secret logs.
3. Remove the failed container before retrying.
4. If failure occurred during first-time database initialization, recreate the persistent volume unless the failure is known not to have modified database state.
5. Determine whether the failure is host-specific, Docker-specific, image-specific, network-specific, or project-specific.
6. Keep runtime-host troubleshooting separate from control-plane database deployment troubleshooting.
7. Update this procedure only when the finding is reusable beyond one host.

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
- the database is reachable from the operator workstation,
- no secrets have been committed,
- the runtime host does not depend on Git or database deployment tooling,
- the host remains healthy,
- the deployment can be explained and repeated from this document alone.

Project schema installation and data seeding are validated separately from container deployment.

## Portability Notes
The project aims for **practical portability**, not support for every possible platform.

Documented runtime assumptions:
- Ubuntu Linux
- Docker
- required host resources and capabilities
- persistent runtime storage
- APEX/ORDS reachability
- network access from the operator workstation
- no secrets in source control

Documented control-plane assumptions:
- source control is managed outside the Oracle host
- an Oracle client such as SQLcl is available to the operator
- connection credentials/wallets remain on the control plane

Environment-specific choices:
- hostname or IP address
- filesystem paths for local runtime support files and secrets
- host port mappings
- DNS and optional reverse proxy/ingress configuration

Operators using another distribution or container runtime are welcome to adapt the procedure, but those combinations are not part of the project's validated reference path.
