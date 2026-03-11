import { relationalStore } from '@kit.ArkData'
import { buildRdbPageResult, normalizeRdbPageRequest, RdbPage, RdbPageRequest } from './RdbPageModel'
import { QueryWrapper, UpdateWrapper } from '../dsl'
import { buildNormalizedEntityMetaSignature, NormalizedEntityMeta, requireDeclaredField } from '../metadata'
import {
  assignGeneratedId,
  compileQueryPredicates,
  prepareInsertValues,
  prepareLogicDeleteValues,
  preparePatchValues,
  prepareUpdateValuesFromEntity,
  RdbDatabaseRuntime,
  requireEntityIdValue,
  RdbError,
  toStoreValue
} from '../runtime'

export class BaseMapper<T extends object, ID> {
  protected readonly runtime: RdbDatabaseRuntime
  protected readonly entityMeta: NormalizedEntityMeta

  constructor(runtime: RdbDatabaseRuntime, meta: NormalizedEntityMeta) {
    this.runtime = runtime
    this.entityMeta = meta
  }

  meta(): NormalizedEntityMeta {
    return this.entityMeta
  }

  async insert(entity: T): Promise<ID> {
    const prepared = prepareInsertValues(this.entityMeta, entity as object)
    const insertedId = await this.runtime.insert(this.entityMeta, prepared.values)
    assignGeneratedId(this.entityMeta, entity as object, insertedId)
    return requireEntityIdValue(this.entityMeta, entity as object) as ID
  }

  async insertBatch(entities: Array<T>): Promise<Array<ID>> {
    if (entities.length === 0) {
      return []
    }
    return this.runtime.runInTransactionBoundary<Array<ID>>(async (): Promise<Array<ID>> => {
      const ids: Array<ID> = []
      const size = entities.length
      for (let index = 0; index < size; index++) {
        ids.push(await this.insert(entities[index]))
      }
      return ids
    })
  }

  async updateById(entity: T): Promise<boolean> {
    const idValue = requireEntityIdValue(this.entityMeta, entity as object)
    const prepared = prepareUpdateValuesFromEntity(this.entityMeta, entity as object)
    if (prepared.size === 0) {
      throw new RdbError('EMPTY_UPDATE_VALUES', `No updatable values found for ${this.entityMeta.entityName}.`)
    }
    const affected = await this.runtime.update(this.entityMeta, prepared.values, this.buildAliveIdPredicates(idValue))
    return affected > 0
  }

  async deleteById(id: ID, hardDelete: boolean = false): Promise<boolean> {
    const idValue = this.toIdValue(id)
    if (this.entityMeta.logicDelete !== null && !hardDelete) {
      const prepared = prepareLogicDeleteValues(this.entityMeta, true)
      const affected = await this.runtime.update(this.entityMeta, prepared.values, this.buildAliveIdPredicates(idValue))
      return affected > 0
    }
    const affected = await this.runtime.delete(this.entityMeta, this.buildIdPredicates(idValue))
    return affected > 0
  }

  async deleteBatchByIds(ids: Array<ID>, hardDelete: boolean = false): Promise<number> {
    if (ids.length === 0) {
      return 0
    }
    return this.runtime.runInTransactionBoundary<number>(async (): Promise<number> => {
      let affected: number = 0
      const size = ids.length
      for (let index = 0; index < size; index++) {
        if (await this.deleteById(ids[index], hardDelete)) {
          affected = affected + 1
        }
      }
      return affected
    })
  }

  async restoreById(id: ID): Promise<boolean> {
    if (this.entityMeta.logicDelete === null) {
      throw new RdbError('LOGIC_DELETE_NOT_SUPPORTED', `${this.entityMeta.entityName} does not support restoreById.`)
    }
    const idValue = this.toIdValue(id)
    const prepared = prepareLogicDeleteValues(this.entityMeta, false)
    const affected = await this.runtime.update(this.entityMeta, prepared.values, this.buildDeletedIdPredicates(idValue))
    return affected > 0
  }

  async selectById(id: ID, includeDeleted: boolean = false): Promise<T | null> {
    const idValue = this.toIdValue(id)
    const predicates = this.buildIdPredicates(idValue)
    if (this.entityMeta.logicDelete !== null && !includeDeleted) {
      const logicDeleteField = requireDeclaredField(this.entityMeta, this.entityMeta.logicDelete.field)
      predicates.equalTo(
        logicDeleteField.columnName,
        toStoreValue(this.entityMeta.logicDelete.aliveValue, this.entityMeta.entityName, logicDeleteField.property)
      )
    }
    predicates.limitAs(1)
    const result = await this.runtime.query<T>(this.entityMeta, predicates)
    return result.length > 0 ? result[0] : null
  }

  async selectList(wrapper?: QueryWrapper<T>): Promise<Array<T>> {
    const predicates = compileQueryPredicates(this.entityMeta, wrapper)
    return this.runtime.query<T>(this.entityMeta, predicates)
  }

  async selectOne(wrapper?: QueryWrapper<T>): Promise<T | null> {
    const predicates = compileQueryPredicates(this.entityMeta, wrapper)
    if (wrapper === undefined || wrapper.snapshot().page === null) {
      predicates.limitAs(2)
    }
    const result = await this.runtime.query<T>(this.entityMeta, predicates)
    if (result.length === 0) {
      return null
    }
    if (result.length > 1) {
      throw new RdbError('EXPECT_ONE_RECORD', `selectOne found more than one record for ${this.entityMeta.entityName}.`)
    }
    return result[0]
  }

  async selectCount(wrapper?: QueryWrapper<T>): Promise<number> {
    const predicates = compileQueryPredicates(this.entityMeta, wrapper, {
      applyOrders: false,
      applyPage: false
    })
    return this.runtime.count(this.entityMeta, predicates)
  }

  async selectPage(page: RdbPageRequest, wrapper?: QueryWrapper<T>): Promise<RdbPage<T>> {
    const normalizedPage = normalizeRdbPageRequest(this.entityMeta, page.current, page.size)
    const predicates = compileQueryPredicates(this.entityMeta, wrapper, {
      page: normalizedPage
    })
    const records = await this.runtime.query<T>(this.entityMeta, predicates)
    const total = await this.selectCount(wrapper)
    return buildRdbPageResult(normalizedPage, total, records)
  }

  async existsById(id: ID): Promise<boolean> {
    const total = await this.runtime.count(this.entityMeta, this.buildAliveIdPredicates(this.toIdValue(id)))
    return total > 0
  }

  async updatePatchById(id: ID, patch: UpdateWrapper<T>): Promise<boolean> {
    this.assertSameEntityMeta(patch.meta(), 'UpdateWrapper')
    const prepared = preparePatchValues(this.entityMeta, patch.snapshot())
    const affected = await this.runtime.update(this.entityMeta, prepared.values, this.buildAliveIdPredicates(this.toIdValue(id)))
    return affected > 0
  }

  async getById(id: ID, includeDeleted: boolean = false): Promise<T | null> {
    return this.selectById(id, includeDeleted)
  }

  async getOne(wrapper?: QueryWrapper<T>): Promise<T | null> {
    return this.selectOne(wrapper)
  }

  async list(wrapper?: QueryWrapper<T>): Promise<Array<T>> {
    return this.selectList(wrapper)
  }

  async count(wrapper?: QueryWrapper<T>): Promise<number> {
    return this.selectCount(wrapper)
  }

  async page(pageRequest: RdbPageRequest, wrapper?: QueryWrapper<T>): Promise<RdbPage<T>> {
    return this.selectPage(pageRequest, wrapper)
  }

  async removeById(id: ID, hardDelete: boolean = false): Promise<boolean> {
    return this.deleteById(id, hardDelete)
  }

  async removeByIds(ids: Array<ID>, hardDelete: boolean = false): Promise<number> {
    return this.deleteBatchByIds(ids, hardDelete)
  }

  async patchById(id: ID, patch: UpdateWrapper<T>): Promise<boolean> {
    return this.updatePatchById(id, patch)
  }

  private assertSameEntityMeta(otherMeta: NormalizedEntityMeta, sourceName: string): void {
    if (buildNormalizedEntityMetaSignature(this.entityMeta) === buildNormalizedEntityMetaSignature(otherMeta)) {
      return
    }
    throw new RdbError('ENTITY_META_MISMATCH', `${sourceName} entity mismatch for ${this.entityMeta.entityName}.`)
  }

  private buildAliveIdPredicates(idValue: relationalStore.ValueType): relationalStore.RdbPredicates {
    const predicates = this.buildIdPredicates(idValue)
    if (this.entityMeta.logicDelete !== null) {
      const logicDeleteField = requireDeclaredField(this.entityMeta, this.entityMeta.logicDelete.field)
      predicates.equalTo(
        logicDeleteField.columnName,
        toStoreValue(this.entityMeta.logicDelete.aliveValue, this.entityMeta.entityName, logicDeleteField.property)
      )
    }
    return predicates
  }

  private buildDeletedIdPredicates(idValue: relationalStore.ValueType): relationalStore.RdbPredicates {
    const predicates = this.buildIdPredicates(idValue)
    if (this.entityMeta.logicDelete === null) {
      return predicates
    }
    const logicDeleteField = requireDeclaredField(this.entityMeta, this.entityMeta.logicDelete.field)
    predicates.equalTo(
      logicDeleteField.columnName,
      toStoreValue(this.entityMeta.logicDelete.deletedValue, this.entityMeta.entityName, logicDeleteField.property)
    )
    return predicates
  }

  private buildIdPredicates(idValue: relationalStore.ValueType): relationalStore.RdbPredicates {
    const predicates = new relationalStore.RdbPredicates(this.entityMeta.tableName)
    const idField = requireDeclaredField(this.entityMeta, this.entityMeta.id.field)
    predicates.equalTo(idField.columnName, idValue)
    return predicates
  }

  private toIdValue(id: ID): relationalStore.ValueType {
    if (id === null || id === undefined) {
      throw new RdbError('ENTITY_ID_REQUIRED', `ID is required for ${this.entityMeta.entityName}.`)
    }
    const idType = typeof id
    if (idType === 'string' || idType === 'number' || idType === 'boolean' || idType === 'bigint') {
      return id as relationalStore.ValueType
    }
    throw new RdbError('UNSUPPORTED_ID_TYPE', `ID type is not supported for ${this.entityMeta.entityName}.`)
  }
}