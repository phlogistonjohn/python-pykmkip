import argparse
import base64
import sys
import time
import uuid

from kmip.pie.client import ProxyKmipClient, enums
from kmip.core.factories import attributes


def parse_cli():
    parser = argparse.ArgumentParser()
    parser.add_argument("--locate")
    parser.add_argument("--get")
    parser.add_argument("--create-symmetric-key", type=int)
    parser.add_argument("--upload-opaque", type=str)
    parser.add_argument("--name")
    parser.add_argument("--policy")
    parser.add_argument(
        "--tls-cert",
        default="_tls/client.crt",
    )
    parser.add_argument(
        "--tls-key",
        default="_tls/client.key",
    )
    parser.add_argument(
        "--tls-ca-cert",
        default="_tls/ca.crt",
    )
    parser.add_argument("--host", default="192.168.76.1")
    parser.add_argument("--port", default=5696, type=int)
    return parser.parse_args()


def gen_ops(ctx):
    if ctx.create_symmetric_key is not None:
        yield op_create_symmetric_key
    if ctx.upload_opaque is not None:
        yield upload_opaque
    if ctx.locate:
        yield op_locate
    if ctx.get:
        yield op_get


def op_locate(ctx, client):
    params = {}
    parts = ctx.locate.split(",")
    for part in parts:
        if "=" not in part:
            params["name"] = part
        else:
            pkey, pvalue = part.split("=", 1)
            params[pkey] = pvalue

    af = attributes.AttributeFactory()
    attrs = []
    if "name" in params:
        attrs.append(
            af.create_attribute(enums.AttributeType.NAME, params["name"])
        )

    matches = client.locate(
        maximum_items=None if "max" not in params else int(params["max"]),
        offset_items=(
            None if "offset" not in params else int(params["offset"])
        ),
        attributes=attrs,
    )
    matches = list(matches)
    if not matches:
        print("No matches.")
        return
    for match in matches:
        print("Match:", match)

    if ctx.get and ctx.get == ".":
        ctx.get = matches[0]


def op_create_symmetric_key(ctx, client):
    size = ctx.create_symmetric_key or 512
    policy = ctx.policy or "default"
    name = ctx.name or None
    print(f"Creating key ({size})")
    key_id = client.create(
        enums.CryptographicAlgorithm.AES,
        size,
        operation_policy_name=policy,
        name=name,
        cryptographic_usage_mask=[
            enums.CryptographicUsageMask.ENCRYPT,
            enums.CryptographicUsageMask.DECRYPT,
        ],
    )
    print("Created:", key_id)
    _auto_get(ctx, key_id)


def upload_opaque(ctx, client):
    from kmip.pie import objects

    data = base64.b64decode(ctx.upload_opaque)
    name = ctx.name or str(uuid.uuid4())
    print(f"Creating opaque object")
    oo = objects.OpaqueObject(
        data,
        enums.OpaqueDataType.NONE,
        name=name,
    )
    if ctx.policy:
        oo.operation_policy_name = ctx.policy
    key_id = client.register(oo)
    print("Created:", key_id)
    _auto_get(ctx, key_id)


def _auto_get(ctx, key_id):
    if ctx.get and ctx.get == ".":
        ctx.get = key_id


def op_get(ctx, client):
    key_id = ctx.get
    print("Get:", key_id)
    val = client.get(key_id)
    print("object=", repr(val))
    print("b64=", base64.b64encode(val.value).decode())


def main():
    ctx = parse_cli()
    client = ProxyKmipClient(
        hostname=ctx.host,
        port=ctx.port,
        cert=ctx.tls_cert,
        key=ctx.tls_key,
        ca=ctx.tls_ca_cert,
        kmip_version=enums.KMIPVersion.KMIP_1_2,
    )
    with client:
        for op in gen_ops(ctx):
            op(ctx, client)


if __name__ == "__main__":
    main()
