"""Persistent local interpreter for the game's embedded terminal; no network service."""
import ast
import contextlib
import io
import json
import math
import os
from pathlib import Path
import sys
import time
import traceback

folder = Path(sys.argv[1])
folder.mkdir(parents=True, exist_ok=True)
scope = {'__name__': '__console__'}
def no_input(*args, **kwargs):
    raise RuntimeError('Interactive input() is unavailable; enter values in the game terminal.')
scope['input'] = no_input
class Output(io.StringIO):
    def write(self, text):
        if self.tell() + len(text) > 32000:
            raise RuntimeError('Terminal output limit reached (32000 characters).')
        return super().write(text)

while True:
    request = folder / 'request.json'
    if not request.exists():
        time.sleep(.025)
        continue
    try:
        data = json.loads(request.read_text(encoding='utf-8'))
        request.unlink()
    except (OSError, ValueError):
        time.sleep(.025)
        continue
    scope.update({'a': data['a'], 'b': data['b']})
    source = data['code'].strip()
    if source.startswith('>>>'):
        source = source[3:].strip()
    output = Output()
    value = None
    success = True
    with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
        try:
            tree = ast.parse(source, '<game-terminal>', 'exec')
            if tree.body and isinstance(tree.body[-1], ast.Expr):
                last = tree.body.pop()
                exec(compile(tree, '<game-terminal>', 'exec'), scope, scope)
                value = eval(compile(ast.Expression(last.value), '<game-terminal>', 'eval'), scope, scope)
                if value is not None:
                    print(repr(value))
            else:
                exec(compile(tree, '<game-terminal>', 'exec'), scope, scope)
        except BaseException:
            success = False
            try:
                traceback.print_exc(limit=4)
            except RuntimeError:
                pass
    text = output.getvalue()
    numeric = None
    if success:
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            try:
                if math.isfinite(value): numeric = value
            except (OverflowError, ValueError): pass
        elif value is None and text.strip():
            try:
                candidate = float(text.strip().splitlines()[-1])
                if math.isfinite(candidate): numeric = candidate
            except ValueError: pass
    result = {'id': data['id'], 'ok': success, 'output': text, 'numeric': numeric}
    temp = folder / 'response.tmp'
    temp.write_text(json.dumps(result), encoding='utf-8')
    os.replace(temp, folder / 'response.json')
