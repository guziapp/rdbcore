import { common } from '@kit.AbilityKit'
import { describe, expect, it } from '@ohos/hypium'
import {
  BaseMapper,
  buildNormalizedEntityMetaSignature,
  defineEntityMeta,
  EntityMeta,
  field,
  idField,
  logicDeleteField,
  pageConfig,
  QueryWrapper,
  RdbColumn,
  RdbColumnAuditKind,
  RdbDatabase,
  RdbDatabaseRuntime,
  RdbEntity,
  RdbError,
  RdbQueryConditionKind,
  RdbQueryJoin,
  RdbIdStrategy,
  RdbPatchMode,
  RdbPageRequest,
  RdbQueryOperator,
  RdbTransactionScope,
  resolveDecoratedEntityMeta,
    ServiceImpl,
  UpdateWrapper,
  auditFields,
  clearDecoratedEntityMetaForTest,
  mapRowToEntity,
  normalizeEntityMeta
} from '../main/ets'
import { prepareInsertValues } from '../main/ets/runtime/RdbEntityCodec'
import { relationalStore } from '@kit.ArkData'

class TestContextStub {}

class DemoRecord {
  id: number = 0
  name: string = ''
  deleted: number = 0
  createdAt: number = 0
  updatedAt: number = 0
}

@RdbEntity({
  entityName: 'DemoRecord',
  tableName: 'demo_record',
  page: pageConfig(20, 100),
  nowProvider: (): number => 123
})
class DecoratedDemoRecord {
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

@RdbEntity({
  entityName: 'BrokenDecoratedPageRecord',
  tableName: 'broken_decorated_page_record',
  page: pageConfig(20, 10)
})
class BrokenDecoratedPageRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.INPUT })
  id: number = 0

  @RdbColumn()
  name: string = ''
}

@RdbEntity({
  entityName: 'DuplicatedDecoratedIdRecord',
  tableName: 'duplicated_decorated_id_record'
})
class DuplicatedDecoratedIdRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.INPUT })
  id: number = 0

  @RdbColumn({ idStrategy: RdbIdStrategy.INPUT })
  externalId: number = 0
}

class DecoratedRecordBase {
  @RdbColumn({ insertable: false })
  inheritedFlag: number = 0
}

@RdbEntity({
  entityName: 'InheritedDecoratedRecord',
  tableName: 'inherited_decorated_record'
})
class InheritedDecoratedRecord extends DecoratedRecordBase {
  @RdbColumn({ idStrategy: RdbIdStrategy.INPUT })
  id: number = 0

  @RdbColumn()
  name: string = ''
}

class InsertOnlyRecord {
  name: string = ''
}

class FakeStore {
  beginCount: number = 0
  commitCount: number = 0
  rollbackCount: number = 0
  insertCount: number = 0
  updateCount: number = 0
  deleteCount: number = 0
  nextInsertId: number = 101
  rollbackShouldThrow: boolean = false

  beginTransaction(): void {
    this.beginCount = this.beginCount + 1
  }

  commit(): void {
    this.commitCount = this.commitCount + 1
  }

  rollBack(): void {
    this.rollbackCount = this.rollbackCount + 1
    if (this.rollbackShouldThrow) {
      throw new Error('rollback failed')
    }
  }

  async insert(table: string, values: relationalStore.ValuesBucket, conflict: relationalStore.ConflictResolution): Promise<number> {
    this.insertCount = this.insertCount + 1
    const insertedId = this.nextInsertId
    this.nextInsertId = this.nextInsertId + 1
    return insertedId
  }

  async update(
    values: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates,
    conflict: relationalStore.ConflictResolution
  ): Promise<number> {
    this.updateCount = this.updateCount + 1
    return 1
  }

  async delete(predicates: relationalStore.RdbPredicates): Promise<number> {
    this.deleteCount = this.deleteCount + 1
    return 1
  }
}

class StoreBackedRuntime extends RdbDatabaseRuntime {
  private readonly fakeStore: FakeStore

  constructor(name: string, fakeStore: FakeStore) {
    super({
      name: name,
      context: createContextStub()
    })
    this.fakeStore = fakeStore
  }

  protected openStore(storeConfig: relationalStore.StoreConfig): Promise<relationalStore.RdbStore> {
    return Promise.resolve(this.fakeStore as object as relationalStore.RdbStore)
  }
}

class ScopeHolder {
  hasValue: boolean = false
  scope: RdbTransactionScope = new RdbTransactionScope('scope-holder')
}

class ErrorCodeHolder {
  hasValue: boolean = false
  code: string = ''
}

class StringHolder {
  hasValue: boolean = false
  value: string = ''
}

class FakeRuntime extends RdbDatabaseRuntime {
  queryResult: Array<DemoRecord> = []
  countResult: number = 0
  queryCount: number = 0
  insertCount: number = 0
  updateCount: number = 0
  deleteCount: number = 0
  countCount: number = 0
  txCount: number = 0
  nextInsertId: number = 7

  constructor() {
    super({
      name: 'rdbcore-fake-runtime.db',
      context: createContextStub()
    })
  }

  async tx<Result>(task: (scope: RdbTransactionScope) => Promise<Result>): Promise<Result> {
    this.txCount = this.txCount + 1
    return task(new RdbTransactionScope('fake'))
  }

  async insert(meta: object, values: relationalStore.ValuesBucket): Promise<number> {
    this.insertCount = this.insertCount + 1
    const insertedId = this.nextInsertId
    this.nextInsertId = this.nextInsertId + 1
    return insertedId
  }

  async update(meta: object, values: relationalStore.ValuesBucket, predicates: relationalStore.RdbPredicates): Promise<number> {
    this.updateCount = this.updateCount + 1
    return 1
  }

  async delete(meta: object, predicates: relationalStore.RdbPredicates): Promise<number> {
    this.deleteCount = this.deleteCount + 1
    return 1
  }

  async query<T extends object>(meta: object, predicates: relationalStore.RdbPredicates, columns?: Array<string>): Promise<Array<T>> {
    this.queryCount = this.queryCount + 1
    return this.queryResult as Array<T>
  }

  async count(meta: object, predicates: relationalStore.RdbPredicates): Promise<number> {
    this.countCount = this.countCount + 1
    return this.countResult
  }
}

class TestPageRequest implements RdbPageRequest {
  current: number = 1
  size: number = 10
}

function createContextStub(): common.Context {
  return new TestContextStub() as object as common.Context
}

function createDemoMeta(): EntityMeta {
  return {
    entityName: 'DemoRecord',
    tableName: 'demo_record',
    fields: [
      { property: 'id', columnName: 'id' },
      { property: 'name', columnName: 'name' },
      { property: 'deleted', columnName: 'deleted' },
      { property: 'createdAt', columnName: 'created_at', updatable: false },
      { property: 'updatedAt', columnName: 'updated_at' }
    ],
    id: { field: 'id', strategy: RdbIdStrategy.AUTO },
    logicDelete: { field: 'deleted', aliveValue: 0, deletedValue: 1 },
    audit: {
      createdAt: 'createdAt',
      updatedAt: 'updatedAt',
      nowProvider: (): number => 123
    },
    page: { defaultSize: 20, maxSize: 100 }
  }
}

function createDemoMetaByDsl(): EntityMeta {
  return defineEntityMeta({
    entityName: 'DemoRecord',
    tableName: 'demo_record',
    fields: [
      field('id'),
      field('name'),
      field('deleted'),
      field('createdAt', 'created_at', { updatable: false }),
      field('updatedAt', 'updated_at')
    ],
    id: idField('id', RdbIdStrategy.AUTO),
    logicDelete: logicDeleteField('deleted', 0, 1),
    audit: auditFields('createdAt', 'updatedAt', (): number => 123),
    page: pageConfig(20, 100)
  })
}

function createDemoMetaByDecorator(): EntityMeta {
  return resolveDecoratedEntityMeta('DemoRecord')
}

export default function rdbcoreUnitTest() {
  describe('rdbcoreUnitTest', () => {
    it('normalize_entity_meta_should_apply_defaults_and_build_lookup_maps', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())

      expect(normalized.entityName).assertEqual('DemoRecord')
      expect(normalized.fieldMap.get('name')?.columnName).assertEqual('name')
      expect(normalized.columnMap.get('updated_at')?.property).assertEqual('updatedAt')
      expect(normalized.fields[0].insertable).assertTrue()
      expect(normalized.fields[0].updatable).assertTrue()
      expect(normalized.logicDelete?.field).assertEqual('deleted')
      expect(normalized.page?.maxSize).assertEqual(100)
    })

    it('entity_meta_dsl_should_match_manual_entity_meta_after_normalize', 0, async () => {
      const manual = normalizeEntityMeta(createDemoMeta())
      const byDsl = normalizeEntityMeta(createDemoMetaByDsl())

      expect(buildNormalizedEntityMetaSignature(byDsl)).assertEqual(buildNormalizedEntityMetaSignature(manual))
      expect(byDsl.audit?.createdAt).assertEqual(manual.audit?.createdAt)
      expect(byDsl.audit?.updatedAt).assertEqual(manual.audit?.updatedAt)
      expect(byDsl.audit?.nowProvider?.()).assertEqual(123)
      expect(byDsl.fieldMap.get('name')?.columnName).assertEqual('name')
      expect(byDsl.fieldMap.get('createdAt')?.updatable).assertFalse()
      expect(byDsl.logicDelete?.deletedValue).assertEqual(1)
    })

    it('entity_meta_dsl_should_keep_fail_fast_validation', 0, async () => {
      const errorHolder = new ErrorCodeHolder()
      const messageHolder = new StringHolder()

      try {
        normalizeEntityMeta(defineEntityMeta({
          entityName: 'BrokenRecord',
          tableName: 'broken_record',
          fields: [
            field('id'),
            field('name')
          ],
          id: idField('id', RdbIdStrategy.INPUT),
          logicDelete: logicDeleteField('deleted', 0, 1)
        }))
      } catch (error) {
        const metaError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = metaError.code
        messageHolder.hasValue = true
        messageHolder.value = metaError.message
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('ENTITY_META_FIELD_REFERENCE_INVALID')
      expect(messageHolder.value).assertEqual('EntityMeta.logicDelete.field must exist in fields.')
    })

    it('entity_meta_dsl_should_keep_page_fail_fast_validation', 0, async () => {
      const errorHolder = new ErrorCodeHolder()

      try {
        normalizeEntityMeta(defineEntityMeta({
          entityName: 'BrokenPageRecord',
          tableName: 'broken_page_record',
          fields: [
            field('id'),
            field('name')
          ],
          id: idField('id', RdbIdStrategy.INPUT),
          page: pageConfig(20, 10)
        }))
      } catch (error) {
        const metaError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = metaError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('ENTITY_META_PAGE_DEFAULT_EXCEEDS_MAX')
    })

    it('entity_meta_decorator_should_match_manual_entity_meta_after_normalize', 0, async () => {
      const manual = normalizeEntityMeta(createDemoMeta())
      const byDecorator = normalizeEntityMeta(createDemoMetaByDecorator())

      expect(buildNormalizedEntityMetaSignature(byDecorator)).assertEqual(buildNormalizedEntityMetaSignature(manual))
      expect(byDecorator.audit?.createdAt).assertEqual(manual.audit?.createdAt)
      expect(byDecorator.audit?.updatedAt).assertEqual(manual.audit?.updatedAt)
      expect(byDecorator.audit?.nowProvider?.()).assertEqual(123)
      expect(byDecorator.fieldMap.get('createdAt')?.columnName).assertEqual('created_at')
      expect(byDecorator.fieldMap.get('createdAt')?.updatable).assertFalse()
      expect(byDecorator.logicDelete?.aliveValue).assertEqual(0)
    })

    it('entity_meta_decorator_should_keep_page_fail_fast_validation', 0, async () => {
      const errorHolder = new ErrorCodeHolder()

      try {
        normalizeEntityMeta(resolveDecoratedEntityMeta('BrokenDecoratedPageRecord'))
      } catch (error) {
        const metaError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = metaError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('ENTITY_META_PAGE_DEFAULT_EXCEEDS_MAX')
    })

    it('entity_meta_decorator_should_fail_when_duplicate_id_declared', 0, async () => {
      const errorHolder = new ErrorCodeHolder()

      try {
        resolveDecoratedEntityMeta('DuplicatedDecoratedIdRecord')
      } catch (error) {
        const metaError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = metaError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('DECORATED_ENTITY_DUPLICATED_ID')
    })

    it('entity_meta_decorator_should_fail_when_entity_is_not_registered', 0, async () => {
      clearDecoratedEntityMetaForTest('MissingDecoratedRecord')
      const errorHolder = new ErrorCodeHolder()

      try {
        resolveDecoratedEntityMeta('MissingDecoratedRecord')
      } catch (error) {
        const metaError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = metaError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('DECORATED_ENTITY_NOT_REGISTERED')
    })

    it('entity_meta_decorator_should_fail_when_inherited_decorated_fields_exist', 0, async () => {
      const errorHolder = new ErrorCodeHolder()

      try {
        resolveDecoratedEntityMeta('InheritedDecoratedRecord')
      } catch (error) {
        const metaError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = metaError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('DECORATED_ENTITY_INHERITED_FIELDS_NOT_SUPPORTED')
    })

    it('rdbcore_database_should_cache_same_entity_meta', 0, async () => {
      const database = new RdbDatabase({
        name: 'rdbcore-skeleton-test.db',
        context: createContextStub()
      })

      const entryA = database.entity<DemoRecord, number>(createDemoMeta())
      const entryB = database.entity<DemoRecord, number>(createDemoMeta())

      expect((entryA.meta() as object) === (entryB.meta() as object)).assertTrue()
      expect(entryA.mapper().meta().tableName).assertEqual('demo_record')
      expect(entryA.service().meta().entityName).assertEqual('DemoRecord')
    })

    it('rdbcore_database_should_support_decorated_entity_name_entry', 0, async () => {
      const database = new RdbDatabase({
        name: 'rdbcore-skeleton-test.db',
        context: createContextStub()
      })

      const entryA = database.entity<DemoRecord, number>('DemoRecord')
      const entryB = database.entity<DemoRecord, number>(createDemoMetaByDecorator())

      expect((entryA.meta() as object) === (entryB.meta() as object)).assertTrue()
      expect(entryA.mapper().meta().tableName).assertEqual('demo_record')
      expect(entryA.query().meta().entityName).assertEqual('DemoRecord')
    })

    it('query_and_update_wrapper_should_keep_entity_boundary', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)
      const update = new UpdateWrapper<DemoRecord>(normalized)

      query.eq('name', 'demo').gte('updatedAt', 100).in('deleted', [0, 1]).includeDeleted(true).orderByDesc('updatedAt').page(1, 20)
      update.set('name', 'demo').clearMany(['updatedAt'])

      expect(query.snapshot().includeDeleted).assertTrue()
      expect(query.snapshot().conditions.length).assertEqual(3)
      expect(query.snapshot().orders.length).assertEqual(1)
      expect(query.snapshot().page?.size).assertEqual(20)
      expect(update.hasPatch()).assertTrue()
      expect(update.patchSize()).assertEqual(2)
    })

    it('query_wrapper_should_reject_empty_in_values', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)
      const errorHolder = new ErrorCodeHolder()
      const messageHolder = new StringHolder()

      try {
        query.in('id', [])
      } catch (error) {
        const wrapperError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = wrapperError.code
        messageHolder.hasValue = true
        messageHolder.value = wrapperError.message
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('QUERY_WRAPPER_EMPTY_VALUES')
      expect(messageHolder.hasValue).assertTrue()
      expect(messageHolder.value).assertEqual('QueryWrapper.in requires a non-empty values array.')
    })

    it('query_wrapper_should_fail_with_stable_error_when_field_not_declared', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)
      const errorHolder = new ErrorCodeHolder()
      const messageHolder = new StringHolder()

      try {
        query.eq('missingField', 'demo')
      } catch (error) {
        const wrapperError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = wrapperError.code
        messageHolder.hasValue = true
        messageHolder.value = wrapperError.message
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('FIELD_NOT_DECLARED')
      expect(messageHolder.hasValue).assertTrue()
      expect(messageHolder.value).assertEqual('Field "missingField" is not declared in DemoRecord.')
    })

    it('query_wrapper_should_support_high_frequency_conditional_helpers', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)

      query.eqIf(false, 'name', 'skip')
        .likeIf(true, 'name', 'demo')
        .inIf(false, 'deleted', [0])
        .betweenIf(true, 'updatedAt', 10, 20)
        .likeLeft('name', 'tom')
        .likeRight('name', 'je')
        .notIn('deleted', [1])
        .orderByAscIf(false, 'id')
        .orderByDescIf(true, 'updatedAt')

      const snapshot = query.snapshot()

      expect(snapshot.conditions.length).assertEqual(5)
      expect(snapshot.conditions[0].operator).assertEqual(RdbQueryOperator.LIKE)
      expect(snapshot.conditions[0].value).assertEqual('demo')
      expect(snapshot.conditions[1].operator).assertEqual(RdbQueryOperator.BETWEEN)
      expect(snapshot.conditions[1].value).assertEqual(10)
      expect(snapshot.conditions[1].secondValue).assertEqual(20)
      expect(snapshot.conditions[2].value).assertEqual('%tom')
      expect(snapshot.conditions[3].value).assertEqual('je%')
      expect(snapshot.conditions[4].operator).assertEqual(RdbQueryOperator.NOT_IN)
      expect(snapshot.conditions[4].values[0]).assertEqual(1)
      expect(snapshot.orders.length).assertEqual(1)
      expect(snapshot.orders[0].property).assertEqual('updatedAt')
      expect(snapshot.orders[0].ascending).assertFalse()
    })

    it('query_wrapper_should_support_grouped_and_or_conditions', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)

      query.eq('deleted', 0)
        .or((nested: QueryWrapper<DemoRecord>): void => {
          nested.eq('name', 'alpha').likeRight('name', 'al')
        })
        .and((nested: QueryWrapper<DemoRecord>): void => {
          nested.gte('updatedAt', 10).lte('updatedAt', 20)
        })

      const snapshot = query.snapshot()

      expect(snapshot.conditions.length).assertEqual(3)
      expect(snapshot.conditions[0].kind).assertEqual(RdbQueryConditionKind.LEAF)
      expect(snapshot.conditions[1].kind).assertEqual(RdbQueryConditionKind.GROUP)
      expect(snapshot.conditions[1].join).assertEqual(RdbQueryJoin.OR)
      expect(snapshot.conditions[1].children.length).assertEqual(2)
      expect(snapshot.conditions[1].children[0].property).assertEqual('name')
      expect(snapshot.conditions[1].children[1].value).assertEqual('al%')
      expect(snapshot.conditions[2].kind).assertEqual(RdbQueryConditionKind.GROUP)
      expect(snapshot.conditions[2].join).assertEqual(RdbQueryJoin.AND)
      expect(snapshot.conditions[2].children[0].operator).assertEqual(RdbQueryOperator.GTE)
      expect(snapshot.conditions[2].children[1].operator).assertEqual(RdbQueryOperator.LTE)
    })

    it('query_wrapper_should_support_multi_filter_business_style_query', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)

      query.eq('deleted', 0)
        .likeIf(true, 'name', '%demo%')
        .inIf(true, 'id', [11, 12, 15])
        .betweenIf(true, 'updatedAt', 100, 200)
        .or((nested: QueryWrapper<DemoRecord>): void => {
          nested.likeRight('name', 'vip').likeLeft('name', 'pro')
        })
        .orderByDescIf(true, 'updatedAt')
        .page(2, 10)

      const snapshot = query.snapshot()

      expect(snapshot.includeDeleted).assertFalse()
      expect(snapshot.conditions.length).assertEqual(5)
      expect(snapshot.conditions[0].operator).assertEqual(RdbQueryOperator.EQ)
      expect(snapshot.conditions[1].operator).assertEqual(RdbQueryOperator.LIKE)
      expect(snapshot.conditions[1].value).assertEqual('%demo%')
      expect(snapshot.conditions[2].operator).assertEqual(RdbQueryOperator.IN)
      expect(snapshot.conditions[2].values.length).assertEqual(3)
      expect(snapshot.conditions[2].values[0]).assertEqual(11)
      expect(snapshot.conditions[3].operator).assertEqual(RdbQueryOperator.BETWEEN)
      expect(snapshot.conditions[3].value).assertEqual(100)
      expect(snapshot.conditions[3].secondValue).assertEqual(200)
      expect(snapshot.conditions[4].kind).assertEqual(RdbQueryConditionKind.GROUP)
      expect(snapshot.conditions[4].join).assertEqual(RdbQueryJoin.OR)
      expect(snapshot.conditions[4].children.length).assertEqual(2)
      expect(snapshot.conditions[4].children[0].value).assertEqual('vip%')
      expect(snapshot.conditions[4].children[1].value).assertEqual('%pro')
      expect(snapshot.orders.length).assertEqual(1)
      expect(snapshot.orders[0].property).assertEqual('updatedAt')
      expect(snapshot.orders[0].ascending).assertFalse()
      expect(snapshot.page?.current).assertEqual(2)
      expect(snapshot.page?.size).assertEqual(10)
    })

    it('query_wrapper_should_fail_fast_when_group_contains_non_condition_state', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)
      const errorHolder = new ErrorCodeHolder()
      const messageHolder = new StringHolder()

      try {
        query.and((nested: QueryWrapper<DemoRecord>): void => {
          nested.eq('name', 'alpha').orderByDesc('updatedAt')
        })
      } catch (error) {
        const wrapperError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = wrapperError.code
        messageHolder.hasValue = true
        messageHolder.value = wrapperError.message
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('QUERY_WRAPPER_GROUP_STATE_NOT_SUPPORTED')
      expect(messageHolder.hasValue).assertTrue()
      expect(messageHolder.value).assertEqual('QueryWrapper grouped conditions do not support orderBy.')
    })

    it('query_wrapper_should_reject_invalid_page_with_stable_error', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const query = new QueryWrapper<DemoRecord>(normalized)
      const errorHolder = new ErrorCodeHolder()

      try {
        query.page(0, 20)
      } catch (error) {
        const wrapperError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = wrapperError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('QUERY_WRAPPER_INVALID_PAGE')
    })

    it('update_wrapper_should_support_patch_helper_methods', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const update = new UpdateWrapper<DemoRecord>(normalized)

      update.setIf(false, 'name', 'skip')
        .setIf(true, 'name', 'demo')
        .setIfDefined('name', 'beta')
        .setIfDefined('updatedAt', undefined)
        .setMany([
          { property: 'updatedAt', value: 123 },
          { property: 'deleted', value: 0 }
        ])

      const snapshot = update.snapshot()

      expect(update.hasPatch()).assertTrue()
      expect(update.patchSize()).assertEqual(3)
      expect(snapshot[0].property).assertEqual('name')
      expect(snapshot[0].mode).assertEqual(RdbPatchMode.SET)
      expect(snapshot[0].value).assertEqual('beta')
      expect(snapshot[1].property).assertEqual('updatedAt')
      expect(snapshot[1].value).assertEqual(123)
      expect(snapshot[2].property).assertEqual('deleted')
      expect(snapshot[2].value).assertEqual(0)
    })

    it('update_wrapper_should_fail_with_stable_error_for_non_updatable_field', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const update = new UpdateWrapper<DemoRecord>(normalized)
      const errorHolder = new ErrorCodeHolder()
      const messageHolder = new StringHolder()

      try {
        update.set('createdAt', 456)
      } catch (error) {
        const patchError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = patchError.code
        messageHolder.hasValue = true
        messageHolder.value = patchError.message
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('FIELD_NOT_UPDATABLE')
      expect(messageHolder.hasValue).assertTrue()
      expect(messageHolder.value).assertEqual('Field "createdAt" is not updatable in DemoRecord.')
    })

    it('update_wrapper_should_fail_with_stable_error_for_patch_conflict', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const update = new UpdateWrapper<DemoRecord>(normalized)
      const errorHolder = new ErrorCodeHolder()

      try {
        update.set('name', 'alpha').clear('name')
      } catch (error) {
        const patchError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = patchError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('UPDATE_WRAPPER_PATCH_CONFLICT')
    })

    it('prepare_insert_values_should_apply_logic_delete_and_audit_defaults', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const entity = new InsertOnlyRecord()
      entity.name = 'demo'
      const prepared = prepareInsertValues(normalized, entity as object)
      const mapped = mapRowToEntity<DemoRecord>(normalized, prepared.values)

      expect(prepared.size).assertEqual(4)
      expect(mapped.name).assertEqual('demo')
      expect(mapped.deleted).assertEqual(0)
      expect(mapped.createdAt).assertEqual(123)
      expect(mapped.updatedAt).assertEqual(123)
    })

    it('base_mapper_should_use_runtime_for_minimal_crud_path', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const entity = new DemoRecord()
      entity.name = 'alpha'
      const wrapper = new QueryWrapper<DemoRecord>(normalized)
      const patch = new UpdateWrapper<DemoRecord>(normalized)
      wrapper.eq('name', 'alpha').orderByAsc('id')
      patch.set('name', 'beta')

      const insertedId = await mapper.insert(entity)
      runtime.queryResult = [entity]
      const selected = await mapper.selectById(insertedId)
      const listed = await mapper.selectList(wrapper)
      const updated = await mapper.updatePatchById(insertedId, patch)
      const deleted = await mapper.deleteById(insertedId)
      const restored = await mapper.restoreById(insertedId)

      expect(insertedId).assertEqual(7)
      expect(entity.id).assertEqual(7)
      expect(selected?.name).assertEqual('alpha')
      expect(listed.length).assertEqual(1)
      expect(runtime.insertCount).assertEqual(1)
      expect(runtime.updateCount).assertEqual(3)
      expect(runtime.deleteCount).assertEqual(0)
      expect(updated).assertTrue()
      expect(deleted).assertTrue()
      expect(restored).assertTrue()
    })

    it('base_mapper_should_support_batch_insert_and_delete_path', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const first = new DemoRecord()
      const second = new DemoRecord()
      first.name = 'alpha'
      second.name = 'beta'

      const emptyInsertIds = await mapper.insertBatch([])
      const insertedIds = await mapper.insertBatch([first, second])
      const emptyDeleteCount = await mapper.deleteBatchByIds([])
      const softDeletedCount = await mapper.deleteBatchByIds([first.id, second.id])
      const hardDeletedCount = await mapper.deleteBatchByIds([99], true)

      expect(emptyInsertIds.length).assertEqual(0)
      expect(insertedIds.length).assertEqual(2)
      expect(insertedIds[0]).assertEqual(7)
      expect(insertedIds[1]).assertEqual(8)
      expect(first.id).assertEqual(7)
      expect(second.id).assertEqual(8)
      expect(emptyDeleteCount).assertEqual(0)
      expect(softDeletedCount).assertEqual(2)
      expect(hardDeletedCount).assertEqual(1)
      expect(runtime.insertCount).assertEqual(2)
      expect(runtime.updateCount).assertEqual(2)
      expect(runtime.deleteCount).assertEqual(1)
      expect(runtime.txCount).assertEqual(3)
    })

    it('base_mapper_should_support_count_page_and_exists_path', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const wrapper = new QueryWrapper<DemoRecord>(normalized)
      const pageRequest = new TestPageRequest()
      const first = new DemoRecord()
      const second = new DemoRecord()

      wrapper.eq('name', 'alpha').page(1, 1)
      pageRequest.current = 2
      pageRequest.size = 2
      first.id = 11
      first.name = 'alpha'
      second.id = 12
      second.name = 'beta'
      runtime.queryResult = [first, second]
      runtime.countResult = 5

      const count = await mapper.selectCount(wrapper)
      const page = await mapper.selectPage(pageRequest, wrapper)
      const exists = await mapper.existsById(11)

      expect(count).assertEqual(5)
      expect(page.current).assertEqual(2)
      expect(page.size).assertEqual(2)
      expect(page.total).assertEqual(5)
      expect(page.pages).assertEqual(3)
      expect(page.records.length).assertEqual(2)
      expect(page.hasNext).assertTrue()
      expect(page.hasPrevious).assertTrue()
      expect(exists).assertTrue()
      expect(runtime.countCount).assertEqual(3)
    })

    it('base_mapper_should_support_grouped_query_wrapper_path', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const wrapper = new QueryWrapper<DemoRecord>(normalized)
      const first = new DemoRecord()

      wrapper.eq('deleted', 0)
        .or((nested: QueryWrapper<DemoRecord>): void => {
          nested.eq('name', 'alpha').likeRight('name', 'al')
        })
      first.id = 9
      first.name = 'alpha'
      runtime.queryResult = [first]

      const listed = await mapper.selectList(wrapper)
      const count = await mapper.selectCount(wrapper)

      expect(listed.length).assertEqual(1)
      expect(listed[0].id).assertEqual(9)
      expect(count).assertEqual(0)
    })

    it('base_mapper_should_support_short_crud_aliases', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const entity = new DemoRecord()
      const wrapper = new QueryWrapper<DemoRecord>(normalized)
      const patch = new UpdateWrapper<DemoRecord>(normalized)
      const pageRequest = new TestPageRequest()
      const first = new DemoRecord()

      entity.name = 'alpha'
      wrapper.eq('name', 'alpha')
      patch.set('name', 'beta')
      pageRequest.current = 1
      pageRequest.size = 10
      first.id = 7
      first.name = 'alpha'
      runtime.queryResult = [first]
      runtime.countResult = 1

      const insertedId = await mapper.insert(entity)
      const one = await mapper.getById(insertedId)
      const listed = await mapper.list(wrapper)
      const count = await mapper.count(wrapper)
      const page = await mapper.page(pageRequest, wrapper)
      const patched = await mapper.patchById(insertedId, patch)
      const removed = await mapper.removeById(insertedId)
      const removedBatch = await mapper.removeByIds([insertedId], true)

      runtime.countResult = 1
      const exists = await mapper.existsById(insertedId)

      expect(insertedId).assertEqual(7)
      expect(one?.id).assertEqual(7)
      expect(listed.length).assertEqual(1)
      expect(count).assertEqual(1)
      expect(page.total).assertEqual(1)
      expect(patched).assertTrue()
      expect(removed).assertTrue()
      expect(removedBatch).assertEqual(1)
      expect(exists).assertTrue()
    })

    it('base_mapper_should_support_multi_filter_page_business_flow', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const query = new QueryWrapper<DemoRecord>(normalized)
      const first = new DemoRecord()
      const second = new DemoRecord()
      const pageRequest = new TestPageRequest()

      pageRequest.current = 2
      pageRequest.size = 10
      first.id = 11
      first.name = 'alice'
      second.id = 12
      second.name = 'vip-pro'
      runtime.queryResult = [first, second]
      runtime.countResult = 6

      query.eq('deleted', 0)
        .likeIf(true, 'name', '%ali%')
        .inIf(true, 'id', [11, 12, 15])
        .betweenIf(true, 'updatedAt', 100, 200)
        .or((nested: QueryWrapper<DemoRecord>): void => {
          nested.likeRight('name', 'vip').likeLeft('name', 'pro')
        })
        .orderByDescIf(true, 'updatedAt')
        .page(2, 10)

      const listed = await mapper.list(query)
      const count = await mapper.count(query)
      const page = await mapper.page(pageRequest, query)

      expect(listed.length).assertEqual(2)
      expect(listed[0].id).assertEqual(11)
      expect(listed[1].name).assertEqual('vip-pro')
      expect(count).assertEqual(6)
      expect(page.current).assertEqual(2)
      expect(page.size).assertEqual(10)
      expect(page.total).assertEqual(6)
      expect(page.pages).assertEqual(1)
      expect(page.records.length).assertEqual(2)
      expect(runtime.queryCount).assertEqual(2)
      expect(runtime.countCount).assertEqual(2)
    })

    it('service_impl_should_support_short_crud_aliases', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const service = new ServiceImpl<DemoRecord, number>(mapper)
      const entity = new DemoRecord()
      const wrapper = new QueryWrapper<DemoRecord>(normalized)
      const patch = new UpdateWrapper<DemoRecord>(normalized)
      const pageRequest = new TestPageRequest()
      const first = new DemoRecord()

      entity.name = 'alpha'
      wrapper.eq('name', 'alpha')
      patch.set('name', 'beta')
      pageRequest.current = 1
      pageRequest.size = 10
      first.id = 7
      first.name = 'alpha'
      runtime.queryResult = [first]
      runtime.countResult = 1

      const insertedId = await service.insert(entity)
      const one = await service.getById(insertedId)
      const listed = await service.list(wrapper)
      const count = await service.count(wrapper)
      const page = await service.page(pageRequest, wrapper)
      const patched = await service.patchById(insertedId, patch)
      const removed = await service.removeById(insertedId)
      const removedBatch = await service.removeByIds([insertedId], true)

      runtime.countResult = 1
      const exists = await service.existsById(insertedId)

      expect(insertedId).assertEqual(7)
      expect(one?.id).assertEqual(7)
      expect(listed.length).assertEqual(1)
      expect(count).assertEqual(1)
      expect(page.total).assertEqual(1)
      expect(patched).assertTrue()
      expect(removed).assertTrue()
      expect(removedBatch).assertEqual(1)
      expect(exists).assertTrue()
    })

    it('service_impl_should_support_high_frequency_business_flow', 0, async () => {
      const normalized = normalizeEntityMeta(createDemoMeta())
      const runtime = new FakeRuntime()
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const service = new ServiceImpl<DemoRecord, number>(mapper)
      const first = new DemoRecord()
      const second = new DemoRecord()
      const query = new QueryWrapper<DemoRecord>(normalized)
      const patch = new UpdateWrapper<DemoRecord>(normalized)
      const pageRequest = new TestPageRequest()
      first.name = 'alpha'
      second.name = 'beta'
      pageRequest.current = 1
      pageRequest.size = 20

      const insertedIds = await service.insertBatch([first, second])
      runtime.queryResult = [first, second]
      runtime.countResult = 2
      query.eq('deleted', 0)
        .and((nested: QueryWrapper<DemoRecord>): void => {
          nested.likeRight('name', 'a')
        })
        .orderByDesc('updatedAt')
        .page(1, 20)
      patch.setIfDefined('name', 'gamma').setMany([{ property: 'updatedAt', value: 456 }])

      const listed = await service.list(query)
      const page = await service.page(pageRequest, query)
      const patched = await runtime.tx<boolean>(async (_scope): Promise<boolean> => {
        return service.patchById(insertedIds[0], patch)
      })
      const removed = await service.removeByIds(insertedIds)

      expect(insertedIds.length).assertEqual(2)
      expect(insertedIds[0]).assertEqual(7)
      expect(insertedIds[1]).assertEqual(8)
      expect(listed.length).assertEqual(2)
      expect(page.total).assertEqual(2)
      expect(page.records.length).assertEqual(2)
      expect(page.pages).assertEqual(1)
      expect(patched).assertTrue()
      expect(removed).assertEqual(2)
      expect(runtime.insertCount).assertEqual(2)
      expect(runtime.updateCount).assertEqual(3)
      expect(runtime.txCount).assertEqual(3)
    })

    it('runtime_tx_should_commit_and_close_scope_on_success', 0, async () => {
      const store = new FakeStore()
      const runtime = new StoreBackedRuntime('tx-success.db', store)
      const scopeHolder = new ScopeHolder()

      const result = await runtime.tx<number>(async (scope): Promise<number> => {
        scopeHolder.hasValue = true
        scopeHolder.scope = scope
        expect(scope.isActive()).assertTrue()
        return 9
      })

      expect(result).assertEqual(9)
      expect(store.beginCount).assertEqual(1)
      expect(store.commitCount).assertEqual(1)
      expect(store.rollbackCount).assertEqual(0)
      expect(scopeHolder.hasValue).assertTrue()
      expect(scopeHolder.scope.isActive()).assertFalse()
    })

    it('runtime_tx_should_rollback_and_wrap_error_on_failure', 0, async () => {
      const store = new FakeStore()
      const runtime = new StoreBackedRuntime('tx-failed.db', store)
      const scopeHolder = new ScopeHolder()
      const errorHolder = new ErrorCodeHolder()

      try {
        await runtime.tx<number>(async (scope): Promise<number> => {
          scopeHolder.hasValue = true
          scopeHolder.scope = scope
          throw new Error('boom')
        })
      } catch (error) {
        const txError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = txError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('TX_FAILED')
      expect(store.beginCount).assertEqual(1)
      expect(store.commitCount).assertEqual(0)
      expect(store.rollbackCount).assertEqual(1)
      expect(scopeHolder.hasValue).assertTrue()
      expect(scopeHolder.scope.isActive()).assertFalse()
    })

    it('runtime_tx_should_wrap_rollback_failure', 0, async () => {
      const store = new FakeStore()
      store.rollbackShouldThrow = true
      const runtime = new StoreBackedRuntime('tx-rollback-failed.db', store)
      const scopeHolder = new ScopeHolder()
      const errorHolder = new ErrorCodeHolder()

      try {
        await runtime.tx<number>(async (scope): Promise<number> => {
          scopeHolder.hasValue = true
          scopeHolder.scope = scope
          throw new Error('boom')
        })
      } catch (error) {
        const txError = error as RdbError
        errorHolder.hasValue = true
        errorHolder.code = txError.code
      }

      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('TX_ROLLBACK_FAILED')
      expect(store.beginCount).assertEqual(1)
      expect(store.commitCount).assertEqual(0)
      expect(store.rollbackCount).assertEqual(1)
      expect(scopeHolder.hasValue).assertTrue()
      expect(scopeHolder.scope.isActive()).assertFalse()
    })

    it('runtime_tx_should_reject_nested_transaction_on_same_runtime', 0, async () => {
      const store = new FakeStore()
      const runtime = new StoreBackedRuntime('nested.db', store)
      const errorHolder = new ErrorCodeHolder()

      const result = await runtime.tx<number>(async (_scope): Promise<number> => {
        try {
          await runtime.tx<number>(async (_innerScope): Promise<number> => {
            return 2
          })
        } catch (error) {
          const nestedError = error as RdbError
          errorHolder.hasValue = true
          errorHolder.code = nestedError.code
        }
        return 1
      })

      expect(result).assertEqual(1)
      expect(errorHolder.hasValue).assertTrue()
      expect(errorHolder.code).assertEqual('NESTED_TX_NOT_ALLOWED')
      expect(store.beginCount).assertEqual(1)
      expect(store.commitCount).assertEqual(1)
      expect(store.rollbackCount).assertEqual(0)
    })

    it('runtime_tx_should_allow_independent_transaction_on_other_runtime', 0, async () => {
      const storeA = new FakeStore()
      const storeB = new FakeStore()
      const runtimeA = new StoreBackedRuntime('db-a.db', storeA)
      const runtimeB = new StoreBackedRuntime('db-b.db', storeB)
      const resultHolder = new StringHolder()

      const result = await runtimeA.tx<number>(async (_scope): Promise<number> => {
        const innerResult = await runtimeB.tx<number>(async (_innerScope): Promise<number> => {
          return 2
        })
        resultHolder.hasValue = true
        resultHolder.value = `${innerResult}`
        return 1
      })

      expect(result).assertEqual(1)
      expect(resultHolder.hasValue).assertTrue()
      expect(resultHolder.value).assertEqual('2')
      expect(storeA.beginCount).assertEqual(1)
      expect(storeA.commitCount).assertEqual(1)
      expect(storeA.rollbackCount).assertEqual(0)
      expect(storeB.beginCount).assertEqual(1)
      expect(storeB.commitCount).assertEqual(1)
      expect(storeB.rollbackCount).assertEqual(0)
    })

    it('base_mapper_batch_should_reuse_outer_transaction_boundary', 0, async () => {
      const store = new FakeStore()
      const runtime = new StoreBackedRuntime('batch-boundary.db', store)
      const normalized = normalizeEntityMeta(createDemoMeta())
      const mapper = new BaseMapper<DemoRecord, number>(runtime, normalized)
      const first = new DemoRecord()
      const second = new DemoRecord()
      first.name = 'alpha'
      second.name = 'beta'
      let insertedIds: Array<number> = []

      const result = await runtime.tx<number>(async (_scope): Promise<number> => {
        insertedIds = await mapper.insertBatch([first, second])
        return insertedIds.length
      })

      expect(result).assertEqual(2)
      expect(insertedIds[0]).assertEqual(101)
      expect(insertedIds[1]).assertEqual(102)
      expect(first.id).assertEqual(101)
      expect(second.id).assertEqual(102)
      expect(store.beginCount).assertEqual(1)
      expect(store.commitCount).assertEqual(1)
      expect(store.rollbackCount).assertEqual(0)
      expect(store.insertCount).assertEqual(2)
    })
  })
}