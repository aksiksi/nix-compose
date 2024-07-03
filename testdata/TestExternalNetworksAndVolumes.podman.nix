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
  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."traefik" = {
    image = "docker.io/library/traefik";
    volumes = [
      "myproject_test1:/test1:rw"
      "test2:/test2:rw"
    ];
    ports = [
      "80:80/tcp"
      "443:443/tcp"
    ];
    log-driver = "journald";
    autoStart = false;
    extraOptions = [
      "--network-alias=traefik"
      "--network=myproject_test1:alias=my-container"
      "--network=test2"
      "--network=test3"
    ];
  };
  systemd.services."podman-traefik" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-myproject_test1.service"
      "podman-volume-myproject_test1.service"
    ];
    requires = [
      "podman-network-myproject_test1.service"
      "podman-volume-myproject_test1.service"
    ];
    partOf = [
      "podman-compose-myproject-root.target"
    ];
    wantedBy = [
      "podman-compose-myproject-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-myproject_test1" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.podman}/bin/podman network rm -f myproject_test1";
    };
    script = ''
      podman network inspect myproject_test1 || podman network create myproject_test1
    '';
    partOf = [ "podman-compose-myproject-root.target" ];
    wantedBy = [ "podman-compose-myproject-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-myproject_test1" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect myproject_test1 || podman volume create myproject_test1
    '';
    partOf = [ "podman-compose-myproject-root.target" ];
    wantedBy = [ "podman-compose-myproject-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-myproject-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
  };
}
