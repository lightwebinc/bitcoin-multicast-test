#!/usr/bin/env python3
import socket, struct, time

IFACE = 'enp6s0'
GROUPS = ['ff05::1', 'ff05::3']

socks = []
for g in GROUPS:
    s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    s.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_MULTICAST_HOPS, 5)
    idx = socket.if_nametoindex(IFACE)
    mreq = socket.inet_pton(socket.AF_INET6, g) + struct.pack('I', idx)
    s.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_JOIN_GROUP, mreq)
    socks.append(s)
    print(f"Joined {g} on {IFACE}", flush=True)

while True:
    time.sleep(60)
