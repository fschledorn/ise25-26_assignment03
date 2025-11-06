group "default" {
  targets = ["app"]
}

target "app" {
  context = "."
  dockerfile = "application/Dockerfile"
  tags = ["ise25-26/app:latest"]
  args = {
    MAVEN_OPTS = "-Xmx512m"
  }
  # Persist layer/cache locally to speed up subsequent builds
  cache-to = ["type=local,dest=.buildx-cache,mode=max"]
  cache-from = ["type=local,src=.buildx-cache"]
}
