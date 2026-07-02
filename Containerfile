FROM quay.io/centos/centos:stream10


RUN true \
    && dnf install -y 'dnf-command(copr)' \
    && dnf copr enable -y phlogistonjohn/sambacc-extras-deps \
    && dnf install -y 'python3-pykmip' \
    && dnf clean all \
    && true


RUN mkdir -p /etc/kmip/tls /var/lib/kmip/policy /var/log/kmip
ADD kmip.server.conf /etc/kmip/server.conf

ADD ktc.py /usr/local/bin/ktc.py
RUN chmod 0755 /usr/local/bin/ktc.py



ENTRYPOINT ["pykmip-server"]
CMD ["-l", "/var/log/kmip/log", "-f", "/etc/kmip/server.conf"]
