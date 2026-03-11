import {
  EntityMeta,
  RdbAuditMeta,
  RdbFieldMeta,
  RdbIdMeta,
  RdbIdStrategy,
  RdbLogicDeleteMeta,
  RdbPageMeta,
  RdbScalarValue
} from './EntityMeta'

export interface RdbFieldOptions {
  nullable?: boolean
  insertable?: boolean
  updatable?: boolean
}

export interface DefineEntityMetaOptions {
  entityName: string
  tableName: string
  fields: Array<RdbFieldMeta>
  id: RdbIdMeta
  logicDelete?: RdbLogicDeleteMeta
  audit?: RdbAuditMeta
  page?: RdbPageMeta
}

export function defineEntityMeta(options: DefineEntityMetaOptions): EntityMeta {
  return {
    entityName: options.entityName,
    tableName: options.tableName,
    fields: cloneFields(options.fields),
    id: idField(options.id.field, options.id.strategy),
    logicDelete: cloneLogicDelete(options.logicDelete),
    audit: cloneAudit(options.audit),
    page: clonePage(options.page)
  }
}

export function field(property: string, columnName?: string, options?: RdbFieldOptions): RdbFieldMeta {
  return {
    property: property,
    columnName: columnName === undefined ? property : columnName,
    nullable: options?.nullable,
    insertable: options?.insertable,
    updatable: options?.updatable
  }
}

export function idField(property: string, strategy: RdbIdStrategy): RdbIdMeta {
  return {
    field: property,
    strategy: strategy
  }
}

export function logicDeleteField(
  property: string,
  aliveValue: RdbScalarValue,
  deletedValue: RdbScalarValue
): RdbLogicDeleteMeta {
  return {
    field: property,
    aliveValue: aliveValue,
    deletedValue: deletedValue
  }
}

export function auditFields(createdAt?: string, updatedAt?: string, nowProvider?: () => Date | number): RdbAuditMeta {
  return {
    createdAt: createdAt,
    updatedAt: updatedAt,
    nowProvider: nowProvider
  }
}

export function pageConfig(defaultSize?: number, maxSize?: number): RdbPageMeta {
  return {
    defaultSize: defaultSize,
    maxSize: maxSize
  }
}

function cloneFields(fields: Array<RdbFieldMeta>): Array<RdbFieldMeta> {
  const cloned: Array<RdbFieldMeta> = []
  const size = fields.length
  for (let index = 0; index < size; index++) {
    const current = fields[index]
    cloned.push({
      property: current.property,
      columnName: current.columnName,
      nullable: current.nullable,
      insertable: current.insertable,
      updatable: current.updatable
    })
  }
  return cloned
}

function cloneLogicDelete(logicDelete?: RdbLogicDeleteMeta): RdbLogicDeleteMeta | undefined {
  if (logicDelete === undefined) {
    return undefined
  }
  return {
    field: logicDelete.field,
    aliveValue: logicDelete.aliveValue,
    deletedValue: logicDelete.deletedValue
  }
}

function cloneAudit(audit?: RdbAuditMeta): RdbAuditMeta | undefined {
  if (audit === undefined) {
    return undefined
  }
  return {
    createdAt: audit.createdAt,
    updatedAt: audit.updatedAt,
    nowProvider: audit.nowProvider
  }
}

function clonePage(page?: RdbPageMeta): RdbPageMeta | undefined {
  if (page === undefined) {
    return undefined
  }
  return {
    defaultSize: page.defaultSize,
    maxSize: page.maxSize
  }
}