group "default" {
  targets = ["web"]
}

variable "REGISTRY" {
  default = "ghcr.io/netresearch"
}

variable "TAG" {
  default = "latest"
}

target "web" {
  context    = "."
  dockerfile = "docker/web/Dockerfile"
  tags       = ["${REGISTRY}/typo3-demo:${TAG}"]
  platforms  = ["linux/amd64", "linux/arm64"]
  cache-from = ["type=gha"]
  cache-to   = ["type=gha,mode=max"]
}

target "web-dev" {
  inherits   = ["web"]
  tags       = ["typo3-demo:dev"]
  platforms  = ["linux/amd64"]
  args = {
    TYPO3_CONTEXT = "Development/Docker"
  }
}
