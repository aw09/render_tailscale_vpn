FROM alpine:3.18.3

# Setup tailscale
WORKDIR /tailscale.d

COPY start.sh /tailscale.d/start.sh

ENV TAILSCALE_VERSION "latest"
ENV TAILSCALE_HOSTNAME "render-exit-node"
ENV TAILSCALE_ADDITIONAL_ARGS ""

# Install Tailscale, ca-certificates, iptables, ip6tables,
# and crucially, busybox-extras (which includes httpd).
# Ensure busybox-extras is definitively installed.
RUN apk update && \
    apk add --no-cache ca-certificates iptables ip6tables busybox-extras && \
    wget https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz && \
    tar xzf tailscale_${TAILSCALE_VERSION}_amd64.tgz --strip-components=1 && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

RUN chmod +x ./start.sh

# Expose the port Render expects for web services
EXPOSE 10000

CMD ["./start.sh"]
