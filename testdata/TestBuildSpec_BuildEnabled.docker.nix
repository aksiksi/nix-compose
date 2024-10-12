{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."test-museum" = {
    image = "compose2nix/test-museum";
    environment = {
      "ENTE_CREDENTIALS_FILE" = "/credentials.yaml";
    };
    volumes = [
      "/some/path/data:/data:ro"
      "/some/path/museum.yaml:/museum.yaml:ro"
      "/some/path/scripts/compose/credentials.yaml:/credentials.yaml:ro"
      "test_custom-logs:/var/logs:rw"
    ];
    ports = [
      "8080:8080/tcp"
      "2112:2112/tcp"
    ];
    log-driver = "journald";
    autoStart = false;
    extraOptions = [
      "--network-alias=museum"
      "--network=test_internal"
    ];
  };
  systemd.services."docker-test-museum" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-build-test-museum.service"
      "docker-network-test_internal.service"
      "docker-volume-test_custom-logs.service"
    ];
    requires = [
      "docker-build-test-museum.service"
      "docker-network-test_internal.service"
      "docker-volume-test_custom-logs.service"
    ];
    upheldBy = [
      "docker-build-test-museum.service"
    ];
  };

  # Networks
  systemd.services."docker-network-test_internal" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f test_internal";
    };
    script = ''
      docker network inspect test_internal || docker network create test_internal
    '';
    partOf = [ "docker-compose-test-root.target" ];
    wantedBy = [ "docker-compose-test-root.target" ];
  };

  # Volumes
  systemd.services."docker-volume-test_custom-logs" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect test_custom-logs || docker volume create test_custom-logs
    '';
    partOf = [ "docker-compose-test-root.target" ];
    wantedBy = [ "docker-compose-test-root.target" ];
  };

  # Builds
  systemd.services."docker-build-test-museum" = {
    path = [ pkgs.docker pkgs.git ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutSec = 300;
    };
    script = ''
      cd /some/path
      docker build -t compose2nix/test-museum --build-arg GIT_COMMIT=development-cluster -f path/Dockerfile .
    '';
    partOf = [ "docker-compose-test-root.target" ];
    wantedBy = [ "docker-compose-test-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-test-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
  };
}
