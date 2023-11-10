# compose2nix

[![codecov](https://codecov.io/gh/aksiksi/compose2nix/graph/badge.svg)](https://codecov.io/gh/aksiksi/compose2nix)
[![test](https://github.com/aksiksi/compose2nix/actions/workflows/test.yml/badge.svg)](https://github.com/aksiksi/compose2nix/actions/workflows/test.yml)

A tool to automatically generate a NixOS config from a Docker Compose project.

## Quickstart

Install the `compose2nix` CLI via one of the following methods:

1. Cloning this repo and running `make build`
2. Installing the Flake and adding the following to your Nix config:
    ```nix
    environment.systemPackages = with pkgs; [
      compose2nix.packages.x86_64-linux.default
    ];
    ```

Run `compose2nix`.

```bash
compose2nix
```

By default, the tool looks for `docker-compose.yml` in the **current directory** and outputs the NixOS config to `docker-compose.nix`.

## Options

```bash
$ compose2nix -h
Usage of compose2nix:
  -auto_start
        auto-start setting for generated container(s). (default true)
  -env_files string
        one or more comma-separated paths to .env file(s).
  -env_files_only
        only use env file(s) in the NixOS container definitions.
  -generate_unused_resources
        if set, unused resources (e.g., networks) will be generated even if no containers use them.
  -inputs string
        one or more comma-separated path(s) to Compose file(s). (default "docker-compose.yml")
  -output string
        path to output Nix file. (default "docker-compose.nix")
  -project string
        project name used as a prefix for generated resources.
  -project_separator string
        seperator for project prefix. (default "_")
  -runtime string
        one of: ["podman", "docker"]. (default "podman")
  -service_include string
        regex pattern for services to include.
  -use_compose_log_driver
        if set, always use the Docker Compose log driver.
```
