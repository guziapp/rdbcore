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
import { DefineEntityMetaOptions, RdbFieldOptions, auditFields, defineEntityMeta, field, idField, logicDeleteField, pageConfig } from './EntityMetaDsl'
import { RdbError } from '../runtime'
import { ClassConstructor } from './ClassConstructor'

interface RdbDecoratedFieldTarget {
  constructor: ClassConstructor<object>
}

export interface RdbEntityOptions {
  entityName?: string
  tableName?: string
  page?: RdbPageMeta
  nowProvider?: () => Date | number
}

export const enum RdbColumnAuditKind {
  CREATED_AT = 'CREATED_AT',
  UPDATED_AT = 'UPDATED_AT'
}

export interface RdbColumnLogicDeleteOptions {
  aliveValue: RdbScalarValue
  deletedValue: RdbScalarValue
}

export interface RdbColumnOptions extends RdbFieldOptions {
  name?: string
  idStrategy?: RdbIdStrategy
  logicDelete?: RdbColumnLogicDeleteOptions
  audit?: RdbColumnAuditKind
}

interface RdbDecoratedEntityState {
  entityName?: string
  tableName?: string
  page?: RdbPageMeta
  nowProvider?: () => Date | number
  prototype?: object
  target?: ClassConstructor<object>
}

interface RdbDecoratedFieldState {
  property: string
  columnName?: string
  nullable?: boolean
  insertable?: boolean
  updatable?: boolean
  idStrategy?: RdbIdStrategy
  logicDelete?: RdbColumnLogicDeleteOptions
  audit?: RdbColumnAuditKind
}

const DECORATED_ENTITY_STATE_MAP: Map<string, RdbDecoratedEntityState> = new Map<string, RdbDecoratedEntityState>()
const DECORATED_FIELD_STATE_MAP: Map<object, Array<RdbDecoratedFieldState>> = new Map<object, Array<RdbDecoratedFieldState>>()
const DECORATED_FIELD_OWNER_MAP: Map<object, ClassConstructor<object>> = new Map<object, ClassConstructor<object>>()

export function RdbEntity(options?: RdbEntityOptions): (target: object) => void {
  const state = cloneEntityState(options)
  return (target: object): void => {
    const entity = target as ClassConstructor<object>
    const entityName = state.entityName === undefined ? entity.name : state.entityName
    const current = DECORATED_ENTITY_STATE_MAP.get(entityName)
    const nextState = current === undefined ? state : mergeEntityState(current, state)
    if (nextState.entityName === undefined) {
      nextState.entityName = entityName
    }
    if (nextState.tableName === undefined) {
      nextState.tableName = entity.name
    }
    nextState.prototype = entity.prototype as object
    nextState.target = entity
    DECORATED_ENTITY_STATE_MAP.set(entityName, nextState)
  }
}

export function RdbColumn(options?: RdbColumnOptions): (target: object, propertyKey: string) => void {
  const nextOptions = cloneColumnOptions(options)
  return (target: object, propertyKey: string): void => {
    rememberFieldOwner(target)
    const state = ensureFieldState(target, propertyKey)
    mergeColumnState(state, nextOptions)
  }
}

export function resolveDecoratedEntityMeta(entityName: string): EntityMeta {
  const entityState = DECORATED_ENTITY_STATE_MAP.get(entityName)
  if (entityState === undefined) {
    throw new RdbError('DECORATED_ENTITY_NOT_REGISTERED', `Decorated entity ${entityName} is not registered.`)
  }
  assertNoDecoratedInheritance(entityName, entityState.target)
  const fieldStates = entityState.prototype === undefined ? undefined : DECORATED_FIELD_STATE_MAP.get(entityState.prototype)
  const fields: Array<RdbFieldMeta> = []
  let id: RdbIdMeta | undefined = undefined
  let logicDelete: RdbLogicDeleteMeta | undefined = undefined
  let createdAt: string | undefined = undefined
  let updatedAt: string | undefined = undefined

  if (fieldStates !== undefined) {
    const size = fieldStates.length
    for (let index = 0; index < size; index++) {
      const state = fieldStates[index]
      fields.push(field(state.property, state.columnName, {
        nullable: state.nullable,
        insertable: state.insertable,
        updatable: state.updatable
      }))
      if (state.idStrategy !== undefined) {
        if (id !== undefined) {
          throw new RdbError(
            'DECORATED_ENTITY_DUPLICATED_ID',
            `Decorated entity ${entityName} declares duplicated id fields in @RdbColumn metadata.`
          )
        }
        id = idField(state.property, state.idStrategy)
      }
      if (state.logicDelete !== undefined) {
        if (logicDelete !== undefined) {
          throw new RdbError(
            'DECORATED_ENTITY_DUPLICATED_LOGIC_DELETE',
            `Decorated entity ${entityName} declares duplicated logic delete fields in @RdbColumn metadata.`
          )
        }
        logicDelete = logicDeleteField(state.property, state.logicDelete.aliveValue, state.logicDelete.deletedValue)
      }
      if (state.audit === RdbColumnAuditKind.CREATED_AT) {
        if (createdAt !== undefined) {
          throw new RdbError(
            'DECORATED_ENTITY_DUPLICATED_CREATED_AT',
            `Decorated entity ${entityName} declares duplicated createdAt audit fields in @RdbColumn metadata.`
          )
        }
        createdAt = state.property
      }
      if (state.audit === RdbColumnAuditKind.UPDATED_AT) {
        if (updatedAt !== undefined) {
          throw new RdbError(
            'DECORATED_ENTITY_DUPLICATED_UPDATED_AT',
            `Decorated entity ${entityName} declares duplicated updatedAt audit fields in @RdbColumn metadata.`
          )
        }
        updatedAt = state.property
      }
    }
  }

  if (id === undefined) {
    throw new RdbError(
      'DECORATED_ENTITY_ID_REQUIRED',
      `Decorated entity ${entityName} must declare exactly one id field in @RdbColumn metadata.`
    )
  }

  const options: DefineEntityMetaOptions = {
    entityName: entityState.entityName === undefined ? entityName : entityState.entityName,
    tableName: entityState.tableName === undefined ? entityName : entityState.tableName,
    fields: fields,
    id: id,
    logicDelete: logicDelete,
    audit: buildAuditMeta(createdAt, updatedAt, entityState.nowProvider),
    page: entityState.page === undefined ? undefined : pageConfig(entityState.page.defaultSize, entityState.page.maxSize)
  }
  return defineEntityMeta(options)
}

export function clearDecoratedEntityMetaForTest(entityName?: string): void {
  if (entityName === undefined) {
    DECORATED_ENTITY_STATE_MAP.clear()
    DECORATED_FIELD_STATE_MAP.clear()
    DECORATED_FIELD_OWNER_MAP.clear()
    return
  }
  const state = DECORATED_ENTITY_STATE_MAP.get(entityName)
  if (state?.prototype !== undefined) {
    DECORATED_FIELD_STATE_MAP.delete(state.prototype)
    DECORATED_FIELD_OWNER_MAP.delete(state.prototype)
  }
  DECORATED_ENTITY_STATE_MAP.delete(entityName)
}

function cloneEntityState(options?: RdbEntityOptions): RdbDecoratedEntityState {
  if (options === undefined) {
    return {}
  }
  return {
    entityName: options.entityName,
    tableName: options.tableName,
    page: options.page === undefined ? undefined : pageConfig(options.page.defaultSize, options.page.maxSize),
    nowProvider: options.nowProvider,
    prototype: undefined,
    target: undefined
  }
}

function mergeEntityState(current: RdbDecoratedEntityState, next: RdbDecoratedEntityState): RdbDecoratedEntityState {
  return {
    entityName: next.entityName === undefined ? current.entityName : next.entityName,
    tableName: next.tableName === undefined ? current.tableName : next.tableName,
    page: next.page === undefined ? current.page : pageConfig(next.page.defaultSize, next.page.maxSize),
    nowProvider: next.nowProvider === undefined ? current.nowProvider : next.nowProvider,
    prototype: next.prototype === undefined ? current.prototype : next.prototype,
    target: next.target === undefined ? current.target : next.target
  }
}

function rememberFieldOwner(target: object): void {
  if (DECORATED_FIELD_OWNER_MAP.get(target) !== undefined) {
    return
  }
  const fieldTarget = target as RdbDecoratedFieldTarget
  DECORATED_FIELD_OWNER_MAP.set(target, fieldTarget.constructor)
}

function ensureFieldState(target: object, property: string): RdbDecoratedFieldState {
  const current = DECORATED_FIELD_STATE_MAP.get(target)
  if (current === undefined) {
    const created: Array<RdbDecoratedFieldState> = [createFieldState(property)]
    DECORATED_FIELD_STATE_MAP.set(target, created)
    return created[0]
  }
  const size = current.length
  for (let index = 0; index < size; index++) {
    if (current[index].property === property) {
      return current[index]
    }
  }
  const appended = createFieldState(property)
  current.push(appended)
  return appended
}

function createFieldState(property: string): RdbDecoratedFieldState {
  return {
    property: property,
    columnName: property
  }
}

function mergeColumnState(state: RdbDecoratedFieldState, options?: RdbColumnOptions): void {
  if (options === undefined) {
    return
  }
  if (options.name !== undefined) {
    state.columnName = options.name
  }
  if (options.nullable !== undefined) {
    state.nullable = options.nullable
  }
  if (options.insertable !== undefined) {
    state.insertable = options.insertable
  }
  if (options.updatable !== undefined) {
    state.updatable = options.updatable
  }
  if (options.idStrategy !== undefined) {
    state.idStrategy = options.idStrategy
  }
  if (options.logicDelete !== undefined) {
    state.logicDelete = cloneLogicDeleteOptions(options.logicDelete)
  }
  if (options.audit !== undefined) {
    state.audit = options.audit
  }
}

function cloneColumnOptions(options?: RdbColumnOptions): RdbColumnOptions {
  if (options === undefined) {
    return {}
  }
  const clonedLogicDelete = options.logicDelete === undefined ? undefined : cloneLogicDeleteOptions(options.logicDelete)
  const updatable = resolveUpdatableOption(options)
  return {
    name: options.name,
    nullable: options.nullable,
    insertable: options.insertable,
    updatable: updatable,
    idStrategy: options.idStrategy,
    logicDelete: clonedLogicDelete,
    audit: options.audit
  }
}

function cloneLogicDeleteOptions(options: RdbColumnLogicDeleteOptions): RdbColumnLogicDeleteOptions {
  return {
    aliveValue: options.aliveValue,
    deletedValue: options.deletedValue
  }
}

function assertNoDecoratedInheritance(entityName: string, target?: ClassConstructor<object>): void {
  if (target === undefined) {
    return
  }
  DECORATED_FIELD_OWNER_MAP.forEach((owner: ClassConstructor<object>) => {
    if ((owner as object) !== (target as object) && target.prototype instanceof owner) {
      throw new RdbError(
        'DECORATED_ENTITY_INHERITED_FIELDS_NOT_SUPPORTED',
        `Decorated entity ${entityName} uses inherited @RdbColumn metadata, which is not supported. ` +
        `Please flatten the entity or fall back to defineEntityMeta(...).`
      )
    }
  })
}

function resolveUpdatableOption(options: RdbColumnOptions): boolean | undefined {
  if (options.updatable !== undefined) {
    return options.updatable
  }
  if (options.audit === RdbColumnAuditKind.CREATED_AT) {
    return false
  }
  return undefined
}

function buildAuditMeta(createdAt?: string, updatedAt?: string, nowProvider?: () => Date | number): RdbAuditMeta | undefined {
  if (createdAt === undefined && updatedAt === undefined && nowProvider === undefined) {
    return undefined
  }
  return auditFields(createdAt, updatedAt, nowProvider)
}