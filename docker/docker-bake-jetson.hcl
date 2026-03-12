group "default" {
  targets = ["jetson-devel"]
}

// For docker/metadata-action
target "docker-metadata-action-jetson-devel" {}

target "jetson-devel" {
  inherits   = ["docker-metadata-action-jetson-devel"]
  dockerfile = "docker/Dockerfile.jetson"
  target     = "jetson-devel"
}
