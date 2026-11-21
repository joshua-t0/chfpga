#!/usr/bin/env python3
"""Checks the Ethernet frames written by the rawpack testbenches (one frame per line, in hex).

Each file holds the frames of one 100G link. Verifies, for every frame: the Ethernet/IPv4/UDP
headers (lengths, IP checksum), the raw stream header (format 4), that the packet counter and the
timestamps of each stream are contiguous (no packet lost anywhere in the chain), and every sample
against the testbench pattern: sample number t of channel c has the 14-bit value
(t * (2c + 3) + 1000c) mod 16384 at the input, and it is sent as 12 bits (rounded or truncated, as
the header says).

Verifies, over all the files: that a stream is on its link (streams A and B on the first file,
C and D on the second), and that the packets of all streams with the same packet counter start on
the same sample.

Uses only the Python standard library.  Usage: check_frames.py FILE [FILE ...] [--min-packets N]
"""
import argparse
import sys

WORDS_PER_FRAME = 2048
STREAMS_PER_LINK = 2
NAMES = 'ABCD'


def reduce_sample(value, rounded):
    """ The 12-bit number sent for a 14-bit sample (two's complement, as an unsigned 12-bit value). """
    if value >= 8192:
        value -= 16384
    if rounded:
        value += 2
    return min(value >> 2, 2047) & 0xFFF


def check(paths, min_packets=1):
    expected_ctr = {}      # stream -> packet counter of its next packet
    origin = {}            # stream -> first sample of its packet number 0
    counts = {}
    payload_bytes = 0
    total = 0
    for link, path in enumerate(paths):
        n = 0
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
                if h[0:2] != b'RA' or h[2] != 4:
                    fail('bad magic/version')
                if h[20] != 1:
                    fail(f'run number {h[20]} (expected 1: one run since power-up)')
                if h[21] != 12:
                    fail(f'sample width {h[21]} (expected 12)')
                flags, chan_byte, blocks = h[3], h[4], h[5]
                if flags & 0xC0:
                    fail(f'error flags set (0x{flags:02X})')
                rounded = bool(flags & 2)
                mask = (flags >> 2) & 0xF
                stream, chan = (chan_byte >> 4) & 7, chan_byte & 7
                if not mask & (1 << stream):
                    fail(f'packet of stream {NAMES[stream]}, which is not enabled (mask 0x{mask:X})')
                if stream // STREAMS_PER_LINK != link and len(paths) > 1:
                    fail(f'packet of stream {NAMES[stream]} on link {link}')
                dest_port = int.from_bytes(frame[36:38], 'big')
                ctr = int.from_bytes(h[6:12], 'big')
                first_sample = (int.from_bytes(h[12:18], 'big') * WORDS_PER_FRAME + int.from_bytes(h[18:20], 'big')) * 8
                data = frame[64:]
                if len(data) != 96 * blocks:
                    fail(f'{len(data)} sample bytes, expected {96 * blocks}')
                samples = blocks * 64

                if stream not in expected_ctr:
                    if int.from_bytes(h[18:20], 'big') != 0:
                        fail('the stream does not start on a frame boundary')
                    if ctr != 0:
                        fail(f'the first packet of stream {NAMES[stream]} has packet counter {ctr}')
                    origin[stream] = (first_sample, dest_port)
                elif ctr != expected_ctr[stream]:
                    fail(f'stream {NAMES[stream]}: packet counter {ctr}, expected {expected_ctr[stream]}: {ctr - expected_ctr[stream]} packet(s) lost')
                if first_sample != origin[stream][0] + ctr * samples:
                    fail(f'stream {NAMES[stream]}: first sample {first_sample}, expected {origin[stream][0] + ctr * samples}')
                if dest_port != origin[stream][1]:
                    fail(f'stream {NAMES[stream]}: UDP destination port {dest_port}, was {origin[stream][1]}')
                expected_ctr[stream] = ctr + 1

                # 2 samples per 3 bytes, little-endian bit stream, one channel in time order
                i = 0
                for g in range(0, len(data), 3):
                    w = int.from_bytes(data[g:g + 3], 'little')
                    for k in range(2):
                        got = (w >> (12 * k)) & 0xFFF
                        t = first_sample + i
                        expected = reduce_sample((t * (2 * chan + 3) + 1000 * chan) % 16384, rounded)
                        if got != expected:
                            fail(f'sample {i} (channel {chan}, t={t}): got {got}, expected {expected}')
                        i += 1
                n += 1
                counts[stream] = counts.get(stream, 0) + 1
                payload_bytes += len(data)
        total += n
    if total < min_packets:
        sys.exit(f'{", ".join(paths)}: only {total} packets, expected at least {min_packets}')
    if len({first for first, _ in origin.values()}) > 1:
        sys.exit('The streams do not start on the same sample: ' + ', '.join(f'{NAMES[s]}: {origin[s][0]}' for s in sorted(origin)))
    ports = sorted(port for _, port in origin.values())
    if len(set(ports)) != len(ports):
        sys.exit(f'Two streams have the same UDP destination port: {ports}')
    if max(counts.values()) - min(counts.values()) > 1:
        sys.exit('Packets of each stream: ' + ', '.join(f'{NAMES[s]}: {counts[s]}' for s in sorted(counts)))
    print(f'{", ".join(paths)}: {total} packets OK (' + ', '.join(f'{counts[s]} of stream {NAMES[s]} on port {origin[s][1]}' for s in sorted(counts))
          + f'), {payload_bytes * 8 // 12} samples checked, no packet lost, all streams start on sample {next(iter(origin.values()))[0]}')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('files', nargs='+', help='one file for each link, link 0 first')
    p.add_argument('--min-packets', type=int, default=1)
    a = p.parse_args()
    check(a.files, a.min_packets)
