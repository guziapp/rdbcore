<h1 align="center" style="text-align:center;">
  rdbcore
</h1>
<p align="center">
	<strong>为 AI Agent 与人类架构师共同设计的 HarmonyOS NEXT / ArkTS RDB 核心库</strong>
</p>
<p align="center">
	不只是一个数据库工具库，更是一套面向 AI Agent 驱动开发、同时兼顾人类可读性的 HarmonyOS 数据访问基础设施。
</p>
<p align="center">
    <img src="https://img.shields.io/badge/version-v1.0.0-blue.svg" alt="version" />
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="license" />
    <img src="https://img.shields.io/badge/HarmonyOS-6.0.2(22)-orange.svg" alt="HarmonyOS 6.0.2(22)" />
    <img src="https://img.shields.io/badge/ArkTS-supported-brightgreen.svg" alt="ArkTS supported" />
    <img src="https://img.shields.io/badge/package-rdbcore-5c7cfa.svg" alt="package rdbcore" />
</p>

<hr />

## 介绍

`rdbcore` 是一个面向 HarmonyOS / ArkTS 的本地数据库核心库，围绕 **元数据驱动建模、实体访问入口、条件构造、批处理与事务** 提供统一的 RDB 抽象。

和很多只关注“把 CRUD 封装起来”的开源库不一样，`rdbcore` 从一开始就不是按“功能堆叠”思路设计的，而是按 **强约束、可测试、语义清晰、便于持续演进** 的方向来构建。

它的核心目标很直接：让数据库访问这件事，不只方便人写，也方便 AI Agent 理解、生成、校验和重构。

更关键的是，这个仓库本身就是一次完整实践：**项目中的代码、结构、测试与文档，全权由 AI Agent 驱动开发，我主要负责分段目标、方向判断与结果评审。**

换句话说，`rdbcore` 想做的不是“再造一个常规 ORM”，而是给 **AI Agent 驱动开发** 提供一套更稳定的基础设施：

- 对 AI 来说，语义边界更清楚，主链更稳定，更容易生成可靠代码
- 对人来说，结构更规整，命名更统一，更容易阅读、评审和长期维护
- 对团队来说，测试路径更明确，约束更容易落地，架构演进成本更可控

如果把它说得更口语一点：`rdbcore` 希望数据库层不是“谁都能写、但越写越乱”的地方，而是一个 **AI 能协作、人也看得懂、还能持续验证的工程底座**。

## 为什么是 rdbcore

如果只看表面，`rdbcore` 当然是一个数据库 ORM库；但它对标竞品的本质上不是一个思路。

`rdbcore` 更在意的，不只是“能不能查出来、写进去”，而是这套数据访问表达能否长期稳定地被 **人读懂、被 AI 理解、被测试验证、被团队持续演进**。

你可以把它理解成一套专门为**AI Agent 协助**准备的数据库底座：

- **对 AI 更友好**：入口稳定、命名统一、语义边界清楚，Agent 更容易理解上下文并生成可落地代码
- **对人更友好**：不是一堆隐式魔法，而是更接近“看得见主链、读得懂意图、改得动结构”的工程化设计
- **对测试更友好**：能力边界更明确，主流程更容易被拆开验证，不容易变成不可控的黑盒
- **对架构演进更友好**：不是先堆功能再补规则，而是先把约束和语义打稳，再持续扩展能力

说得再直白一点：

- 我们不是想做一个“看起来很方便、但越用越乱”的数据库封装
- 我们想做的是一个“**AI AGENT驱动开发**、人类架构师也愿意长期维护”的基础设施

而且这不只是 README 里的概念表达，而是这个仓库自己的真实开发方式：**这个项目本身，就是由 AI Agent 驱动开发完成的。**

这也是 `rdbcore` 最核心的卖点：它既考虑了 **AI Agent 驱动开发** 的可推理性、可生成性、可验证性，也保留了 **人类架构师** 真正在意的可读性、可审查性和可维护性。

## 开发方式

`rdbcore` 不只是“适合 AI Agent 参与”的项目，它本身就是按照这种方式被做出来的。

可以把这套协作关系理解为：

- **AI Agent 负责实现**：根据目标、约束和现有上下文生成代码、测试、文档与重构方案
- **人类负责架构与裁决**：给出边界、判断方向、做最终评审，而不是亲自下场手写每一行实现
- **仓库负责承载语义**：通过统一命名、稳定主链、明确边界和可测试结构，让协作不失控

这也是为什么我们会这么强调 **强约束、可测试、语义设计优先** —— 因为只有这样，AI Agent 才不是“帮忙补代码”的工具，而是真正可以持续参与研发的工程角色。

如果一句话概括：`rdbcore` 既是一个 HarmonyOS 数据访问核心库，也是一个 **AI Agent 驱动开发如何落到工程实践里** 的样板。

## 特性

- 🧩 **元数据驱动**：支持装饰器与 DSL 两种实体建模方式
- 🗄️ **数据库入口统一**：通过 `RdbDatabase` 管理数据库初始化与访问
- 📦 **实体访问入口**：通过 `EntityEntry<T, ID>` 组织实体读写能力
- 🔗 **链式条件构造**：提供 `QueryWrapper<T>` / `UpdateWrapper<T>`
- ⚙️ **Mapper / Service 双路径**：兼顾底层数据访问与业务友好封装
- 🚀 **常用 CRUD 能力**：覆盖 `insert`、`getById`、`list`、`page`、`patchById`
- 📚 **批量能力**：支持 `insertBatch`、`removeByIds`
- 🔒 **事务支持**：通过 `tx(...)` 管理事务边界
- 🤖 **AI Agent 驱动开发**：强调强约束、低歧义、可推理、可生成、可验证
- 🛠️ **AI Agent 全程交付**：项目本身即由 AI Agent 主导完成代码、测试与文档交付
- 🧱 **语义设计优先**：接口与主链表达更稳定，便于人机协同开发
- 🧪 **测试覆盖**：仓库已包含单元测试与 ohosTest 场景测试

## 下载安装

```bash
ohpm install rdbcore
```

>若当前版本尚未发布到正式包仓，可直接打开本仓库根目录进行本地验证与集成。

## 环境要求

- HarmonyOS SDK：目标版本 `6.0.2(22)`
- 兼容 SDK：`5.0.0(12)`

## 快速上手

### 1. 定义实体与元数据

```ts
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbDatabase,
  RdbIdStrategy,
  pageConfig
} from 'rdbcore'

@RdbEntity({
  tableName: 'user_record',
  page: pageConfig(20, 100)
})
class UserRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  name: string = ''

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}
```

### 2. 创建数据库入口与实体入口

```ts
const database = new RdbDatabase({
  name: 'demo.db',
  context: this.context
})

await database.ensureInitialized()

const userEntry = database.entity<UserRecord, number>('UserRecord')
const service = userEntry.service()
```

> `context` 需要传入当前 UIAbility 或组件可获取到的应用上下文。

### 3. 基本 CRUD

```ts
const first = new UserRecord()
first.name = 'Tom'

const createdId = await service.insert(first)
const one = await service.getById(createdId)

const query = userEntry.query()
  .eq('deleted', 0)
  .likeRight('name', 'T')
  .orderByDesc('id')
  .page(1, 20)

const list = await service.list(query)
const page = await service.page({ current: 1, size: 20 }, query)

const patch = userEntry.update().set('name', 'Jerry')
await service.patchById(createdId, patch)
```

### 4. Batch 与事务

```ts
const second = new UserRecord()
second.name = 'Alice'

const ids = await service.insertBatch([first, second])

await database.tx<void>(async (_scope): Promise<void> => {
  await service.patchById(ids[0], userEntry.update().set('name', 'TxUserUpdated'))
})

await service.removeByIds(ids)
```

## AI Agent 快速上手

> 如果你想让自己的 AI Agent 快速上手业务开发，可以直接复制下面这些提示词。

### 1. 新增一个业务实体

```text
你现在要基于 rdbcore 为一个实际业务新增数据实体。

业务目标：<把你的业务对象粘贴在这里，例如：订单、用户地址、待办事项、设备记录>

请按下面步骤完成：
1. 先设计实体字段、主键、逻辑删除、审计字段
2. 判断哪些字段需要索引、分页配置、默认值
3. 使用 rdbcore 现有模式定义实体与元数据
4. 给出对应的 EntityEntry / service 接入方式
5. 补充最小 CRUD 示例
6. 补充测试建议

要求：命名统一、语义清晰、不要脱离当前仓库已有设计模式。
```

### 2. 做一个业务列表页 / 搜索页

```text
你现在要基于 rdbcore 为一个业务模块实现列表查询能力。

业务场景：<把场景粘贴在这里，例如：订单列表、消息列表、设备告警列表>
筛选条件：<把筛选条件粘贴在这里>
排序方式：<把排序规则粘贴在这里>

请输出：
1. 推荐的实体字段设计
2. QueryWrapper 的构造方式
3. list / page 的调用示例
4. 可选的 likeIf / eq / orderBy 用法
5. 需要补哪些测试

要求：优先复用 rdbcore 的 query 主链，不要自造一套查询表达。
```

### 3. 做一个详情编辑 / Patch 更新

```text
你现在要基于 rdbcore 为一个业务对象实现“详情查询 + 局部更新”能力。

业务对象：<把对象名称粘贴在这里>
允许修改字段：<把允许修改的字段粘贴在这里>
不允许修改字段：<把禁止修改的字段粘贴在这里>

请输出：
1. getById 的读取示例
2. UpdateWrapper / patchById 的更新示例
3. 哪些字段应该禁止更新
4. 参数校验与边界建议
5. 需要覆盖的测试场景

要求：更新逻辑必须保持最小、清晰、可测试，不做隐式副作用。
```

### 4. 做批量操作与事务

```text
你现在要基于 rdbcore 实现一个带事务的业务批量操作。

业务场景：<把你的批量场景粘贴在这里，例如：批量新增任务、批量删除记录、批量更新状态>

请先分析：
1. 哪些步骤必须放在同一个事务里
2. 哪些步骤可以独立执行
3. 应该使用 insertBatch、removeByIds，还是 tx(...) + 多步调用

然后输出：
1. 最小实现方案
2. 事务边界说明
3. 失败回滚的风险点
4. 测试建议

要求：优先使用 rdbcore 已有 batch 和 tx 能力，不要发明新的事务模型。
```

### 5. 把 rdbcore 接到一个真实业务模块

```text
你现在要把 rdbcore 接入一个真实业务模块，请按“先分析、再设计、后实现”的顺序推进。

业务模块：<把模块名称粘贴在这里>
目标能力：<把目标能力粘贴在这里>

请按以下结构输出：
1. 这个业务模块需要哪些实体
2. 每个实体需要哪些基本字段
3. 哪些接口适合走 service，哪些更适合直接走 mapper
4. 哪些地方需要分页、批量、事务
5. 推荐的文件改动清单
6. 推荐的测试清单

要求：方案必须贴合当前仓库结构，避免脱离现有 API 设计另起炉灶。
```


>如果 rdbcore 某些能力不满足你的业务需求，可以直接复制下面这些提示词。

### 1. 先理解仓库

```text
你正在参与 rdbcore 仓库开发。这是一个面向 HarmonyOS NEXT / ArkTS 的 RDB 核心库，强调强约束、可测试、语义清晰，并且适合 AI Agent 驱动开发。

请先阅读以下内容：
1. README.md
2. rdbcore/Index.ets
3. rdbcore/src/main/ets
4. rdbcore/src/test
5. docs/

阅读后输出：
- 核心主链是什么
- 关键公开 API 是什么
- 当前测试覆盖了什么
- 这个仓库为什么适合 AI Agent 协作开发
- 如果要继续演进，最值得优先处理的 3 个方向是什么
```

### 2. 修一个明确问题

```text
你现在是 rdbcore 仓库的 AI Agent 开发者。请先理解现有实现和测试，再对下面的问题做最小、安全、可验证的修改。

要求：
- 保持 HarmonyOS / ArkTS 可编译
- 不做无关重构
- 优先复用现有模式与命名
- 修改后补充或更新测试
- 最后给出变更摘要、影响范围和验证结果

当前任务：<把你的问题粘贴在这里>
```

### 3. 新增一个能力

```text
你正在为 rdbcore 增加一个新能力。请先不要直接写代码，先完成下面几步：
1. 找到相关入口、公开 API、实现层和测试层
2. 总结现有语义约束与命名模式
3. 给出最小实现方案
4. 说明需要改哪些文件
5. 再开始编码并补测试

新增目标：<把你的能力需求粘贴在这里>
```

## 核心功能

### 🔍 查询与分页

```ts
const query = userEntry.query()
  .eq('deleted', 0)
  .likeIf(keyword !== '', 'name', `%${keyword}%`)
  .orderByDesc('updatedAt')
  .page(1, 20)

const list = await service.list(query)
const page = await service.page({ current: 1, size: 20 }, query)
```

### ✏️ 更新操作

```ts
const patch = userEntry.update()
  .set('name', 'NewName')

await service.patchById(id, patch)
```

### 🗑️ 批量删除

```ts
const ids = await service.insertBatch([first, second])
await service.removeByIds(ids)
```

### 🔄 事务管理

```ts
await database.tx<void>(async (_scope): Promise<void> => {
  await service.insert(first)
  await service.patchById(id, userEntry.update().set('name', 'Updated'))
})
```

## 使用边界与说明

- batch 单独调用时会自动开启事务边界
- batch 位于外层 `tx(...)` 中时会复用外层事务
- 当前不允许显式嵌套事务
- 当前不允许跨数据库事务重入
- 推荐先沿着 `RdbDatabase -> EntityEntry -> ServiceImpl / BaseMapper -> QueryWrapper / UpdateWrapper` 主链接入

## 测试与质量验证

仓库当前包含以下测试层：

- `rdbcore/src/test/`：单元测试
- `rdbcore/src/ohosTest/`：ohosTest 场景测试

发布或对外分发前至少完成以下验证：

- [x] diagnostics
- [x] build
- [x] unit test
- [x] ohosTest
- [x] 敏感信息检查

## 开源协议

本项目采用 [MIT License](./LICENSE)。

## 贡献与反馈

如果你不知道从哪里开始，最简单的方法就是：把上面的提示词复制给你的 AI Agent，然后让它先读仓库、再提方案、再提 PR。

也欢迎你把自己的 **AI Agent** 带进来，一起参与这个项目的持续演进。

如果你也在探索 **AI Agent 驱动开发**，那就别只停留在讨论里了，直接让它来提 Issue、补文档、写测试、做重构、发 PR。

`Bring Your AI Agent `

**让你的 AI Agent 赶紧来参与贡献吧。**
