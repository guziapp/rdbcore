# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-15

### Added

#### 核心功能
- 🧩 **元数据驱动建模**
  - 支持装饰器方式定义实体 (`@RdbEntity`, `@RdbColumn`)
  - 支持 DSL 方式定义实体元数据
  - 支持主键策略配置 (AUTO, UUID, ASSIGNED)
  - 支持逻辑删除配置
  - 支持审计字段自动填充 (createdAt, updatedAt)

- 🗄️ **数据库入口统一**
  - `RdbDatabase` 统一管理数据库初始化与访问
  - 支持数据库版本管理与自动升级
  - 支持多数据库实例管理

- 📦 **实体访问入口**
  - `EntityEntry<T, ID>` 组织实体读写能力
  - 提供 Mapper 层 (`BaseMapper`) 和 Service 层 (`ServiceImpl`) 双路径
  - 支持泛型约束,类型安全

- 🔗 **链式条件构造**
  - `QueryWrapper<T>` 查询条件构造器
  - `UpdateWrapper<T>` 更新条件构造器
  - 支持链式调用,语义清晰
  - 支持条件判断式构造 (`eqIf`, `likeIf` 等)

- 🚀 **常用 CRUD 能力**
  - `insert` - 单条插入
  - `getById` - 主键查询
  - `list` - 列表查询
  - `page` - 分页查询
  - `patchById` - 局部更新
  - `removeById` - 主键删除

- 📚 **批量能力**
  - `insertBatch` - 批量插入
  - `removeByIds` - 批量删除
  - 自动事务边界管理

- 🔒 **事务支持**
  - `tx(...)` 事务管理方法
  - 支持事务嵌套检测
  - 自动回滚机制

#### 查询能力
- 支持等值查询 (`eq`, `ne`)
- 支持范围查询 (`gt`, `ge`, `lt`, `le`, `between`)
- 支持模糊查询 (`like`, `likeLeft`, `likeRight`)
- 支持空值判断 (`isNull`, `isNotNull`)
- 支持排序 (`orderBy`, `orderByAsc`, `orderByDesc`)
- 支持分组 (`groupBy`)
- 支持分页 (`page`)

#### 更新能力
- 支持字段设置 (`set`)
- 支持条件更新
- 支持批量更新

#### 测试覆盖
- ✅ 单元测试 (`src/test/`)
  - `List.test.ets` - 列表功能测试
  - `LocalUnit.test.ets` - 本地单元测试
  - `RdbUnit.test.ets` - RDB 核心单元测试

- ✅ 场景测试 (`src/ohosTest/`)
  - `BatchTransactionScenario.test.ets` - 批量事务场景测试
  - `DeleteRestoreScenario.test.ets` - 删除恢复场景测试
  - `DetailPatchScenario.test.ets` - 详情更新场景测试
  - `ListSearchScenario.test.ets` - 列表搜索场景测试
  - `ProfileFlowScenario.test.ets` - 完整流程场景测试

#### 文档与规范
- 📖 完整的 README 文档
- 🤖 AI Agent 快速上手指南
- 🧪 测试场景覆盖说明
- 📝 代码规范与约束说明

### Technical Details

#### 架构设计
- **API 层** (`api/`): 对外暴露的核心接口
  - `RdbDatabase` - 数据库入口
  - `EntityEntry` - 实体访问入口
  - `BaseMapper` - 底层数据访问
  - `ServiceImpl` - 业务友好封装
  - `RdbPageModel` - 分页模型

- **DSL 层** (`dsl/`): 链式条件构造器
  - `QueryWrapper` - 查询构造器
  - `UpdateWrapper` - 更新构造器

- **元数据层** (`metadata/`): 实体元数据管理
  - `EntityMeta` - 实体元数据定义
  - `EntityMetaDecorators` - 装饰器实现
  - `EntityMetaDsl` - DSL 实现
  - `NormalizedEntityMeta` - 标准化元数据

- **运行时层** (`runtime/`): 核心运行时实现
  - `RdbDatabaseRuntime` - 数据库运行时
  - `RdbEntityCodec` - 实体编解码
  - `RdbPredicatesCompiler` - 谓词编译器
  - `RdbTransactionScope` - 事务作用域
  - `RdbConfig` - 配置管理
  - `RdbError` - 错误处理

#### 兼容性
- 目标 SDK: HarmonyOS 6.0.2(22)
- 兼容 SDK: HarmonyOS 5.0.0(12)
- ArkTS 语法支持
- 遵循 ArkTS 语法约束

#### 开发特色
- 🤖 **AI Agent 驱动开发**: 项目代码、测试与文档全权由 AI Agent 驱动完成
- 🧱 **语义设计优先**: 接口与主链表达稳定,便于人机协同
- 🧪 **测试覆盖完整**: 单元测试 + 场景测试双重保障
- 📐 **强约束设计**: 低歧义、可推理、可生成、可验证

### Notes

这是 `rdbcore` 的首个正式发布版本,标志着项目从概念验证阶段进入生产可用阶段。

本版本的核心目标是:
1. 建立稳定的数据库访问主链
2. 提供清晰的语义边界和命名规范
3. 实现完整的测试覆盖
4. 验证 AI Agent 驱动开发的可行性

---

## 版本规划

### [1.1.0] - 计划中
- 支持多表关联查询
- 支持聚合函数 (count, sum, avg, max, min)
- 支持子查询
- 优化批量操作性能

### [1.2.0] - 计划中
- 支持数据库迁移工具
- 支持数据版本管理
- 支持数据备份与恢复

### [2.0.0] - 远期规划
- 支持响应式数据访问
- 支持数据同步与冲突解决
- 支持多数据源管理

---

## 贡献指南

我们欢迎所有形式的贡献,特别是来自 AI Agent 的贡献!

如果你也在探索 **AI Agent 驱动开发**,欢迎让你的 AI Agent 参与:
- 提 Issue
- 补文档
- 写测试
- 做重构
- 发 PR

**Bring Your AI Agent** 🤖

---

## 许可证

本项目采用 [MIT License](../LICENSE) 开源协议。
