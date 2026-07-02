IMAGE:=quay.io/phlogistonjohn/pykmip:test
KMIP_DIR:=.
KMIP_PORT:=5696

.PHONY: help
help:
	@echo 'Run "make image" to build a container image.'
	@echo 'Run "make run" to run said image.'

.PHONY: image
image:
	podman build -t $(IMAGE) .

.PHONY: run
run: prepare rm-kmip
	podman run \
		--name kmip -d \
		-v $(KMIP_DIR)/_tls:/etc/kmip/tls  \
		-v $(KMIP_DIR)/_data:/var/lib/kmip  \
		-p $(KMIP_PORT):$(KMIP_PORT) \
		$(IMAGE)

.PHONY: rm-kmip
rm-kmip:
	podman stop kmip || exit 0
	podman rm kmip || exit 0

.PHONY: prepare
prepare: $(KMIP_DIR)/_tls/kmip.crt policy

.PHONY: policy
policy: $(KMIP_DIR)/_data/policy/policy.json

.PHONY: purge
purge:
	$(RM) -r $(KMIP_DIR)/_data


$(KMIP_DIR)/_tls/kmip.crt:
	mkdir -p _tls
	@if [ ! -f $@ ] ; then exit 0; fi
	@echo ---NOTE---
	@echo 'Manually copy files kmip.crt, kmip.key, and ca.crt into _tls'
	@echo 'to provide the kmip server with needed TLS credentials.'
	@echo ----------
	@exit 1


$(KMIP_DIR)/_data/policy:
	mkdir -p $(KMIP_DIR)/_data/policy


$(KMIP_DIR)/_data/policy/policy.json: $(KMIP_DIR)/_data/policy
	echo '{' > $@
	echo '  "jjm": {' >> $@
	echo '    "preset": {' >> $@
	echo '      "CERTIFICATE": {"GET":"ALLOW_ALL"},' >> $@
	echo '      "SYMMETRIC_KEY": {"GET":"ALLOW_ALL"},' >> $@
	echo '      "PUBLIC_KEY": {"GET":"ALLOW_ALL"},' >> $@
	echo '      "PRIVATE_KEY": {"GET":"ALLOW_ALL"},' >> $@
	echo '      "SPLIT_KEY": {"GET":"ALLOW_ALL"},' >> $@
	echo '      "SECRET_DATA": {"GET":"ALLOW_ALL"},' >> $@
	echo '      "OPAQUE_DATA": {"GET":"ALLOW_ALL"}' >> $@
	echo '    }' >> $@
	echo '  }' >> $@
	echo '}' >> $@
	jq . < $@
