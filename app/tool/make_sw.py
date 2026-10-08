"""Tạo build/web/sw.js từ web/sw.template.js: điền mã bản dựng và hai danh sách tệp (CORE để mở app, REST lưu sau).
Mỗi tệp ghi dạng [đường dẫn, mã băm ngắn, dung lượng] để bản sau chỉ tải những tệp thay đổi."""
import hashlib
import json
import os
import sys

app = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
build = os.path.join(app, 'build', 'web')
stamp = sys.argv[1] if len(sys.argv) > 1 else 'dev'

SKIP_NAMES = {'sw.js', 'sw.template.js', 'version.json', 'flutter_service_worker.js', '.last_build_id', 'offline-check.html'}
SKIP_PREFIX = ('canvaskit/skwasm', 'canvaskit/wimp', 'canvaskit/webparagraph')
SKIP_SUFFIX = ('.map', '.symbols')
BS = chr(92)


def entry(rel):
    data = open(os.path.join(build, rel), 'rb').read()
    return [rel, hashlib.md5(data).hexdigest()[:10], len(data)]


core, rest = [], []
for root, _, names in os.walk(build):
    rel_root = os.path.relpath(root, build).replace(BS, '/')
    if rel_root == '.':
        rel_root = ''
    for n in names:
        rel = (rel_root + '/' + n) if rel_root else n
        if n in SKIP_NAMES or rel.startswith(SKIP_PREFIX) or rel.endswith(SKIP_SUFFIX):
            continue
        is_rest = rel.startswith('assets/assets/art') or rel.startswith('canvaskit/chromium/')
        (rest if is_rest else core).append(entry(rel))
core.sort()
rest.sort()
# trang gốc "./" dùng nội dung của index.html
idx = next(e for e in core if e[0] == 'index.html')
core.insert(0, ['./', idx[1], idx[2]])

tpl = open(os.path.join(app, 'web', 'sw.template.js'), encoding='utf-8').read()
out = tpl.replace('__STAMP__', stamp).replace('__CORE__', json.dumps(core)).replace('__REST__', json.dumps(rest))
open(os.path.join(build, 'sw.js'), 'w', encoding='utf-8').write(out)


def size(lst):
    return sum(e[2] for e in lst) / 1e6


print('sw.js: core %d tep %.1f MB, rest %d tep %.1f MB' % (len(core), size(core), len(rest), size(rest)))
