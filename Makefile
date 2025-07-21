

image:
	podman build -t quay.io/phlogistonjohn/asdf:kmip .


prepare:
	mkdir -p _tls _data/policy

run: prepare
	podman run -it -v $$PWD/_tls:/etc/kmip/tls  -v $$PWD/_data:/var/lib/kmip   -p 5696:5696  quay.io/phlogistonjohn/asdf:kmip

