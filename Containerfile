FROM quay.io/centos/centos:stream9


RUN true \
    && dnf install -y 'dnf-command(copr)' \
    && dnf copr enable -y phlogistonjohn/sambacc-extras-deps centos-stream+epel-next-9-x86_64 \
    && dnf install -y 'python3-pykmip' \
    && true


RUN mkdir -p /etc/kmip/tls /var/lib/kmip/policy /var/log/kmip
ADD kmip.server.conf /etc/kmip/server.conf



ENTRYPOINT ["pykmip-server"]
CMD ["-l", "/var/log/kmip/log", "-f", "/etc/kmip/server.conf"]
