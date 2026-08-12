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

target "web" {
  context    = "."
  dockerfile = "docker/web/Dockerfile"
  # A secret, never an arg: buildx writes build args verbatim into the SLSA
  # provenance of the pushed image, and this image is public. Passing the
  # Composer credential as `args` published a working git.netresearch.de token
  # in every attestation. `type=env` reads COMPOSER_AUTH from the environment,
  # which is exactly what the reusable build workflow already exports, so the
  # calling workflow needs no change. An unset variable yields an empty secret
  # and the build still resolves every public dependency.
  secret = ["type=env,id=composer_auth,env=COMPOSER_AUTH"]
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
