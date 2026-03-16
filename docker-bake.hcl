group "default" {
  targets = ["web"]
}

variable "REGISTRY" {
  default = "ghcr.io/netresearch"
}

variable "TAG" {
  default = "latest"
}

variable "GIT_SHA" {
  default = ""
}

variable "COMPOSER_AUTH" {
  default = ""
}

target "web" {
  context    = "."
  dockerfile = "docker/web/Dockerfile"
  args = {
    COMPOSER_AUTH = COMPOSER_AUTH
  }
  tags       = GIT_SHA != "" ? [
    "${REGISTRY}/typo3-demo:${TAG}",
    "${REGISTRY}/typo3-demo:sha-${GIT_SHA}",
  ] : [
    "${REGISTRY}/typo3-demo:${TAG}",
  ]
  platforms  = ["linux/amd64", "linux/arm64"]
  cache-from = ["type=gha"]
  cache-to   = ["type=gha,mode=max"]
}

target "web-dev" {
  inherits   = ["web"]
  target     = "dev"
  tags       = ["typo3-demo:dev"]
  platforms  = ["linux/amd64"]
}
