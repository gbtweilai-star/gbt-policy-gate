# policy_gate · 模型域能力位

> **用途一句话**：**权限／付款直答门**

<p>
<img alt="python" src="https://img.shields.io/badge/python-3.9%2B-blue">
<img alt="license" src="https://img.shields.io/badge/license-MIT-green">
<img alt="deps" src="https://img.shields.io/badge/runtime%20dependencies-0-brightgreen">
<img alt="capability" src="https://img.shields.io/badge/capability-139%20%2F%20341-orange">
</p>

这是 **GBT V8 的 341 个原生能力位中的第 139 个**（模型域 · `llm`），
单独抽出来做成的独立仓库：可安装、可测试、零运行时依赖。

---

## 一、这一位是什么

> **权限／付款直答门**（fact_gate 同族 · 主人令「拿实质性证据说话」）：能不能做／要不要授权**也是事实**，不该过模型。实测病根：终考里「买 4090」不是机器事实 ⇒ 没过 fact_gate ⇒ 模型又编市场数据（编出「本机 4194x2 已满」「4090 价格带 150-250 元」+ 一个 URL）。做法：① 现读**真门** `auth_gate.SCOPES` 原文 → ② 意图与真表描述对一遍 + 意图对照（**真表过滤**，表里没有的作用域绝不出现）→ ③ 代码判定命中哪些作用域／哪些一次性 → ④ 直答，模型只许在后面加「所以怎么办」。付款类再钉一句：**市场价／库存／商家／型号一律不许编**。op=classify/answer

上面这句是**注册表原文**，逐字复制，没有改写。`tests/test_spec.py` 会把它钉死——
描述漂移会让测试失败，而不是悄悄发版。

---

## 二、用途：它解决什么问题

### 2.1 这一域在管什么

多模型接入与调度：密钥池（model_key_pool / key_gateway / automation_keys）、路由与降级（brain_route / warm_switch / auto_switch 相邻位）、跨供应商适配（claude_code / codebuddy / codex_* / freellmapi / cloud_llm）、以及围绕模型的治理（policy_gate / fact_gate / replan_loop / think_loop）。

### 2.2 为什么这么设计

模型域真正的难题是**上下文与预算**，不是 API 调用。所以这一域里有一半能力位在管「什么时候不该调用模型」——预算耗尽、事实未验证、需要重规划时，正确动作是停下来而不是再发一次请求。

### 2.3 具体到 `policy_gate`

**该用它的时候**：

- 你的任务可以概括为「**权限／付款直答门**」，并且
- 它不需要任何必填参数，可以直接调用，并且
- 你确认它是**可逆**动作（注册表 `safe: true`，不需要逐次授权）。

**不该用它的时候**：

- 你只是想要一个「大概能做这件事」的模糊入口 —— 这一位有明确契约，不是万能入口。
- 你需要它**替你做决定**。它执行，不做价值判断；要不要执行是调用方的事。
- 你希望它自带模型/密钥/机器。它不自带，见 4.5 节接后端。

---

## 三、安装

```bash
git clone https://github.com/gbtweilai-star/gbt-policy-gate.git
cd gbt-policy-gate
python -m pip install -e ".[dev]"
```

零运行时依赖，只有 `pytest` 是开发期依赖。

---

## 四、使用方式

### 4.1 看它是什么（人类可读）

```bash
python -m gbt_policy_gate info
```

真实输出（本机捕获，非示意）：

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

### 4.2 看它的契约（机器可读）

```bash
python -m gbt_policy_gate spec --json
```

输出是一个 JSON 对象，字段与注册表一一对应：`name` / `domain` / `desc` / `handler` /
`safe` / `gated` / `external` / `requires_params` / `params` / `params_hint` /
`multi_op` / `ops` / `ops_hint`。下游可以直接拿它做能力发现，不需要读文档。

### 4.3 只校验、不执行

```bash
python -m gbt_policy_gate check --payload '{}'
```

`check` 永远不会抛异常，只返回「哪里不满足契约」。适合在花掉一次模型调用之前，
先把缺的参数摆给用户看。退出码：`0` 通过、`1` 契约不满足、`2` JSON 本身不合法。

### 4.4 执行

```bash
python -m gbt_policy_gate run --payload '{}'
```

默认后端是 **stub**，所以你会拿到这样的信封：

```json
{
  "cap": "policy_gate",
  "status": "validated",
  "backend": "stub",
  "data": { "executed": false, "reason": "no backend wired" },
  "note": "payload checked against the contract; nothing was executed."
}
```

注意 `status` 是 `"validated"` 而**不是** `"ok"`。这是刻意的：一个把 stub 报成成功的库，
会让调用方停止寻找真正的实现。`bool(result)` 对 stub 结果是 `False`。

### 4.5 接上你自己的后端

```python
from gbt_policy_gate import SPEC, run

class MyBackend:
    name = "my-backend"

    def invoke(self, cap, payload):
        # 这里才是真实实现：调模型、调浏览器、调你的服务
        return {"cap": cap, "handled": sorted(payload)}

result = run({}, backend=MyBackend())
assert result.status == "ok"      # 真实后端才会是 ok
print(result.as_dict())
```

也可以进程级注册一次，之后所有 `run()` 都走它：

```python
from gbt_policy_gate.backend import register_backend
register_backend(MyBackend())
```

`Backend` 是一个 `Protocol`，只需要 `name` 属性和 `invoke(cap, payload) -> dict`。
不继承任何基类，你的实现不需要依赖本包。

### 4.6 作为库用

```python
from gbt_policy_gate import SPEC, run
from gbt_policy_gate.core import check

print(SPEC.name, SPEC.domain, SPEC.gated)

problems = check({})
if problems:
    for p in problems:
        print("缺:", p)
else:
    print(run({}).as_dict())
```

---

## 五、参数

| 参数 | 必填 | 说明 |
|---|---|---|
| — | 否 | 注册表未标注必填参数 |

> 注册表原话（`params_hint`）：（空）

**注册表标注 `multi_op: true`，但没有枚举具体取值。**本包不替它编造取值清单——这种缺口应当在注册表源头补，而不是在文档里圆。


**为什么表里只有「必填/否」两档**：注册表只标注了哪些参数是必填的，没有标注类型与取值范围。
本包没有替它编造类型 —— 编造出来的类型比没有类型更危险，因为调用方会相信它。

---

## 六、返回值

`run()` 返回一个不可变的 `Result`：

| 字段 | 类型 | 含义 |
|---|---|---|
| `cap` | `str` | 能力位名，恒等于 `policy_gate` |
| `status` | `str` | `validated`（stub 校验通过）/ `ok`（真实后端执行）/ `error` |
| `backend` | `str` | 实际执行后端的 `name` |
| `data` | `dict` | 后端返回的原始字典 |
| `note` | `str` | 人类可读的补充说明（stub 会在这里说明自己没执行） |
| `elapsed_ms` | `float` | 后端耗时 |

`Result.as_dict()` 可直接 `json.dumps`。

---

## 七、边界与注意

- **多位一体**（注册表 `multi_op: true`）。同一个能力名下挂着多个子动作，调用前必须读清楚 `op` 的含义，否则「调对了能力、用错了动作」是最常见的误用。
- **本包不含真实实现**。这是刻意设计：真实实现依附于原运行时（模型、密钥、机器）。本包发布的是契约、校验、CLI 与类型接缝；接上你自己的 `Backend` 就能跑。

---

## 八、它不会做什么

- **不会假装执行成功**。默认 stub 的 `status` 是 `validated`，`executed` 是 `false`。
- **不会替你决定要不要执行**。授权是人的动作，不是库的动作。
- **不会编造参数类型**。注册表没写的，本包也不写。
- **不会静默吞掉错误**。后端抛异常就往上抛，返回非 dict 就报 `CapError`。
- **不会联网**。零运行时依赖，`run()` 只调用你给的后端。

---

## 九、测试

```bash
python -m pytest
```

真实输出：

```text
20 passed, 3 skipped in 0.12s
```

测试里有一条**漂移守卫**：`test_description_is_verbatim` 把 `SPEC.desc` 与注册表快照逐字比对。
描述被改了一个字，构建立刻失败。

---

## 十、出处与核对

| 项 | 值 |
|---|---|
| 能力位名 | `policy_gate` |
| 域 | `llm`（模型域，共 341 位 / 30 域中的一位） |
| 注册表 handler | `policy_gate` |
| `safe` | `True` → gated = `False` |
| `external` | `False` |
| `multi_op` | `True` |
| 索引页 | [llm/policy_gate](https://github.com/gbtweilai-star/gbt-caps/blob/main/caps/llm/policy_gate.md) |
| 全量图谱 | [https://github.com/gbtweilai-star/gbt-caps](https://github.com/gbtweilai-star/gbt-caps) |

**关于 341 这个数**：父仓 README 写的是 348，但按 AST 解析注册表实际可枚举的是
`341 个能力位 + 0 个未实现 + 0 个已禁用 = 341`。差出来的 7 个是历史重名/已合并条目。
本仓库按 341 编号，编号与 `gbt-caps` 的索引一致，可逐条核对。

---

## License

MIT。见 [LICENSE](LICENSE)。
