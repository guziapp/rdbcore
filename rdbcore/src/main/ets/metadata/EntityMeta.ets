export const enum RdbIdStrategy {
  AUTO = 'AUTO',
  INPUT = 'INPUT'
}

export type RdbScalarValue = string | number | boolean | Date | null

export interface RdbFieldMeta {
  property: string
  columnName: string
  nullable?: boolean
  insertable?: boolean
  updatable?: boolean
}

export interface RdbIdMeta {
  field: string
  strategy: RdbIdStrategy
}

export interface RdbLogicDeleteMeta {
  field: string
  aliveValue: RdbScalarValue
  deletedValue: RdbScalarValue
}

export interface RdbAuditMeta {
  createdAt?: string
  updatedAt?: string
  nowProvider?: () => Date | number
}

export interface RdbPageMeta {
  defaultSize?: number
  maxSize?: number
}

export interface EntityMeta {
  entityName: string
  tableName: string
  fields: Array<RdbFieldMeta>
  id: RdbIdMeta
  logicDelete?: RdbLogicDeleteMeta
  audit?: RdbAuditMeta
  page?: RdbPageMeta
}