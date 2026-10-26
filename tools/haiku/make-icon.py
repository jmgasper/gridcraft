#!/usr/bin/env python3
"""Original Haiku spreadsheet ledger. Rebuild with python3 tools/haiku/make-icon.py."""
from icon_art import Drawing, INK, plane

d = Drawing()
p = plane(7, 7)
d.shadow([(7,43),(46,57),(62,57),(32,43)])
d.shape([(46,21),(50,17),(50,53),(46,57)], d.gradient('509b71','27533f'), INK)
d.shape(p([(0,0),(39,0),(39,36),(0,36)]), d.gradient('fffff6','d8e5d8'), INK)
d.shape(p([(0,0),(39,0),(39,8),(0,8)]), d.gradient('a5d8ad','439262'))
d.shape(p([(0,8),(7,8),(7,36),(0,36)]), 'b4cdbb')
for v in (8,17,26):
    d.line(p([(0,v),(39,v)]), '738d7c', 1.3)
for u in (7,18,29):
    d.line(p([(u,8),(u,36)]), '738d7c', 1.3)
d.shape(p([(18,17),(29,17),(29,26),(18,26)]), d.gradient('e1f3bd','a3ca78'), '285d42', 2)
d.shape(p([(27,24),(31,24),(31,28),(27,28)]), '285d42')
d.line(p([(4,4),(16,4)]), 'f7fff3', 2)
# Three broad chart columns remain distinct at 16px.
d.shape([(36,47),(42,49),(42,59),(36,57)], d.gradient('a9d9b0','4e996a'), INK, 1.5)
d.shape([(43,42),(49,44),(49,59),(43,57)], d.gradient('9cd3a4','387c54'), INK, 1.5)
d.shape([(50,35),(56,37),(56,59),(50,57)], d.gradient('f3d987','c69432'), INK, 1.5)
d.save(__file__, 'gridcraft', 'GridCraft')
