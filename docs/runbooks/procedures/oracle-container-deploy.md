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

Oracle currently documents the Autonomous AI Database Free container with:

- Oracle APEX, ORDS, and Database Actions included
- recommended allocation of 4 CPUs and 8 GB RAM
- 20 GB database storage allocation
- HTTPS for ORDS/APEX on container port `8443`
- database connectivity through container port `1522`
- optional Mongo-compatible API on container port `27017`
- `SYS_ADMIN` capability and `/dev/fuse` access

The exact image tag should be checked against current Oracle documentation before deployment. Oracle currently publishes ADB Free images through its supported container registries.

## Deployment Variables
Choose these values for the target environment before running the procedure.

```text
CONTAINER_NAME=oracle-estate-adb
WORKLOAD_TYPE=ATP
HOST_HTTPS_PORT=8443
HOST_DB_PORT=1521
LAB_HOST=<hostname-or-ip>
LAB_ROOT=/path/to/runtime/oracle-estate-operations
DATA_ROOT=/path/to/runtime/oracle-estate-operations/data
IMAGE=<current Oracle ADB Free image>
```

Example only for the Stack.Idlewood reference lab:

```text
LAB_HOST=stack
LAB_ROOT=/srv/workshop/oracle-estate-operations
DATA_ROOT=/srv/workshop/oracle-estate-operations/data
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

## 2. Create Runtime Storage

Set the local values selected above, then create runtime storage outside the Git repository:

```bash
export LAB_ROOT=/path/to/runtime/oracle-estate-operations
export DATA_ROOT="${LAB_ROOT}/data"
mkdir -p "${DATA_ROOT}"
```

Verify:

```bash
ls -ld "${LAB_ROOT}" "${DATA_ROOT}"
```

### PASS
Runtime storage exists outside the Git working tree and is writable by the deployment operator.

### STOP
Do not continue if runtime state would be stored inside the repository or on an unintended filesystem.

## 3. Obtain the Oracle Container Image

Set the image selected from current Oracle documentation:

```bash
export IMAGE=<current Oracle ADB Free image>
docker pull "${IMAGE}"
```

Verify the image is present:

```bash
docker images | grep -E 'adb-free|oracle'
```

### PASS
The expected image is present locally.

### STOP
Do not continue if the image pull fails, the image source is unclear, or licensing terms have not been reviewed.

## 4. Prepare Credentials

Create strong temporary lab credentials for:

- Autonomous database `ADMIN`
- generated wallet protection

Do not place these values in the repository, shell history, committed `.env` files, or runbook examples.

Preferred approaches include runtime-only environment variables, an untracked local environment file, or an appropriate secrets mechanism supported by Docker.

### PASS
Required credentials are available to the deployment command without being committed to Git.

### STOP
Do not continue if credentials would be stored in tracked project files.

## 5. Start the Container

The Oracle-documented runtime requirements translate to the following Docker pattern:

```bash
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${HOST_DB_PORT}:1522" \
  -p "${HOST_HTTPS_PORT}:8443" \
  -e WORKLOAD_TYPE="${WORKLOAD_TYPE}" \
  -e WALLET_PASSWORD="${WALLET_PASSWORD}" \
  -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
  --cap-add SYS_ADMIN \
  --device /dev/fuse \
  --volume "${DATA_ROOT}:/u01/data" \
  "${IMAGE}"
```

Notes:

- Oracle also provides a Mongo-compatible API on port `27017`. It is not required for project V1 and should remain unexposed unless a later requirement justifies it.
- Host port values are examples. Remap them if the host already uses those ports.
- A future Compose implementation may replace this command once the manual deployment has been validated.

## 6. Verify Container State

Check the container:

```bash
docker ps --filter "name=${CONTAINER_NAME}"
```

Review startup logs:

```bash
docker logs "${CONTAINER_NAME}"
```

Do not treat `running` alone as application readiness. Continue only when the database and built-in tools have completed initialization.

### PASS
The container remains running and initialization completes without unresolved fatal errors.

### STOP
Stop if the container repeatedly exits, reports unresolved initialization failures, or cannot access persistent storage/FUSE.

## 7. Verify APEX / ORDS

From a browser with network access to the host, open:

```text
https://<LAB_HOST>:<HOST_HTTPS_PORT>/ords/apex
```

The container uses a self-signed certificate by default, so a browser certificate warning is expected in a local lab unless a trusted certificate is added later.

### PASS
The APEX endpoint responds and the APEX landing/login workflow is reachable.

### STOP
Do not proceed to schema or application deployment until the ORDS/APEX endpoint is reachable.

## 8. Record Deployment Outcome

Record only non-secret deployment facts in project notes or the implementation PR:

- Oracle image and tag
- Ubuntu version
- Docker version
- mapped ports
- runtime storage location pattern
- deployment date
- validation result
- any justified deviation from this procedure

Do not record passwords, wallet contents, private certificates, or host-specific secrets.

## Failure Handling
If deployment fails:

1. Stop at the failed gate.
2. Capture the failing command and relevant non-secret logs.
3. Determine whether the failure is host-specific, Docker-specific, image-specific, or project-specific.
4. Update this procedure only when the finding is reusable beyond one host.
5. Keep one-off host fixes in local implementation notes unless they represent a generally useful pattern.

## Completion Criteria
This procedure is complete when:

- the Oracle Autonomous AI Database Free container is running,
- persistent runtime state is outside the Git repository,
- APEX/ORDS is reachable,
- no secrets have been committed,
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
- filesystem paths
- host port mappings
- DNS and optional reverse proxy/ingress configuration

Operators using another distribution or container runtime are welcome to adapt the procedure, but those combinations are not part of the project's validated reference path.
