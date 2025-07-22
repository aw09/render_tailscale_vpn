#!/bin/sh

# Set the port for the dummy web server
DUMMY_WEB_PORT=${PORT:-10000}

# Create a simple index.html file for the web server
echo "Hello Render! Tailscale is running." > /tmp/index.html

# Start Tailscale daemon in the background
echo "Starting Tailscale daemon..."
./tailscaled \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock \
    --tun=userspace-networking \
    --socks5-server=localhost:1055 \
    --outbound-http-proxy-listen=localhost:1055 &

# Wait for tailscaled to be ready and bring up the interface
echo "Bringing Tailscale up..."
until ./tailscale up \
    --authkey="${TAILSCALE_AUTHKEY}" \
    --hostname="${TAILSCALE_HOSTNAME}" \
    --advertise-exit-node \
    ${TAILSCALE_ADDITIONAL_ARGS}
do
    sleep 0.1
done

# Start busybox httpd in the background
# -p specifies the port, -h specifies the document root
echo "Starting persistent dummy web server on port $DUMMY_WEB_PORT..."
busybox httpd -f -p "$DUMMY_WEB_PORT" -h /tmp &

# Keep the script running by waiting for the httpd process.
# This ensures the container doesn't exit.
wait $!
