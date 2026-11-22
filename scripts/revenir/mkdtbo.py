#!/usr/bin/env python3
"""Minimal Android DTBO (dt_table) image tool: dump and create (version 0)."""
import struct, sys
MAGIC = 0xd7b7ab1e
def dump(path):
    b = open(path, 'rb').read()
    magic, total, hsz, esz, cnt, eoff, page, ver = struct.unpack('>8I', b[:32])
    print(f"magic={magic:#x} total={total} hdr={hsz} entry={esz} count={cnt} off={eoff} page={page} ver={ver}")
    for i in range(cnt):
        sz, off, id_, rev, *cust = struct.unpack('>8I', b[eoff+i*esz:eoff+i*esz+32])
        print(f" [{i}] size={sz} off={off} id={id_:#x} rev={rev:#x} custom={[hex(c) for c in cust]}")
def create(out, dtbos, page=4096):
    cnt = len(dtbos); hsz = esz = 32
    eoff = hsz; off = hsz + esz*cnt
    blobs = [open(p,'rb').read() for p in dtbos]
    entries = b''; data = b''
    for bl in blobs:
        entries += struct.pack('>8I', len(bl), off + len(data), 0, 0, 0, 0, 0, 0)
        data += bl
    total = off + len(data)
    hdr = struct.pack('>8I', MAGIC, total, hsz, esz, cnt, eoff, page, 0)
    open(out, 'wb').write(hdr + entries + data)
if __name__ == '__main__':
    if sys.argv[1] == 'dump': dump(sys.argv[2])
    elif sys.argv[1] == 'create': create(sys.argv[2], sys.argv[3:])
