# rdbcore 项目级 AI Agent 协作规范

## 1. 文档目的

本文件用于给进入 `rdbcore` 仓库的 AI Agent 提供**统一、稳定、可执行**的项目级协作规范。

目标只有一个：让 Agent 在不破坏主链语义的前提下，能够快速理解仓库、完成修改、补齐验证，并留下可复评证据。

## 2. 项目事实

- 仓库正式名称：`rdbcore`
- 当前主线版本：`v1.0.0`
- 技术栈：`HarmonyOS NEXT / ArkTS`
- 工程类型：`entry + har(rdbcore)` 双模块工程
- 核心模块：`rdbcore/`
- 仓库定位：面向 **AI Agent 驱动开发**、同时兼顾人类架构师可读性的 HarmonyOS RDB 核心库
- 项目现状：
  - **rdbcore 模块**：主链能力已形成，场景测试全部通过（ProfileFlowScenario、BatchTransactionScenario、DeleteRestoreScenario、DetailPatchScenario、ListSearchScenario、StoreLifecycleScenario）
  - **entry 模块**：demo 应用已收敛，真机测试全部通过（92 个测试用例，Pass: 92, Failure: 0, Error: 0）
  - **已知限制**：rdbcore 不提供自动建表能力，需业务层自行管理 schema
- 当前发布结论口径：`Conditional Go`，**不得对外宣称已完全达到 Go**

## 3. 仓库结构

### 3.1 根目录

- `README.md`：仓库首页、定位、最小接入说明、AI Agent 提示词
- `docs/`：评审、整改、开源检查、路线图文档
- `entry/`：应用壳模块，当前仍处于 demo/模板收敛阶段
- `rdbcore/`：核心 HAR 模块，主要开发工作应优先落在这里

### 3.2 rdbcore 主结构

- `rdbcore/Index.ets`：包导出入口
- `rdbcore/src/main/ets/api/`：对外 API 门面
- `rdbcore/src/main/ets/dsl/`：查询/更新 DSL
- `rdbcore/src/main/ets/metadata/`：实体元数据、装饰器、DSL 建模
- `rdbcore/src/main/ets/runtime/`：运行时、事务、谓词编译、配置
- `rdbcore/src/test/`：单元测试
- `rdbcore/src/ohosTest/`：场景测试 / 集成验证

## 4. Agent 进入仓库后必须先读的文件

按下面顺序阅读：

1. `README.md`
2. `rdbcore/Index.ets`
3. `rdbcore/src/main/ets/index.ets`
4. `rdbcore/src/main/ets/api/`
5. `rdbcore/src/main/ets/dsl/`
6. `rdbcore/src/main/ets/metadata/`
7. `rdbcore/src/main/ets/runtime/`
8. `rdbcore/src/test/`
9. `rdbcore/src/ohosTest/ets/test/`

如果是业务接入任务，再补读：

- `entry/` 相关页面与能力入口

## 5. 核心主链

Agent 必须优先沿着以下主链理解和扩展仓库：

`RdbDatabase -> EntityEntry<T, ID> -> ServiceImpl / BaseMapper -> QueryWrapper / UpdateWrapper`

### 5.1 关键公开 API

- `RdbDatabase`
- `EntityEntry<T, ID>`
- `BaseMapper<T, ID>`
- `ServiceImpl<T, ID>`
- `QueryWrapper<T>`
- `UpdateWrapper<T>`
- `RdbEntity`
- `RdbColumn`
- `RdbIdStrategy`
- `RdbColumnAuditKind`
- `pageConfig`

### 5.2 常用能力

- `insert`
- `getById`
- `list`
- `page`
- `patchById`
- `insertBatch`
- `removeByIds`
- `tx(...)`

## 6. 项目铁律

以下规则优先级高于“临时方便”：

1. **先补交付链，再扩能力边界。**
2. **先建立 schema 演进契约，再允许实体结构持续演化。**
3. **示例应用必须服务核心库验证，不保留纯模板壳层。**
4. **所有整改都必须能被 diagnostics / build / test / 文档证据证明。**
5. **不允许以临时业务接入需求，反推底层 runtime 与 migration 设计。**

## 7. 设计原则

`rdbcore` 不是“随手包一层 CRUD”的库，而是强调：

- 强约束
- 可测试
- 语义清晰
- 可持续演进
- 对 AI Agent 友好
- 对人类架构师可读

做任何改动时，优先问自己：

- 这次改动是否让主链更清晰？
- 是否引入隐式魔法或不可测试逻辑？
- 是否破坏命名一致性和层次边界？
- 是否让 AI 更难理解上下文？

## 8. 明确禁止项

以下方向默认禁止，除非有明确架构决策和验证证据：

- 直接绕过 `RdbDatabase -> EntityEntry -> Service/Mapper -> Wrapper` 主链另起一套入口
- 为了业务赶进度，直接把临时逻辑塞进 runtime 层
- 用手写 SQL 重建表来掩盖正式 migration contract 缺失
- 在没有验证证据的情况下宣称“功能完成”
- 做大范围重构但不补测试、不补文档
- 在仓库中制造动态、弱约束、难推理的接口表达
- 把 `entry` 当成独立产品开发，而不是核心库验证样板

## 9. ArkTS / HarmonyOS 约束

Agent 修改代码时，必须遵守以下约束：

- 不使用 `any` / `unknown`
- 避免解构、索引签名、动态字段访问、`in`、`is`、`Function.bind/apply/call`
- 避免不被 ArkTS 支持的 TS 高级语法
- 所有 import 放在文件顶部
- 对 HarmonyOS API 不确定时，先查官方文档，不要猜
- 涉及权限时，必须核对 `module.json5`
- 涉及依赖时，必须核对 `oh-package.json5`，并优先使用包管理命令，不手改依赖锁文件

## 10. 当前阶段下的工作优先级

当前仓库仍处于“主链收口 + 发布前治理”阶段，优先级如下：

1. `rdbcore` 默认交付链可验证
2. schema version / migration contract
3. `.ts` / `src/test` / `src/ohosTest` 持续纳入质量门禁
4. `entry` 收敛为最小 demo
5. 文档、示例、公开 API 口径一致

如果任务与上述优先级冲突，优先保护主线，不要为了局部业务需求破坏整体治理方向。

## 11. Agent 标准工作流

### 11.1 接到任务后

1. 先判断任务属于：缺陷修复 / 新能力 / 文档 / 测试 / demo / 架构治理
2. 先读相关实现和测试，不要先写代码
3. 明确会改哪些文件、不会改哪些文件
4. 优先做最小、安全、可验证改动

### 11.2 编码时

- 优先复用现有命名、目录、模式
- 不做无关重构
- 同一类改动保持风格一致
- 若涉及公开 API，必须考虑 README / example / docs 是否需要同步

### 11.3 提交结果时

至少输出：

- 改了什么
- 为什么这样改
- 影响范围
- 风险点
- 做了哪些验证
- 还缺什么后续动作

## 12. 验证要求

只要发生代码改动，默认至少考虑以下验证：

- `diagnostics`
- `build`
- `unit test`
- `ohosTest`

验证原则：

- 优先最小范围验证
- 有现成测试就补到现有测试层
- 没有测试时，至少补最小回归路径或明确说明缺口
- 没有证据，不算完成

## 13. 测试层理解

- `rdbcore/src/test/`：偏单元与基础行为验证
- `rdbcore/src/ohosTest/ets/test/scenario/`：偏真实场景链路验证
- `rdbcore/src/ohosTest/ets/test/support/`：场景支撑层

新增能力时，优先考虑：

- 单元测试是否需要补
- 场景测试是否需要补
- README / example 是否需要同步示例

## 14. 文档同步规则

以下情况必须同步文档：

- 新增或修改公开 API
- 改变主链接入方式
- 改变事务、批量、分页、逻辑删除等边界行为
- 引入新的 migration / version / runtime 约束
- 改变开源发布口径或验证结论

优先检查的文档：

- `README.md`
- `docs/PROJECT_CHECKLIST.md`

## 15. 对 AI Agent 最重要的一句话

先读懂主链，再做最小修改；先补验证证据，再谈功能完成；先保证语义清晰和可测试，再考虑能力扩张。
