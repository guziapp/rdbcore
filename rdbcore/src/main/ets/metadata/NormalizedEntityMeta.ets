import {
  EntityMeta,
  RdbAuditMeta,
  RdbFieldMeta,
  RdbIdMeta,
  RdbLogicDeleteMeta,
  RdbPageMeta
} from './EntityMeta'
import { RdbError } from './RdbError'

export interface NormalizedEntityMeta {
  entityName: string
  tableName: string
  fields: Array<RdbFieldMeta>
  id: RdbIdMeta
  logicDelete: RdbLogicDeleteMeta | null
  audit: RdbAuditMeta | null
  page: RdbPageMeta | null
  fieldMap: Map<string, RdbFieldMeta>
  columnMap: Map<string, RdbFieldMeta>
}

export function normalizeEntityMeta(meta: EntityMeta): NormalizedEntityMeta {
  assertNonBlank(meta.entityName, 'ENTITY_META_ENTITY_NAME_REQUIRED', 'EntityMeta.entityName is required.')
  assertNonBlank(meta.tableName, 'ENTITY_META_TABLE_NAME_REQUIRED', 'EntityMeta.tableName is required.')
  const fields = normalizeFields(meta.fields)
  const fieldMap = buildFieldMap(fields)
  const columnMap = buildColumnMap(fields)
  validateFieldExists(meta.id.field, fieldMap, 'ENTITY_META_FIELD_REFERENCE_INVALID', 'EntityMeta.id.field must exist in fields.')
  const audit = normalizeAudit(meta.audit, fieldMap)
  const logicDelete = normalizeLogicDelete(meta.logicDelete, fieldMap)
  const page = normalizePage(meta.page)
  return {
    entityName: meta.entityName,
    tableName: meta.tableName,
    fields: fields,
    id: { field: meta.id.field, strategy: meta.id.strategy },
    logicDelete: logicDelete,
    audit: audit,
    page: page,
    fieldMap: fieldMap,
    columnMap: columnMap
  }
}

export function buildNormalizedEntityMetaSignature(meta: NormalizedEntityMeta): string {
  let signature = `${meta.entityName}|${meta.tableName}|${meta.id.field}`
  const size = meta.fields.length
  for (let index = 0; index < size; index++) {
    const field = meta.fields[index]
    signature = `${signature}|${field.property}:${field.columnName}:${field.insertable === true}:${field.updatable === true}`
  }
  return signature
}

export function requireDeclaredField(meta: NormalizedEntityMeta, property: string): RdbFieldMeta {
  const field = meta.fieldMap.get(property)
  if (field === undefined) {
    throw new RdbError('FIELD_NOT_DECLARED', `Field "${property}" is not declared in ${meta.entityName}.`)
  }
  return field
}

function normalizeFields(fields: Array<RdbFieldMeta>): Array<RdbFieldMeta> {
  if (fields.length === 0) {
    throw new RdbError('ENTITY_META_FIELDS_REQUIRED', 'EntityMeta.fields must not be empty.')
  }
  const normalized: Array<RdbFieldMeta> = []
  const size = fields.length
  for (let index = 0; index < size; index++) {
    const field = fields[index]
    assertNonBlank(field.property, 'ENTITY_META_FIELD_PROPERTY_REQUIRED', 'EntityMeta.fields.property must not be empty.')
    assertNonBlank(field.columnName, 'ENTITY_META_FIELD_COLUMN_REQUIRED', 'EntityMeta.fields.columnName must not be empty.')
    const normalizedField: RdbFieldMeta = {
      property: field.property,
      columnName: field.columnName,
      nullable: field.nullable === true,
      insertable: field.insertable !== false,
      updatable: field.updatable !== false
    }
    normalized.push(normalizedField)
  }
  return normalized
}

function buildFieldMap(fields: Array<RdbFieldMeta>): Map<string, RdbFieldMeta> {
  const fieldMap = new Map<string, RdbFieldMeta>()
  const size = fields.length
  for (let index = 0; index < size; index++) {
    const field = fields[index]
    if (fieldMap.has(field.property)) {
      throw new RdbError('ENTITY_META_DUPLICATED_FIELD', `Duplicated field property "${field.property}".`)
    }
    fieldMap.set(field.property, field)
  }
  return fieldMap
}

function buildColumnMap(fields: Array<RdbFieldMeta>): Map<string, RdbFieldMeta> {
  const columnMap = new Map<string, RdbFieldMeta>()
  const size = fields.length
  for (let index = 0; index < size; index++) {
    const field = fields[index]
    if (columnMap.has(field.columnName)) {
      throw new RdbError('ENTITY_META_DUPLICATED_COLUMN', `Duplicated column name "${field.columnName}".`)
    }
    columnMap.set(field.columnName, field)
  }
  return columnMap
}

function normalizeLogicDelete(
  logicDelete: RdbLogicDeleteMeta | undefined,
  fieldMap: Map<string, RdbFieldMeta>
): RdbLogicDeleteMeta | null {
  if (logicDelete === undefined) {
    return null
  }
  validateFieldExists(
    logicDelete.field,
    fieldMap,
    'ENTITY_META_FIELD_REFERENCE_INVALID',
    'EntityMeta.logicDelete.field must exist in fields.'
  )
  return {
    field: logicDelete.field,
    aliveValue: logicDelete.aliveValue,
    deletedValue: logicDelete.deletedValue
  }
}

function normalizeAudit(
  audit: RdbAuditMeta | undefined,
  fieldMap: Map<string, RdbFieldMeta>
): RdbAuditMeta | null {
  if (audit === undefined) {
    return null
  }
  if (audit.createdAt !== undefined) {
    validateFieldExists(
      audit.createdAt,
      fieldMap,
      'ENTITY_META_FIELD_REFERENCE_INVALID',
      'EntityMeta.audit.createdAt must exist in fields.'
    )
  }
  if (audit.updatedAt !== undefined) {
    validateFieldExists(
      audit.updatedAt,
      fieldMap,
      'ENTITY_META_FIELD_REFERENCE_INVALID',
      'EntityMeta.audit.updatedAt must exist in fields.'
    )
  }
  return {
    createdAt: audit.createdAt,
    updatedAt: audit.updatedAt,
    nowProvider: audit.nowProvider
  }
}

function normalizePage(page: RdbPageMeta | undefined): RdbPageMeta | null {
  if (page === undefined) {
    return null
  }
  if (page.defaultSize !== undefined && page.defaultSize <= 0) {
    throw new RdbError('ENTITY_META_PAGE_DEFAULT_SIZE_INVALID', 'EntityMeta.page.defaultSize must be greater than 0.')
  }
  if (page.maxSize !== undefined && page.maxSize <= 0) {
    throw new RdbError('ENTITY_META_PAGE_MAX_SIZE_INVALID', 'EntityMeta.page.maxSize must be greater than 0.')
  }
  if (page.defaultSize !== undefined && page.maxSize !== undefined && page.defaultSize > page.maxSize) {
    throw new RdbError('ENTITY_META_PAGE_DEFAULT_EXCEEDS_MAX', 'EntityMeta.page.defaultSize must not exceed maxSize.')
  }
  return {
    defaultSize: page.defaultSize,
    maxSize: page.maxSize
  }
}

function validateFieldExists(
  fieldName: string,
  fieldMap: Map<string, RdbFieldMeta>,
  code: string,
  message: string
): void {
  assertNonBlank(fieldName, code, message)
  if (!fieldMap.has(fieldName)) {
    throw new RdbError(code, message)
  }
}

function assertNonBlank(value: string, code: string, message: string): void {
  if (value.length === 0) {
    throw new RdbError(code, message)
  }
}