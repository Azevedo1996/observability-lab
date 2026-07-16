FROM rockylinux:9

LABEL maintainer="Observability Lab"       org.opencontainers.image.title="Observability Lab Rocky Linux 9 Base"       org.opencontainers.image.description="Imagem base para customizacoes futuras do laboratorio de observabilidade."

ENV TZ=America/Sao_Paulo

RUN dnf -y update     && dnf -y install         ca-certificates         curl         iproute         procps-ng         tar         unzip         vim-minimal     && dnf clean all     && rm -rf /var/cache/dnf

WORKDIR /opt/observability-lab

CMD ["/bin/bash"]
