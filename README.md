# QueryWeaver AI

一个基于大模型的自然语言问数平台：业务同学用一句话提问，系统检索字段级 Schema、生成并执行 SQL，最后用表格和文字返回结果。目标是让不懂 SQL 的人也能自助取数，同时保证结果**可信、可核对**。

前端 Vue 3，后端 FastAPI + LangGraph，检索采用「BM25 + 稠密向量 + Rerank」的混合召回，数据由 DuckDB 只读引擎计算。

## 它解决什么问题

业务侧的取数需求通常卡在数据团队：提工单、排期、等结果。传统 BI 看板又只能回答预设好的问题，口径一变就失效。而直接让大模型回答数据问题，它不知道库里的表结构，容易编字段、编数字。

QueryWeaver 的思路是：**让大模型当「翻译」而不是「答题」**——它只负责把自然语言翻译成 SQL，真正的数据计算交给确定性的数据库引擎。这样既用上了大模型的理解能力，又规避了幻觉风险。

## 核心能力

- **字段级 Schema 检索**：不是整表召回，而是精确到字段的混合检索，配合 Rerank 精排，给 SQL 生成提供精准的表结构上下文。
- **口径澄清（Human-in-the-loop）**：问题有歧义时主动询问，用户确认口径后再查，而不是猜一个答案。
- **角色权限隔离**：按业务域（增长 / 渠道 / 内容）做表级权限隔离，SQL 执行前二次校验。
- **结果记忆与综合分析**：查询结果可保存为结果表，后续提问能引用历史结果做跨表分析。
- **图表与报告**：自动生成柱状图、饼图和 Markdown 分析报告。

## 技术架构

```
前端 (Vue3)  →  后端 (FastAPI + LangGraph)  →  单库智能体 (生成 SQL / MCP 工具)
                        ↓                            ↓
                 字段级检索                       数据执行
           (BM25 + 向量 + Rerank)              (DuckDB 只读)
```

- 模型：`qwen3.7-plus`（语义理解 / SQL 生成）、`text-embedding-v4`（字段向量化）、`qwen3-rerank`（候选重排）
- 检索：BM25 关键词 + 稠密向量混合召回，RRF 融合后 Rerank 精排
- 数据：CSV 注册为 DuckDB 只读视图，SQL 经语法校验 + 权限校验后执行

## 快速开始

### 环境要求

- Python 3.11
- Node.js 20.19+
- 可用的 LLM / Embedding / Rerank 服务（默认阿里云百炼）

### 后端

```powershell
cd backend
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

编辑 `backend/.env`，填入 `LLM_API_KEY`：

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

访问：

- 前端：`http://127.0.0.1:5173`
- API 文档：`http://127.0.0.1:8000/docs`
- 健康检查：`http://127.0.0.1:8000/api/health`

### 演示账号

| 账号 | 密码 | 数据权限 |
| --- | --- | --- |
| admin | admin123 | 全部数据 |
| sales | sales123 | 电商运营（ecommerce_ops） |
| mock | mock123 | 基础演示（demo_mock） |

## 项目结构

```
.
├── backend/
│   ├── app/
│   │   ├── api/            # FastAPI 路由
│   │   ├── querying/       # SQL 生成、DuckDB 引擎、单库智能体
│   │   ├── retrieval/      # 字段级混合检索与索引
│   │   ├── workflows/      # LangGraph 工作流
│   │   ├── services/       # 会话、记忆、归档
│   │   ├── security/       # 认证与权限隔离
│   │   ├── skills/         # 应用级 Skill 配置
│   │   └── mcp_runtime/    # 进程内 MCP 工具服务
│   ├── data/databases/     # CSV 业务数据
│   └── tests/              # 单元测试
└── frontend/
    └── src/                # Vue 3 前端
```

## 测试

后端目录下执行：

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -p "test_*.py"
```

覆盖字段检索、预处理、记忆、权限隔离、Skill 等核心模块。
