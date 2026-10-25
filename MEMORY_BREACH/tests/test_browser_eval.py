import importlib.util
import json
from pathlib import Path
path = Path(__file__).resolve().parents[1] / "python_runtime/browser_eval.py"
spec = importlib.util.spec_from_file_location("browser_eval", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
for code, expected in [("print(a ^ b)", 10), ("import math; math.sqrt(81)", 9),
                       ("x=40; x+2", 42), ("x+3", 43), ("a+2*b", 27)]:
    result = json.loads(module._memory_breach_eval(code, 13, 7))
    assert result["ok"] and result["numeric"] == expected, result
for code, error in [("asfddfs", "NameError"), ("1/0", "ZeroDivisionError"),
                    ("input('x')", "RuntimeError"), ("print('x'*40000)", "output limit")]:
    result = json.loads(module._memory_breach_eval(code, 13, 7))
    assert not result["ok"] and error.lower() in result["output"].lower(), result
print("PASS: 9 Python evaluator checks")
