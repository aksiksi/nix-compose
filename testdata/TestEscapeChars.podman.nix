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
  virtualisation.oci-containers.containers."dovecot" = {
    image = "dovecot";
    volumes = [
      "dovecot_def:/path/to/path:rw"
    ];
    labels = {
      "ofelia.enabled" = "true";
      "ofelia.job-exec.dovecot_imapsync_runner.command" = "/bin/bash -c \"[[ \${MASTER} == y ]] && /usr/local/bin/gosu nobody /usr/local/bin/imapsync_runner.pl || exit 0\"";
      "ofelia.job-exec.dovecot_imapsync_runner.no-overlap" = "true";
      "ofelia.job-exec.dovecot_imapsync_runner.schedule" = "@every 1m";
      "ofelia.job-exec.dovecot_trim_logs.command" = "/bin/bash -c \"[[ \${MASTER} == y ]] && /usr/local/bin/gosu vmail /usr/local/bin/trim_logs.sh || exit 0\"";
      "ofelia.job-exec.dovecot_trim_logs.schedule" = "@every 1m";
    };
    log-driver = "journald";
    autoStart = false;
    extraOptions = [
      "--network-alias=dovecot"
      "--network=dovecot_abc"
    ];
  };
  systemd.services."podman-dovecot" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "no";
    };
    after = [
      "podman-network-dovecot_abc.service"
      "podman-volume-dovecot_def.service"
    ];
    requires = [
      "podman-network-dovecot_abc.service"
      "podman-volume-dovecot_def.service"
    ];
    partOf = [
      "podman-compose-dovecot-root.target"
    ];
    wantedBy = [
      "podman-compose-dovecot-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-dovecot_abc" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f dovecot_abc";
    };
    script = ''
      podman network inspect dovecot_abc || podman network create dovecot_abc --label=my-label="some quoted string"
    '';
    partOf = [ "podman-compose-dovecot-root.target" ];
    wantedBy = [ "podman-compose-dovecot-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-dovecot_def" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect dovecot_def || podman volume create dovecot_def --label=other-label="another quota string"
    '';
    partOf = [ "podman-compose-dovecot-root.target" ];
    wantedBy = [ "podman-compose-dovecot-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-dovecot-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
  };
}
