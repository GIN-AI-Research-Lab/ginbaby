# -*- coding: utf-8 -*-
"""Gỡ từ khoá const ở những biểu thức không còn hằng số được (sau khi màu thành getter). Chạy lặp đến khi hết lỗi."""
import re
import subprocess
import sys

APP = r'F:\Project Ai\GinBaby\app'
FLUTTER = r'F:\dev\flutter\bin\flutter.bat'
ERR = re.compile(r"^\s+error - (.*?) - (lib[\\/][^:]+):(\d+):(\d+) - (\w+)$")
CONST_CODES = {'const_eval_method_invocation', 'const_with_non_constant_argument', 'invalid_constant', 'non_constant_list_element', 'const_initialized_with_non_constant_value'}


def analyze():
    out = subprocess.run([FLUTTER, 'analyze', '--no-pub'], cwd=APP, capture_output=True, text=True, encoding='utf-8').stdout
    errs = []
    for line in out.splitlines():
        m = ERR.match(line)
        if m:
            errs.append((m.group(2).replace('\\', '/'), int(m.group(3)), int(m.group(4)), m.group(5), m.group(1)))
    return errs


def offset(text, line, col):
    pos = 0
    for _ in range(line - 1):
        pos = text.index('\n', pos) + 1
    return pos + col - 1


def match_close(text, i):
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack = []
    n = len(text)
    j = i
    in_str = None
    while j < n:
        c = text[j]
        if in_str:
            if c == '\\':
                j += 2
                continue
            if c == in_str:
                in_str = None
        elif c in '\'"':
            in_str = c
        elif c in pairs:
            stack.append(pairs[c])
        elif c in ')]}':
            if stack and stack[-1] == c:
                stack.pop()
                if not stack:
                    return j
        j += 1
    return n


def enclosing_consts(text, off):
    """Các vị trí 'const' bao quanh offset, từ trong ra ngoài."""
    res = []
    for m in re.finditer(r"\bconst\b", text[:off]):
        st = m.start()
        # tìm dấu ngoặc đầu tiên sau const (trước dấu ; hoặc =>)
        k = m.end()
        while k < len(text) and text[k] not in '([{;':
            k += 1
        if k >= len(text) or text[k] == ';':
            continue
        end = match_close(text, k)
        if st < off <= end:
            res.append((st, end))
    res.sort(key=lambda x: -x[0])  # trong cùng trước
    return res


def main():
    for it in range(40):
        errs = [e for e in analyze() if e[3] in CONST_CODES]
        print('round', it, 'const errors:', len(errs))
        if not errs:
            return
        by_file = {}
        for e in errs:
            by_file.setdefault(e[0], []).append(e)
        for f, es in by_file.items():
            path = APP + '\\' + f.replace('/', '\\')
            text = open(path, encoding='utf-8').read()
            cuts = set()
            for (_, line, col, code, msg) in es:
                off = offset(text, line, col)
                enc = enclosing_consts(text, off)
                if enc:
                    cuts.add(enc[0][0])
            for st in sorted(cuts, reverse=True):
                if text[st:st + 6] != 'const ':
                    continue
                head = text[st:st + 120]
                if re.match(r"const\s+(?:[\w<>,? ()]+\s+)?\w+\s*=", head) and (text[max(0, st - 7):st] == 'static ' or text[st - 1:st] == chr(10)):
                    text = text[:st] + 'final' + text[st + 5:]  # khai báo hằng -> final
                else:
                    text = text[:st] + text[st + 6:]
            open(path, 'w', encoding='utf-8').write(text)


main()
