#!/usr/bin/env python3
"""Build GridCraft's Haiku vector icon (HVIF) from the app icon's SVG geometry
(assets/app-icon/gridcraft.svg: a green tile, a tilted ledger page with a
folded corner, its header row and grid, a selected cell with its fill handle),
so air/OS's Tracker, Deskbar and window tabs show it sharp at any size.

    python3 tools/haiku/make-icon.py apps/gridcraft-haiku/resources/GridCraft.hvif [preview.png]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hvif  # noqa: E402

S = 64 / 512  # SVG units to the 64 x 64 icon canvas
K = 0.5523    # cubic handle length for a quarter circle
INK, PAPER, GREEN = hvif.hex_color('0b0b0c'), hvif.hex_color('efe9dc'), hvif.hex_color('1f9d55')

icon = {'styles': [], 'paths': [], 'shapes': []}


def style(color):
    icon['styles'].append({'color': color})
    return len(icon['styles']) - 1


def path(points, closed=True):
    icon['paths'].append({'closed': closed, 'points': points})
    return len(icon['paths']) - 1


def shape(style_index, paths, transformers=None):
    icon['shapes'].append({'style': style_index, 'paths': paths, 'transformers': transformers or []})


def stroke(width, cap=0):
    # join 2 = round; cap 2 = round
    return [{'type': 'stroke', 'width': width * S, 'join': 2, 'cap': cap, 'miter': 4}]


def rotated(points, degrees=-6, cx=256, cy=268):
    a = math.radians(degrees)
    c, s = math.cos(a), math.sin(a)
    return [((cx + (x - cx) * c - (y - cy) * s) * S, (cy + (x - cx) * s + (y - cy) * c) * S) for x, y in points]


def rect(x0, y0, x1, y1):
    return rotated([(x0, y0), (x1, y0), (x1, y1), (x0, y1)])


def line(x0, y0, x1, y1):
    return path(rotated([(x0, y0), (x1, y1)]), closed=False)


def rounded_rect(x0, y0, x1, y1, r):
    k = r * K
    return [
        ((x0 + r, y0), (x0 + r - k, y0), (x0 + r, y0)),
        ((x1 - r, y0), (x1 - r, y0), (x1 - r + k, y0)),
        ((x1, y0 + r), (x1, y0 + r - k), (x1, y0 + r)),
        ((x1, y1 - r), (x1, y1 - r), (x1, y1 - r + k)),
        ((x1 - r, y1), (x1 - r + k, y1), (x1 - r, y1)),
        ((x0 + r, y1), (x0 + r, y1), (x0 + r - k, y1)),
        ((x0, y1 - r), (x0, y1 - r + k), (x0, y1 - r)),
        ((x0, y0 + r), (x0, y0 + r), (x0, y0 + r - k)),
    ]


# The tile, inset a little as Haiku icons are.
tile = path(rounded_rect(2, 2, 62, 62, 13))
green = style(GREEN)
shape(green, [tile])

ink, paper = style(INK), style(PAPER)
page = path(rotated([(112, 76), (336, 76), (404, 144), (404, 440), (112, 440)]))
shape(paper, [page])
# The header row and the row-number column, in the app colour.
header = path(rotated([(112, 164), (404, 164), (404, 204), (164, 204), (164, 440), (112, 440)]))
shape(green, [header])
# The grid: fewer rules than the 512 px drawing, which would blur together at 16 px.
grid = [line(112, y, 404, y) for y in (164, 204, 250, 296, 342, 388)]
grid += [line(x, 164, x, 440) for x in (164, 244, 324)]
shape(ink, grid, stroke(8))
shape(ink, [page], stroke(14))
fold = path(rotated([(336, 76), (336, 144), (404, 144)]), closed=False)
shape(ink, [fold], stroke(12))
titles = [line(146, 106, 272, 106), line(146, 130, 232, 130)]
shape(ink, titles, stroke(12, cap=2))
# The selected cell and its fill handle.
cell = path(rect(244, 250, 324, 296))
shape(ink, [cell], stroke(16))
handle = path(rect(312, 284, 336, 308))
shape(ink, [handle])
shape(paper, [handle], stroke(5))
# The double rule under the total.
rules = [line(252, 410, 316, 410), line(252, 424, 316, 424)]
shape(ink, rules, stroke(7, cap=2))

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else 'GridCraft.hvif'
    data = hvif.encode(icon)
    hvif.decode(data)
    with open(out, 'wb') as f:
        f.write(data)
    print('%s: %d bytes' % (out, len(data)))
    if len(sys.argv) > 2:
        hvif.preview(icon, 256, (245, 245, 240, 255)).save(sys.argv[2])
        print(sys.argv[2])
