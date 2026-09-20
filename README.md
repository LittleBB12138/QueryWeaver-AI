# QueryWeaver AI

面向业务场景的自然语言问数平台：业务同学用一句话提问，系统检索字段级 Schema、生成并执行 SQL，最后用表格、图表和文字返回结果。目标是让不懂 SQL 的人也能自助取数，同时保证结果**可信、可核对**。

前端 Vue 3，后端 FastAPI + LangGraph，检索采用「BM25 + 稠密向量 + Rerank」混合召回，数据由 DuckDB 只读引擎计算。

## 它解决什么问题

业务侧的取数需求通常卡在数据团队：提工单、排期、等结果。传统 BI 看板只能回答预设好的问题，口径一变就失效；直接让大模型回答数据问题，它不知道库里的表结构，容易编字段、编数字。

QueryWeaver 的思路是**让大模型当「翻译」而不是「答题」**：它只负责把自然语言翻译成 SQL，真正的数据计算交给确定性的数据库引擎，从机制上规避幻觉。

## 核心设计

**双智能体分工** —— 意图路由把请求拆成两条链路，交给两个智能体分头处理，优化目标各不相同：

- **Coder 智能体（查询链路）**：字段检索 → 口径澄清 → 生成 SQL → 调 MCP 执行，追求 SQL 可执行、结果正确。
- **Data-Analysis 智能体（分析链路）**：读结果表 → 对齐口径 → 分析计算 → 可视化 → 报告，追求结论清晰、报告可读。

**字段级 Schema 检索**：精确到字段的「关键词 + 向量 + Rerank」三级索引，而不是整表召回。

**Human-in-the-loop 澄清**：问题有歧义时主动询问，用户确认口径后再查，而不是猜一个答案。

**角色权限隔离**：按业务域（增长 / 渠道 / 内容）做表级权限隔离，SQL 执行前二次校验。

**长短期记忆**：滑动窗口 + 异步摘要维持对话连贯；用户主动保存的字段与结果表跨会话复用。

## 数据与评测

内置一套短视频运营仿真数据（`short_video_ops`）：**41 张表 / 276 个字段 / 72.3 万行**，覆盖用户增长、渠道投放、内容运营三大业务场景。

配套评测体系（`backend/evaluation/`）用 430 条用例做全链路度量，结果如下：

| 评测 | 用例数 | SQL 执行成功率 | 结果正确率 | Schema 召回率 |
| --- | ---: | ---: | ---: | ---: |
| Gold（标准 SQL，验证数据与引擎） | 430 | 100% | 100% | — |
| Live 端到端（全量） | 430 | 99.30% | 82.56% | 95.26% |
| Live 端到端（冒烟） | 49 | 97.96% | 89.80% | 92.99% |

Gold 评测用标准 SQL 验证数据与执行引擎的正确性；Live 评测走完整「自然语言 → 检索 → 生成 → 执行」链路，衡量 AI 端到端能力。

## 快速开始

### 环境要求

- Python 3.11+
- Node.js 20+
- 可用的 LLM / Embedding / Rerank 服务（默认阿里云百炼）

### 后端

```powershell
cd backend
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

编辑 `backend/.env` 填入模型服务配置：

```env
LLM_API_KEY=your-api-key
LLM_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
LLM_MODEL=qwen3.7-plus
EMBEDDING_MODEL=text-embedding-v4
RERANK_MODEL=qwen3-rerank
```

### 前端

```powershell
cd frontend
npm install
```

### 启动

两个终端分别执行：

```powershell
# 后端
cd backend
.\.venv\Scripts\python.exe run.py

# 前端
cd frontend
npm run dev
```

访问 `http://127.0.0.1:5173`（前端）、`http://127.0.0.1:8000/docs`（API 文档）。

### 演示账号

| 账号 | 密码 | 数据权限 |
| --- | --- | --- |
| admin | admin123 | 全部数据 |
| growth | growth123 | 用户增长运营 |
| channel | channel123 | 渠道投放运营 |
| content | content123 | 内容运营 |

## 运行评测

```powershell
cd backend

# Gold 评测：用标准 SQL 验证数据与引擎（无需 LLM Key）
.\.venv\Scripts\python.exe -m evaluation.run_benchmark --mode gold --scope all

# Live 评测：走完整 AI 链路（需在 .env 配置 LLM_API_KEY）
.\.venv\Scripts\python.exe -m evaluation.run_benchmark --mode live --scope smoke
```

## 项目结构

```
.
├── backend/
│   ├── app/
│   │   ├── api/            # FastAPI 路由
│   │   ├── querying/       # Coder / Data-Analysis 智能体、DuckDB 引擎
│   │   ├── retrieval/      # 字段级混合检索与索引
│   │   ├── workflows/      # LangGraph 工作流
│   │   ├── services/       # 会话、记忆、归档
│   │   ├── security/       # 认证与权限隔离
│   │   ├── skills/         # Skill 配置（查询 / 分析）
│   │   └── mcp_runtime/    # 进程内 MCP 工具服务
│   ├── data/databases/short_video_ops/  # 短视频运营数据（41 表）
│   ├── evaluation/         # 评测脚本 + 430 用例 + 结果报告
│   ├── scripts/            # 数据生成与校验脚本
│   └── tests/              # 单元测试
└── frontend/
    └── src/                # Vue 3 前端
```

## License

[MIT](./LICENSE)
