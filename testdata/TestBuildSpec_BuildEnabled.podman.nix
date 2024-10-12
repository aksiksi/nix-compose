{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.backend = "podman";

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
  systemd.services."podman-test-museum" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-build-test-museum.service"
      "podman-network-test_internal.service"
      "podman-volume-test_custom-logs.service"
    ];
    requires = [
      "podman-build-test-museum.service"
      "podman-network-test_internal.service"
      "podman-volume-test_custom-logs.service"
    ];
    upheldBy = [
      "podman-build-test-museum.service"
    ];
  };

  # Networks
  systemd.services."podman-network-test_internal" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f test_internal";
    };
    script = ''
      podman network inspect test_internal || podman network create test_internal
    '';
    partOf = [ "podman-compose-test-root.target" ];
    wantedBy = [ "podman-compose-test-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-test_custom-logs" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect test_custom-logs || podman volume create test_custom-logs
    '';
    partOf = [ "podman-compose-test-root.target" ];
    wantedBy = [ "podman-compose-test-root.target" ];
  };

  # Builds
  systemd.services."podman-build-test-museum" = {
    path = [ pkgs.podman pkgs.git ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutSec = 300;
    };
    script = ''
      cd /some/path
      podman build -t compose2nix/test-museum --build-arg GIT_COMMIT=development-cluster -f path/Dockerfile .
    '';
    partOf = [ "podman-compose-test-root.target" ];
    wantedBy = [ "podman-compose-test-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-test-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
  };
}
