# Container Build and Run

This project ships a production image definition at `container/Dockerfile`.

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
