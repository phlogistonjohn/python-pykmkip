

image:
	podman build -t quay.io/phlogistonjohn/asdf:kmip .


prepare:
	mkdir -p _tls _data/policy
	@echo ---NOTE---
	@echo 'Copy files kmip.crt, kmip.key, and ca.crt into _tls'
	@echo 'to provide the kmip server with needed TLS credentials.'
	@echo ----------

run: prepare
	podman run -it -v $$PWD/_tls:/etc/kmip/tls  -v $$PWD/_data:/var/lib/kmip   -p 5696:5696  quay.io/phlogistonjohn/asdf:kmip

