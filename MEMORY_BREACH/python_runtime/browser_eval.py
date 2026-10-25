"""Persistent evaluator for the browser-only worker; never runs on a host server."""
import ast
import contextlib
import io
import json
import math
import traceback

def _no_input(*args, **kwargs):
    raise RuntimeError("input() is unavailable; enter values in the game terminal.")

_scope = {"__name__": "__console__", "input": _no_input}

class _Output(io.StringIO):
    def write(self, text):
        if self.tell() + len(text) > 32000:
            raise RuntimeError("Terminal output limit reached (32000 characters).")
        return super().write(text)

def _memory_breach_eval(source, a, b):
    _scope.update(a=a, b=b)
    source = source.strip()
    if source.startswith(">>>"):
        source = source[3:].strip()
    output = _Output()
    value = None
    success = True
    with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
        try:
            tree = ast.parse(source, "<game-terminal>", "exec")
            if tree.body and isinstance(tree.body[-1], ast.Expr):
                last = tree.body.pop()
                exec(compile(tree, "<game-terminal>", "exec"), _scope, _scope)
                value = eval(compile(ast.Expression(last.value), "<game-terminal>", "eval"), _scope, _scope)
                if value is not None:
                    print(repr(value))
            else:
                exec(compile(tree, "<game-terminal>", "exec"), _scope, _scope)
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
                if math.isfinite(value):
                    numeric = value
            except (ValueError, OverflowError):
                pass
        elif value is None and text.strip():
            try:
                candidate = float(text.strip().splitlines()[-1])
                if math.isfinite(candidate):
                    numeric = candidate
            except ValueError:
                pass
    return json.dumps({"ok": success, "numeric": numeric, "output": text}, allow_nan=False)
