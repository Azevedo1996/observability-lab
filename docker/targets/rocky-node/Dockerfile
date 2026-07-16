FROM rockylinux:9

ARG ZABBIX_MAJOR_VERSION=7.4
ARG NODE_EXPORTER_VERSION=1.8.2
ARG TARGETARCH

LABEL org.opencontainers.image.title="Observability Lab Rocky Node Target" \
      org.opencontainers.image.description="Target Rocky Linux 9 com Zabbix Agent e Prometheus Node Exporter" \
      org.opencontainers.image.base.name="rockylinux:9"

ENV TZ=America/Sao_Paulo \
    ZBX_SERVER_HOST=zabbix-server \
    ZBX_SERVER_PORT=10051 \
    ZBX_AGENT_HOSTNAME=rocky-node-target \
    NODE_EXPORTER_LISTEN_ADDRESS=:9100

# Nao executamos dnf update no build do lab para evitar falhas de mirror/timeout.
# O rockylinux:9 ja traz curl-minimal em muitos builds; quando necessario,
# instalamos curl-minimal em vez de curl para evitar conflito com curl-minimal/libcurl-minimal.
RUN dnf -y install \
        ca-certificates \
        curl-minimal \
        procps-ng \
        python3 \
        iproute-tc \
        iptables \
        tar \
        hostname \
        iproute \
        shadow-utils \
        findutils \
    --setopt=install_weak_deps=False \
    --setopt=timeout=60 \
    --setopt=retries=10 \
    && update-ca-trust \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN curl -fsSL --retry 5 --retry-delay 5 --connect-timeout 30 \
        -o /tmp/zabbix-release.rpm \
        "https://repo.zabbix.com/zabbix/${ZABBIX_MAJOR_VERSION}/release/rocky/9/noarch/zabbix-release-latest.el9.noarch.rpm" \
    && rpm -Uvh /tmp/zabbix-release.rpm \
    && dnf -y install zabbix-agent \
        --setopt=install_weak_deps=False \
        --setopt=timeout=60 \
        --setopt=retries=10 \
    && rm -f /tmp/zabbix-release.rpm \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN set -eux; \
    arch="${TARGETARCH:-amd64}"; \
    case "$arch" in \
      amd64) node_arch="amd64" ;; \
      arm64) node_arch="arm64" ;; \
      arm) node_arch="armv7" ;; \
      *) echo "Arquitetura nao suportada para node_exporter: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL --retry 5 --retry-delay 5 --connect-timeout 30 \
      -o /tmp/node_exporter.tar.gz \
      "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${node_arch}.tar.gz"; \
    tar -xzf /tmp/node_exporter.tar.gz -C /tmp; \
    install -m 0755 "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-${node_arch}/node_exporter" /usr/local/bin/node_exporter; \
    ln -sf /usr/local/bin/node_exporter /usr/local/bin/prometheus-node-exporter; \
    useradd --system --no-create-home --shell /sbin/nologin node_exporter; \
    rm -rf /tmp/node_exporter* /tmp/*.tar.gz

COPY config/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
COPY config/node-exporter/node-exporter.env /etc/default/node-exporter
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 0644 /etc/zabbix/zabbix_agentd.conf /etc/default/node-exporter \
    && chmod 0755 /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/run/zabbix /var/log/zabbix \
    && chown -R zabbix:zabbix /var/run/zabbix /var/log/zabbix /etc/zabbix

EXPOSE 10050 9100

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=20s \
  CMD curl -fsS http://127.0.0.1:9100/metrics >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
