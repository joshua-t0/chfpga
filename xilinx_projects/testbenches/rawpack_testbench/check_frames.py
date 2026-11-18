#!/usr/bin/env python3
"""Checks the Ethernet frames written by the rawpack testbenches (one frame per line, in hex).

Verifies, for every frame: the Ethernet/IPv4/UDP headers (lengths, IP checksum), the raw stream
header, that the packet counter and the timestamps are contiguous (no packet lost anywhere in the
chain), and every sample against the testbench pattern: sample number t of channel c has the
14-bit value (t * (2c + 3) + 1000c) mod 16384 at the input, and its 12 MSBs are sent.

Uses only the Python standard library.  Usage: check_frames.py FILE [--min-packets N]
"""
import argparse
import sys

WORDS_PER_FRAME = 2048


def check(path, min_packets=1):
    expected_ctr = None
    expected_sample = None
    n = 0
    payload_bytes = 0
    with open(path) as f:
        for lineno, line in enumerate(f, 1):
            frame = bytes.fromhex(line.strip())

            def fail(msg):
                sys.exit(f'{path}:{lineno}: packet {n}: {msg}')

            if len(frame) < 64:
                fail(f'frame too short ({len(frame)} bytes)')
            if frame[12:14] != b'\x08\x00':
                fail('not IPv4')
            ip = frame[14:34]
            if ip[0] != 0x45 or ip[9] != 17:
                fail('not a plain IPv4/UDP header')
            if int.from_bytes(ip[2:4], 'big') != len(frame) - 14:
                fail(f'IP length {int.from_bytes(ip[2:4], "big")} does not match the frame ({len(frame) - 14})')
            s = sum(int.from_bytes(ip[i:i + 2], 'big') for i in range(0, 20, 2))
            s = (s & 0xFFFF) + (s >> 16)
            s = (s & 0xFFFF) + (s >> 16)
            if s != 0xFFFF:
                fail('bad IP header checksum')
            if int.from_bytes(frame[38:40], 'big') != len(frame) - 34:
                fail('bad UDP length')
            h = frame[42:64]
            if h[0:2] != b'RA' or h[2] != 2:
                fail('bad magic/version')
            if h[20] != 1 or h[21] != 0:
                fail(f'stream number {h[20]} (expected 1: single stream since power-up), reserved byte {h[21]}')
            flags, chans, blocks = h[3], h[4], h[5]
            if flags & 0xC0:
                fail(f'error flags set (0x{flags:02X})')
            single = bool(flags & 4)
            chan_a, chan_b = chans & 7, (chans >> 4) & 7
            ctr = int.from_bytes(h[6:12], 'big')
            first_sample = (int.from_bytes(h[12:18], 'big') * WORDS_PER_FRAME + int.from_bytes(h[18:20], 'big')) * 8
            data = frame[64:]
            if len(data) != 96 * blocks:
                fail(f'{len(data)} sample bytes, expected {96 * blocks}')
            sample_times = blocks * (64 if single else 32)

            if expected_ctr is None:
                if int.from_bytes(h[18:20], 'big') != 0:
                    fail('the stream does not start on a frame boundary')
            else:
                if ctr != expected_ctr:
                    fail(f'packet counter {ctr}, expected {expected_ctr}: {ctr - expected_ctr} packet(s) lost')
                if first_sample != expected_sample:
                    fail(f'first sample {first_sample}, expected {expected_sample}')
            expected_ctr = ctr + 1
            expected_sample = first_sample + sample_times

            # 2 samples per 3 bytes, little-endian bit stream
            i = 0
            for g in range(0, len(data), 3):
                w = int.from_bytes(data[g:g + 3], 'little')
                for k in range(2):
                    got = (w >> (12 * k)) & 0xFFF
                    if single:
                        c, t = chan_a, first_sample + i
                    else:
                        c, t = (chan_a, chan_b)[i & 1], first_sample + (i >> 1)
                    expected = ((t * (2 * c + 3) + 1000 * c) % 16384) >> 2
                    if got != expected:
                        fail(f'sample {i} (channel {c}, t={t}): got {got}, expected {expected}')
                    i += 1
            n += 1
            payload_bytes += len(data)
    if n < min_packets:
        sys.exit(f'{path}: only {n} packets, expected at least {min_packets}')
    print(f'{path}: {n} packets OK, {payload_bytes * 8 // 12} samples checked, no packet lost')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('file')
    p.add_argument('--min-packets', type=int, default=1)
    a = p.parse_args()
    check(a.file, a.min_packets)
