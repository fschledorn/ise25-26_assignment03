# CampusCoffee (WS 25/26)

## Prerequisites

* Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) or a compatible open-source alternative such as [Rancher Desktop](https://rancherdesktop.io/).
* Install the [Temurin JDK 21](https://adoptium.net/temurin/releases/?version=21&os=any&arch=any) and [Maven 3.9](https://maven.apache.org/install.html) either via the provided [`mise.toml`](mise.toml) file (see [getting started guide](https://mise.jdx.dev/getting-started.html) for details) or directly via your favorite package manager.
* Install a Java IDE. We recommend [IntelliJ](https://www.jetbrains.com/idea/), but you are free to use alternatives such as [VS Code](https://code.visualstudio.com/) with suitable extensions.

## Build application

First, make sure that the Docker daemon is running.
Then, to build the application, run the following command in the command line (or use the Maven integration of your IDE):

```shell
mvn clean install
```
**Note:** In the `dev` profile, all repositories are cleared before startup, the initial data is loaded (see [`LoadInitialData.java`](application/src/main/java/de/seuhd/campuscoffee/LoadInitialData.java)).

You can use the quiet mode to suppress most log messages:

```shell
mvn clean install -q
```

## Start application (dev)

First, make sure that the Docker daemon is running.
Before you start the application, you first need to start a Postgres docker container:

```shell
docker run -d -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:17-alpine
```

Then, you can start the application:

```shell
cd application
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```
**Note:** The data source is configured via the [`application.yaml`](application/src/main/resources/application.yaml) file.

## REST API

You can use `curl` in the command line to send HTTP requests to the REST API.

### POS endpoint

#### Get POS

All POS:
```shell
curl http://localhost:8080/api/pos
```
POS by ID:
```shell
curl http://localhost:8080/api/pos/1 # add valid POS id here
```

#### Create POS

```shell
curl --header "Content-Type: application/json" --request POST --data '{"name":"New Café","description":"Description","type":"CAFE","campus":"ALTSTADT","street":"Hauptstraße","houseNumber":"100","postalCode":69117,"city":"Heidelberg"}' http://localhost:8080/api/pos
```

#### Update POS

Update title and description:
```shell
curl --header "Content-Type: application/json" --request PUT --data '{"id":4,"name":"New coffee","description":"Great croissants","type":"CAFE","campus":"ALTSTADT","street":"Hauptstraße","houseNumber":"95","postalCode":69117,"city":"Heidelberg"}' http://localhost:8080/api/pos/4 # set correct POS id here and in the body
```

## Docker (recommended)

This project ships a multi-stage Dockerfile and a `docker-bake.hcl` target which uses Buildx for multi-arch builds and a local cache to speed up subsequent builds.

Prerequisites
- Docker Desktop or a compatible daemon
- Docker Buildx available (Docker Desktop includes it)

Build (local, loads into local docker engine)

1. (Optional) create and bootstrap a builder that supports multiple platforms:

```shell
docker buildx create --name mybuilder --driver docker-container --use
docker buildx inspect --bootstrap
```

2. Build the image using bake (this uses the `app` target defined in `docker-bake.hcl`):

```shell
docker buildx bake app --load
```

This will build an image (by default tagged as `ise25-26/app:latest` in the bake target) for the platforms configured in `docker-bake.hcl` and load it into your local docker engine.

If you prefer `docker buildx build` directly, you can run:

```shell
docker buildx build --platform linux/amd64,linux/arm64 -t youruser/ise25-26:latest --push .
```

Run with docker-compose (local dev)

We provide `docker-compose.yml` to start the application together with a Postgres service. After building (or after pulling the prebuilt image), start the stack:

```shell
docker compose up -d
docker compose logs -f --tail=200
```

Notes and housekeeping
- The repository `.gitignore` already excludes `.buildx-cache/` and other local Docker artifacts so build caches are not committed.
- If you accidentally committed cache files, remove them from the index and commit the removal:

```shell
git rm -r --cached .buildx-cache
git commit -m "chore: remove buildx cache from repository"
```

- To free local buildx caches on your machine you can prune them with:

```shell
docker buildx prune -a
```

Publishing to upstream / CI notes

- In CI (GitHub Actions or similar) prefer `docker buildx build --push` to produce and publish multi-arch images.
- Use the `--cache-to` and `--cache-from` options or `docker-bake.hcl` to speed CI builds by persisting cache in the workflow between runs.