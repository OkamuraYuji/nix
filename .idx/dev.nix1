{ pkgs, ... }: {
  # Use a recent channel (matches Firebase Studio docs)
  channel = "stable-24.11";

  # Tools available in the terminal
  packages = [
    pkgs.docker
    pkgs.cloudflared
  ];

  # Enable Docker (rootless)
  services.docker.enable = true;

  # Auto-run your container on workspace start
  idx.workspace.onStart = {
    novnc = ''
      # Be forgiving on rebuilds
      find /home/user -mindepth 1 -maxdepth 1 ! -name 'idx-ubuntu22-gui' ! -name '.*' -exec rm -rf {} +



      docker rm ubuntu-novnc 
      

      docker run --name ubuntu-novnc \
        --shm-size 2g -d \
        -p 8080:8080 \
        -p 5901:5901 \
        -e VNC_GEOMETRY=1920x1080 \
        -e VNC_DEPTH=24 \
        ghcr.io/okamurayuji/os:ubuntu-gnome

      cloudflared tunnel --url http://localhost:8080
    '';
  };

  # (Optional) show a preview tile in the UI – the app already runs via onStart,
  # so we just keep a harmless long-lived command.
  idx.previews = {
    enable = true;
    previews = {
      novnc = {
        command = [ "bash" "-lc" "echo 'noVNC on port 8080'; tail -f /dev/null" ];
        manager = "web";
      };
    };
  };
}
