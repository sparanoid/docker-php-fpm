function "process_tag" {
  params = [string]
  # See available functions here:
  # https://github.com/docker/buildx/blob/c5eb8f58b4884dd9001042768574cdde08087501/bake/hclparser/stdlib.go#L78
  result = regex_replace(string, "-fpm", "")
}

variable "BASE_SLUG" {
  default = "sparanoid/php-fpm"
}

variable "BASE_TAG" {
  default = "8.1-fpm"
}

variable "BUILD_TAG" {
  default = process_tag("${BASE_TAG}")
}

variable "DEFAULT_TAG" {
  default = [
    # Only build :local for 8.1-fpm
    equal("8.1-fpm", BASE_TAG) ? "${BASE_SLUG}:local" : "",
    "${BASE_SLUG}:${BUILD_TAG}-local"
  ]
}

# Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = "${DEFAULT_TAG}"
  args = {
    BASE_TAG = "${BASE_TAG}"
  }
}

# Default target if none specified
group "default" {
  targets = ["build-local"]
}

target "build" {
  inherits = ["docker-metadata-action"]
}

target "build-local" {
  inherits = ["build"]
  output = ["type=docker"]
}

target "build-all" {
  inherits = ["build"]
  platforms = [
    "linux/amd64",
    # "linux/arm/v7",
    # "linux/arm64",
  ]
}
