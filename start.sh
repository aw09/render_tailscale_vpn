#!/bin/sh

# Set the port for the dummy web server
DUMMY_WEB_PORT=${PORT:-10000} # Use Render's $PORT env var if set, otherwise default to 10000

# Start Tailscale daemon in the background
echo "Starting Tailscale daemon..."
./tailscaled \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock \
    --tun=userspace-networking \
    --socks5-server=localhost:1055 \
    --outbound-http-proxy-listen=localhost:1055 &
TAILSCALED_PID=$! # Store PID of tailscaled

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

# Start a dummy web server in the background
# This listens on the specified port and simply returns a 200 OK for any request
# This specific busybox nc command needs to be in a loop to be persistent
# as it exits after a single connection.
echo "Starting dummy web server on port $DUMMY_WEB_PORT..."
while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Length: 12\r\n\r\nHello Render!" | busybox nc -lp "$DUMMY_WEB_PORT"
done &
DUMMY_WEB_PID=$! # Store PID of the dummy web server process (the `while true` loop)

# The container will now remain alive because the `while true` loop
# running the dummy web server is an active, long-running process.
# We don't need `sleep infinity` anymore as the dummy web server keeps it alive.
# Optionally, if you wanted to monitor the Tailscale daemon and restart if it dies:
# wait $TAILSCALED_PID
# exit $?
