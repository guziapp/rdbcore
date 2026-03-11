import { relationalStore } from '@kit.ArkData'
import { normalizeRdbPageRequest, RdbPageRequest } from '../api/RdbPageModel'
import {
  QueryWrapper,
  RdbQueryCondition,
  RdbQueryConditionKind,
  RdbQueryJoin,
  RdbQueryOperator,
  RdbQueryWrapperState
} from '../dsl'
import { buildNormalizedEntityMetaSignature, NormalizedEntityMeta, requireDeclaredField } from '../metadata'
import { RdbError } from './RdbError'
import { toStoreValue } from './RdbEntityCodec'

export function compileQueryPredicates<T extends object>(
  meta: NormalizedEntityMeta,
  wrapper?: QueryWrapper<T>,
  options?: RdbPredicatesCompileOptions
): relationalStore.RdbPredicates {
  const predicates = new relationalStore.RdbPredicates(meta.tableName)
  const state = resolveQueryState(meta, wrapper)
  if (state !== null) {
    applyQueryConditions(meta, predicates, state)
    if (shouldApplyOrders(options)) {
      applyQueryOrders(meta, predicates, state)
    }
  }
  if (shouldApplyPage(options)) {
    applyQueryPage(meta, predicates, state, resolveOverridePage(options))
  }
  applyDefaultLogicDeleteCondition(meta, predicates, state)
  return predicates
}

export interface RdbPredicatesCompileOptions {
  applyOrders?: boolean
  applyPage?: boolean
  page?: RdbPageRequest | null
}

function shouldApplyOrders(options?: RdbPredicatesCompileOptions): boolean {
  return options === undefined || options.applyOrders === undefined ? true : options.applyOrders
}

function shouldApplyPage(options?: RdbPredicatesCompileOptions): boolean {
  return options === undefined || options.applyPage === undefined ? true : options.applyPage
}

function resolveOverridePage(options?: RdbPredicatesCompileOptions): RdbPageRequest | null | undefined {
  return options === undefined ? undefined : options.page
}

function resolveQueryState<T extends object>(
  meta: NormalizedEntityMeta,
  wrapper?: QueryWrapper<T>
): RdbQueryWrapperState | null {
  if (wrapper === undefined) {
    return null
  }
  const wrapperMeta = wrapper.meta()
  if (buildNormalizedEntityMetaSignature(wrapperMeta) !== buildNormalizedEntityMetaSignature(meta)) {
    throw new RdbError('QUERY_WRAPPER_ENTITY_MISMATCH', `QueryWrapper entity mismatch for ${meta.entityName}.`)
  }
  return wrapper.snapshot()
}

function applyQueryConditions(
  meta: NormalizedEntityMeta,
  predicates: relationalStore.RdbPredicates,
  state: RdbQueryWrapperState
): void {
  applyConditionList(meta, predicates, state.conditions)
}

function applyConditionList(
  meta: NormalizedEntityMeta,
  predicates: relationalStore.RdbPredicates,
  conditions: Array<RdbQueryCondition>
): void {
  const size = conditions.length
  for (let index = 0; index < size; index++) {
    const condition = conditions[index]
    applyCondition(meta, predicates, condition, index === 0)
  }
}

function applyCondition(
  meta: NormalizedEntityMeta,
  predicates: relationalStore.RdbPredicates,
  condition: RdbQueryCondition,
  isFirst: boolean
): void {
  if (!isFirst && condition.join === RdbQueryJoin.OR) {
    predicates.or()
  }
  if (condition.kind === RdbQueryConditionKind.GROUP) {
    predicates.beginWrap()
    applyConditionList(meta, predicates, condition.children)
    predicates.endWrap()
    return
  }
  applyLeafCondition(meta, predicates, condition)
}

function applyLeafCondition(
  meta: NormalizedEntityMeta,
  predicates: relationalStore.RdbPredicates,
  condition: RdbQueryCondition
): void {
  const field = requireDeclaredField(meta, condition.property)
  const columnName = field.columnName
  if (condition.operator === RdbQueryOperator.EQ) {
    predicates.equalTo(columnName, toStoreValue(condition.value, meta.entityName, condition.property))
    return
  }
  if (condition.operator === RdbQueryOperator.NE) {
    predicates.notEqualTo(columnName, toStoreValue(condition.value, meta.entityName, condition.property))
    return
  }
  if (condition.operator === RdbQueryOperator.GT) {
    predicates.greaterThan(columnName, toStoreValue(condition.value, meta.entityName, condition.property))
    return
  }
  if (condition.operator === RdbQueryOperator.GTE) {
    predicates.greaterThanOrEqualTo(columnName, toStoreValue(condition.value, meta.entityName, condition.property))
    return
  }
  if (condition.operator === RdbQueryOperator.LT) {
    predicates.lessThan(columnName, toStoreValue(condition.value, meta.entityName, condition.property))
    return
  }
  if (condition.operator === RdbQueryOperator.LTE) {
    predicates.lessThanOrEqualTo(columnName, toStoreValue(condition.value, meta.entityName, condition.property))
    return
  }
  if (condition.operator === RdbQueryOperator.LIKE) {
    predicates.like(columnName, String(condition.value))
    return
  }
  if (condition.operator === RdbQueryOperator.IN) {
    predicates.in(columnName, toStoreValues(meta, condition))
    return
  }
  if (condition.operator === RdbQueryOperator.NOT_IN) {
    predicates.notIn(columnName, toStoreValues(meta, condition))
    return
  }
  if (condition.operator === RdbQueryOperator.BETWEEN) {
    predicates.between(
      columnName,
      toStoreValue(condition.value, meta.entityName, condition.property),
      toStoreValue(condition.secondValue, meta.entityName, condition.property)
    )
    return
  }
  if (condition.operator === RdbQueryOperator.IS_NULL) {
    predicates.isNull(columnName)
    return
  }
  predicates.isNotNull(columnName)
}

function toStoreValues(meta: NormalizedEntityMeta, condition: RdbQueryCondition): Array<relationalStore.ValueType> {
  const values: Array<relationalStore.ValueType> = []
  const size = condition.values.length
  for (let index = 0; index < size; index++) {
    values.push(toStoreValue(condition.values[index], meta.entityName, condition.property))
  }
  return values
}

function applyQueryOrders(
  meta: NormalizedEntityMeta,
  predicates: relationalStore.RdbPredicates,
  state: RdbQueryWrapperState
): void {
  const size = state.orders.length
  for (let index = 0; index < size; index++) {
    const order = state.orders[index]
    const field = requireDeclaredField(meta, order.property)
    if (order.ascending) {
      predicates.orderByAsc(field.columnName)
    } else {
      predicates.orderByDesc(field.columnName)
    }
  }
}

function applyQueryPage(
  meta: NormalizedEntityMeta,
  predicates: relationalStore.RdbPredicates,
  state: RdbQueryWrapperState | null,
  overridePage?: RdbPageRequest | null
): void {
  const page = overridePage === undefined ? (state === null ? null : state.page) : overridePage
  if (page === null) {
    return
  }
  const normalizedPage = normalizeRdbPageRequest(meta, page.current, page.size)
  predicates.limitAs(normalizedPage.size)
  predicates.offsetAs((normalizedPage.current - 1) * normalizedPage.size)
}

function applyDefaultLogicDeleteCondition(
  meta: NormalizedEntityMeta,
  predicates: relationalStore.RdbPredicates,
  state: RdbQueryWrapperState | null
): void {
  if (meta.logicDelete === null) {
    return
  }
  if (state !== null && state.includeDeleted) {
    return
  }
  const field = requireDeclaredField(meta, meta.logicDelete.field)
  predicates.equalTo(field.columnName, toStoreValue(meta.logicDelete.aliveValue, meta.entityName, field.property))
}