{ pkgs, ... }: {
  channel = "stable-24.11";

  packages = [
    pkgs.docker
    pkgs.cloudflared
    pkgs.socat
    pkgs.coreutils
    pkgs.gnugrep
  ];

  services.docker.enable = true;

  idx.workspace.onStart = {
    novnc = ''
      set -e

      # One-time cleanup
      if [ ! -f /home/user/.cleanup_done ]; then
        rm -rf /home/user/.gradle/* /home/user/.emu/*
        find /home/user -mindepth 1 -maxdepth 1 ! -name 'idx-ubuntu22-gui' ! -name '.*' -exec rm -rf {} +
        touch /home/user/.cleanup_done
      fi

      # Create container nếu chưa có
      if ! docker ps -a --format '{{.Names}}' | grep -qx 'ubuntu-novnc'; then
        docker run --name ubuntu-novnc \
          --rm -d -it \
          --shm-size=512m \
          -p 6901:6901 \
          -e VNC_PW=password \
          kasmweb/ubuntu-focal-desktop:1.16.0
      else
        docker start ubuntu-novnc || true
      fi

      # Cài Chrome bên trong container
      docker exec -it ubuntu-novnc bash -lc "
        sudo apt update &&
        sudo apt remove -y firefox || true &&
        sudo apt install -y wget &&
        wget -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
        sudo apt install -y /tmp/chrome.deb &&
        rm -f /tmp/chrome.deb
      "

      # Run cloudflared tunnel
      nohup cloudflared tunnel --no-autoupdate --url http://localhost:6901 \
        > /tmp/cloudflared.log 2>&1 &

      sleep 10

      if grep -q "trycloudflare.com" /tmp/cloudflared.log; then
        URL=$(grep -o "https://[a-z0-9.-]*trycloudflare.com" /tmp/cloudflared.log | head -n1)
        echo "========================================="
        echo " 🌍 Your Cloudflared tunnel is ready:"
        echo "     $URL"
        echo "========================================="
      else
        echo "❌ Cloudflared tunnel failed, check /tmp/cloudflared.log"
      fi

      elapsed=0; while true; do echo "Time elapsed: $elapsed min"; ((elapsed++)); sleep 60; done
    '';
  };

  idx.previews = {
    enable = true;
    previews = {
      novnc = {
        manager = "web";
        command = [
          "bash" "-lc"
          "socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:127.0.0.1:6901"
        ];
      };
    };
  };
}
