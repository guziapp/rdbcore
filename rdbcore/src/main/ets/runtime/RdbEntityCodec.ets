import { relationalStore } from '@kit.ArkData'
import { NormalizedEntityMeta, requireDeclaredField } from '../metadata'
import { RdbPatchEntry, RdbPatchMode } from '../dsl'
import { RdbIdStrategy } from '../metadata/EntityMeta'
import { RdbError } from './RdbError'
import { createDynamicObject, hasDynamicField, readDynamicField, writeDynamicField } from './ObjectFieldAccess'

export interface PreparedValuesBucket {
  values: relationalStore.ValuesBucket
  size: number
}

export function prepareInsertValues(meta: NormalizedEntityMeta, entity: object): PreparedValuesBucket {
  const prepared = createPreparedValuesBucket()
  const fields = meta.fields
  const size = fields.length
  for (let index = 0; index < size; index++) {
    const field = fields[index]
    if (field.insertable !== true) {
      continue
    }
    if (field.property === meta.id.field && meta.id.strategy === RdbIdStrategy.AUTO) {
      continue
    }
    const value = readDynamicField(entity, field.property)
    if (value === undefined) {
      continue
    }
    upsertPreparedValue(prepared, field.columnName, toStoreValue(value, meta.entityName, field.property))
  }
  applyInsertDefaults(meta, prepared)
  return prepared
}

export function prepareUpdateValuesFromEntity(meta: NormalizedEntityMeta, entity: object): PreparedValuesBucket {
  const prepared = createPreparedValuesBucket()
  const fields = meta.fields
  const size = fields.length
  for (let index = 0; index < size; index++) {
    const field = fields[index]
    if (field.property === meta.id.field || field.updatable !== true) {
      continue
    }
    const value = readDynamicField(entity, field.property)
    if (value === undefined) {
      continue
    }
    upsertPreparedValue(prepared, field.columnName, toStoreValue(value, meta.entityName, field.property))
  }
  applyUpdateAudit(meta, prepared)
  return prepared
}

export function preparePatchValues(meta: NormalizedEntityMeta, patches: Array<RdbPatchEntry>): PreparedValuesBucket {
  if (patches.length === 0) {
    throw new RdbError('EMPTY_PATCH', `Update patch is empty for ${meta.entityName}.`)
  }
  const prepared = createPreparedValuesBucket()
  const size = patches.length
  for (let index = 0; index < size; index++) {
    const patch = patches[index]
    const field = requireDeclaredField(meta, patch.property)
    if (field.updatable !== true) {
      throw new RdbError('FIELD_NOT_UPDATABLE', `Field "${patch.property}" is not updatable in ${meta.entityName}.`)
    }
    const value = patch.mode === RdbPatchMode.CLEAR ? null : toStoreValue(patch.value, meta.entityName, patch.property)
    upsertPreparedValue(prepared, field.columnName, value)
  }
  applyUpdateAudit(meta, prepared)
  return prepared
}

export function prepareLogicDeleteValues(meta: NormalizedEntityMeta, deleted: boolean): PreparedValuesBucket {
  if (meta.logicDelete === null) {
    throw new RdbError('LOGIC_DELETE_NOT_SUPPORTED', `${meta.entityName} does not declare logicDelete metadata.`)
  }
  const prepared = createPreparedValuesBucket()
  const field = requireDeclaredField(meta, meta.logicDelete.field)
  const value = deleted ? meta.logicDelete.deletedValue : meta.logicDelete.aliveValue
  upsertPreparedValue(prepared, field.columnName, toStoreValue(value, meta.entityName, field.property))
  applyUpdateAudit(meta, prepared)
  return prepared
}

export function mapRowToEntity<T extends object>(meta: NormalizedEntityMeta, row: relationalStore.ValuesBucket): T {
  const entity = createDynamicObject()
  const fields = meta.fields
  const size = fields.length
  for (let index = 0; index < size; index++) {
    const field = fields[index]
    if (!hasDynamicField(row as object, field.columnName)) {
      continue
    }
    const value = readDynamicField(row as object, field.columnName)
    writeDynamicField(entity, field.property, value)
  }
  return entity as T
}

export function requireEntityIdValue(meta: NormalizedEntityMeta, entity: object): relationalStore.ValueType {
  const value = readDynamicField(entity, meta.id.field)
  if (value === undefined || value === null) {
    throw new RdbError('ENTITY_ID_REQUIRED', `Entity id field "${meta.id.field}" is required for ${meta.entityName}.`)
  }
  return toStoreValue(value, meta.entityName, meta.id.field)
}

export function assignGeneratedId(meta: NormalizedEntityMeta, entity: object, insertedId: number): void {
  if (meta.id.strategy !== RdbIdStrategy.AUTO) {
    return
  }
  writeDynamicField(entity, meta.id.field, insertedId)
}

export function toStoreValue(
  value: relationalStore.ValueType | Date | undefined,
  entityName: string,
  property: string
): relationalStore.ValueType {
  if (value === undefined || value === null) {
    return null
  }
  if (value instanceof Date) {
    return value.getTime()
  }
  if (value instanceof Uint8Array || value instanceof Float32Array) {
    return value
  }
  const typeOfValue = typeof value
  if (typeOfValue === 'string' || typeOfValue === 'number' || typeOfValue === 'boolean' || typeOfValue === 'bigint') {
    return value
  }
  throw new RdbError('UNSUPPORTED_FIELD_VALUE', `Field "${property}" on ${entityName} contains unsupported value type.`)
}

function createPreparedValuesBucket(): PreparedValuesBucket {
  return {
    values: {} as relationalStore.ValuesBucket,
    size: 0
  }
}

function applyInsertDefaults(meta: NormalizedEntityMeta, prepared: PreparedValuesBucket): void {
  if (meta.logicDelete !== null) {
    const logicField = requireDeclaredField(meta, meta.logicDelete.field)
    upsertPreparedValue(
      prepared,
      logicField.columnName,
      toStoreValue(meta.logicDelete.aliveValue, meta.entityName, logicField.property)
    )
  }
  if (meta.audit !== null) {
    const nowValue = resolveNowValue(meta)
    if (nowValue !== null) {
      if (meta.audit.createdAt !== undefined) {
        const createdAtField = requireDeclaredField(meta, meta.audit.createdAt)
        upsertPreparedValue(prepared, createdAtField.columnName, nowValue)
      }
      if (meta.audit.updatedAt !== undefined) {
        const updatedAtField = requireDeclaredField(meta, meta.audit.updatedAt)
        upsertPreparedValue(prepared, updatedAtField.columnName, nowValue)
      }
    }
  }
}

function applyUpdateAudit(meta: NormalizedEntityMeta, prepared: PreparedValuesBucket): void {
  if (meta.audit === null || meta.audit.updatedAt === undefined) {
    return
  }
  const nowValue = resolveNowValue(meta)
  if (nowValue === null) {
    return
  }
  const updatedAtField = requireDeclaredField(meta, meta.audit.updatedAt)
  upsertPreparedValue(prepared, updatedAtField.columnName, nowValue)
}

function resolveNowValue(meta: NormalizedEntityMeta): relationalStore.ValueType | null {
  if (meta.audit === null || meta.audit.nowProvider === undefined) {
    return null
  }
  return toStoreValue(meta.audit.nowProvider(), meta.entityName, 'audit.nowProvider')
}

function upsertPreparedValue(prepared: PreparedValuesBucket, columnName: string, value: relationalStore.ValueType): void {
  const valuesObject = prepared.values as object
  if (!hasDynamicField(valuesObject, columnName)) {
    prepared.size = prepared.size + 1
  }
  writeDynamicField(valuesObject, columnName, value)
}