# policy_gate

**One capability bit from GBT V8, packaged standalone.** No. 139 of 341,
`llm` domain (LLM).

<p>
<img alt="python" src="https://img.shields.io/badge/python-3.9%2B-blue">
<img alt="license" src="https://img.shields.io/badge/license-MIT-green">
<img alt="deps" src="https://img.shields.io/badge/runtime%20dependencies-0-brightgreen">
</p>

> **权限／付款直答门**（fact_gate 同族 · 主人令「拿实质性证据说话」）：能不能做／要不要授权**也是事实**，不该过模型。实测病根：终考里「买 4090」不是机器事实 ⇒ 没过 fact_gate ⇒ 模型又编市场数据（编出「本机 4194x2 已满」「4090 价格带 150-250 元」+ 一个 URL）。做法：① 现读**真门** `auth_gate.SCOPES` 原文 → ② 意图与真表描述对一遍 + 意图对照（**真表过滤**，表里没有的作用域绝不出现）→ ③ 代码判定命中哪些作用域／哪些一次性 → ④ 直答，模型只许在后面加「所以怎么办」。付款类再钉一句：**市场价／库存／商家／型号一律不许编**。op=classify/answer

That description is copied verbatim from the registry. `tests/test_spec.py` pins it,
so documentation drift fails the build instead of shipping quietly.

## What this package actually is

It is the **contract** for one capability: its name, its parameters, the values it
accepts, and whether it can change state that cannot be restored. It is not the
implementation — that lives in the runtime this bit was extracted from.

So `run()` goes through a narrow `Backend` protocol, and the default backend is a
stub that **says so**:

```
status="validated"   backend="stub"   data={"executed": false}
```

Never `status="ok"`. A stub that reports success is worse than no stub, because the
caller stops looking for the real thing.

## Install

```bash
git clone https://github.com/gbtweilai-star/gbt-policy-gate.git
cd gbt-policy-gate
python -m pip install -e ".[dev]"
```

## Use

```bash
python -m gbt_policy_gate info                  # capability card
python -m gbt_policy_gate spec --json           # machine-readable contract
python -m gbt_policy_gate check --payload '{}'
python -m gbt_policy_gate run   --payload '{}'
```

Real `info` output from this machine:

```text
policy_gate  (llm)  v1.0.0
----------------------------------------
**权限／付款直答门**（fact_gate 同族 · 主人令「拿实质性证据说话」）：能不能做／要不要授权**也是事实**，不该过模型。实测病根：终考里「买 4090」不是机器事实 ⇒ 没过 fact_gate ⇒ 模型又编市场数据（编出「本机 4194x2 已满」「4090 价格带 150-250 元」+ 一个 URL）。做法：① 现读**真门** `auth_gate.SCOPES` 原文 → ② 意图与真表描述对一遍 + 意图对照（**真表过滤**，表里没有的作用域绝不出现）→ ③ 代码判定命中哪些作用域／哪些一次性 → ④ 直答，模型只许在后面加「所以怎么办」。付款类再钉一句：**市场价／库存／商家／型号一律不许编**。op=classify/answer

gated      : False
external   : False
multi-op   : True
params     : (none)
values     : (multi-op, but the registry does not enumerate them)
```

Wire a real implementation:

```python
from gbt_policy_gate import run

class MyBackend:
    name = "my-backend"
    def invoke(self, cap, payload):
        return {"cap": cap, "handled": sorted(payload)}

result = run({}, backend=MyBackend())
assert result.status == "ok"
```

## Parameters

| name | required | notes |
|---|---|---|
| — | no | the registry declares no required parameters |

Registry hint (`params_hint`): (empty)

**注册表标注 `multi_op: true`，但没有枚举具体取值。**本包不替它编造取值清单——这种缺口应当在注册表源头补，而不是在文档里圆。

Types are deliberately absent: the registry does not declare them, and an invented
type is worse than no type, because callers believe it.

## Boundaries

- Not gated: the registry marks this bit `safe: true`.
- No external service dependency declared.
- Multi-op (`multi_op: true`): several sub-actions share one name — read `op` before calling.
- No implementation ships here. Bring a backend; the protocol is one method.

## What this is not

Not a wrapper around a hosted API. Not a model. Not a promise that calling it does
anything on its own. It is the typed seam plus the validation, which is the part that
stays correct even when the implementation changes.

## Tests

```bash
python -m pytest
```

```text
20 passed, 3 skipped in 0.12s
```

## Provenance

| field | value |
|---|---|
| capability | `policy_gate` |
| domain | `llm` |
| handler | `policy_gate` |
| safe | `True` (gated = `False`) |
| external | `False` |
| atlas page | [llm/policy_gate](https://github.com/gbtweilai-star/gbt-caps/blob/main/caps/llm/policy_gate.md) |
| full index | [https://github.com/gbtweilai-star/gbt-caps](https://github.com/gbtweilai-star/gbt-caps) |

The parent README says 348 capabilities; an AST pass over the registry enumerates
`341 + 0 unimplemented + 0 disabled = 341`. The extra 7 are historical duplicates.
Numbering here follows 341 and matches the `gbt-caps` index one-to-one.

## License

MIT.
