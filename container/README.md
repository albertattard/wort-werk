# Container Build and Run

This project ships a production image definition at `container/Dockerfile`.
Local verification stack definition: `container/compose.verify.yml` (invoked by `./mvnw clean verify`).
The production Dockerfile intentionally uses a pinned Oracle no-fee Oracle JDK builder image on Oracle Linux plus a slim Oracle Linux runtime base.
That keeps local verification and OCI DevOps verification on Oracle-provided images without adding a second Oracle JDK base-image login step.
OCI DevOps uses the same `./mvnw clean verify` contract through a repository-owned Podman-native backend instead of assuming a Docker daemon-backed Compose runtime on the managed runner.

For local Maven verification, the required order is:

```bash
export VERIFY_DB_USERNAME='<username>'
export VERIFY_DB_PASSWORD='<password>'
./mvnw clean verify
```

OCI deployment runbook: [OCI-DEPLOYMENT.md](./OCI-DEPLOYMENT.md)

## Build (Local, Single Architecture)

Example for `linux/amd64`:

```bash
docker build \
  --file ./container/Dockerfile \
  --tag game:wort-werk \
  --platform linux/amd64 \
  --load \
  .
```

## Run

```bash
docker run \
  --rm \
  --detach \
  --name wort-werk \
  --publish 8080:8080 \
  game:wort-werk
```

## Stop

```bash
docker stop wort-werk
```

## Multi-Architecture Build

To build and publish both `linux/amd64` and `linux/arm64`, use `buildx`:

```bash
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

docker buildx build \
  --file ./container/Dockerfile \
  --tag <registry>/game/wort-werk:latest \
  --platform linux/amd64,linux/arm64 \
  --push \
  .
```

Notes:
- `--load` is single-architecture only.
- Multi-arch output requires pushing to a registry (`--push`).
- `aarch64` corresponds to Docker platform `linux/arm64`.
