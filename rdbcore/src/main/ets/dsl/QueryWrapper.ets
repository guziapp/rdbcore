import { NormalizedEntityMeta, RdbScalarValue, requireDeclaredField } from '../metadata'
import { RdbError } from '../runtime'

export const enum RdbQueryOperator {
  EQ = 'EQ',
  NE = 'NE',
  GT = 'GT',
  GTE = 'GTE',
  LT = 'LT',
  LTE = 'LTE',
  LIKE = 'LIKE',
  IN = 'IN',
  NOT_IN = 'NOT_IN',
  BETWEEN = 'BETWEEN',
  IS_NULL = 'IS_NULL',
  IS_NOT_NULL = 'IS_NOT_NULL'
}

export const enum RdbQueryJoin {
  AND = 'AND',
  OR = 'OR'
}

export const enum RdbQueryConditionKind {
  LEAF = 'LEAF',
  GROUP = 'GROUP'
}

export interface RdbQueryCondition {
  kind: RdbQueryConditionKind
  join: RdbQueryJoin
  property: string
  operator: RdbQueryOperator
  value: RdbScalarValue
  secondValue: RdbScalarValue
  values: Array<RdbScalarValue>
  children: Array<RdbQueryCondition>
}

export interface RdbQueryOrderBy {
  property: string
  ascending: boolean
}

export interface RdbQueryPage {
  current: number
  size: number
}

export interface RdbQueryWrapperState {
  includeDeleted: boolean
  conditions: Array<RdbQueryCondition>
  orders: Array<RdbQueryOrderBy>
  page: RdbQueryPage | null
}

export class QueryWrapper<T extends object> {
  private readonly entityMeta: NormalizedEntityMeta
  private readonly conditions: Array<RdbQueryCondition> = []
  private readonly orders: Array<RdbQueryOrderBy> = []
  private includeDeletedValue: boolean = false
  private pageValue: RdbQueryPage | null = null

  constructor(meta: NormalizedEntityMeta) {
    this.entityMeta = meta
  }

  meta(): NormalizedEntityMeta {
    return this.entityMeta
  }

  includeDeleted(value: boolean): QueryWrapper<T> {
    this.includeDeletedValue = value
    return this
  }

  eq(property: string, value: RdbScalarValue): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.EQ, value)
  }

  eqIf(condition: boolean, property: string, value: RdbScalarValue): QueryWrapper<T> {
    if (!condition) {
      return this
    }
    return this.eq(property, value)
  }

  ne(property: string, value: RdbScalarValue): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.NE, value)
  }

  gt(property: string, value: RdbScalarValue): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.GT, value)
  }

  gte(property: string, value: RdbScalarValue): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.GTE, value)
  }

  lt(property: string, value: RdbScalarValue): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.LT, value)
  }

  lte(property: string, value: RdbScalarValue): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.LTE, value)
  }

  like(property: string, value: string): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.LIKE, value)
  }

  likeIf(condition: boolean, property: string, value: string): QueryWrapper<T> {
    if (!condition) {
      return this
    }
    return this.like(property, value)
  }

  likeLeft(property: string, value: string): QueryWrapper<T> {
    return this.like(property, `%${value}`)
  }

  likeRight(property: string, value: string): QueryWrapper<T> {
    return this.like(property, `${value}%`)
  }

  in(property: string, values: Array<RdbScalarValue>): QueryWrapper<T> {
    return this.pushArrayCondition(property, RdbQueryOperator.IN, values, 'QueryWrapper.in requires a non-empty values array.')
  }

  inIf(condition: boolean, property: string, values: Array<RdbScalarValue>): QueryWrapper<T> {
    if (!condition) {
      return this
    }
    return this.in(property, values)
  }

  notIn(property: string, values: Array<RdbScalarValue>): QueryWrapper<T> {
    return this.pushArrayCondition(property, RdbQueryOperator.NOT_IN, values,
      'QueryWrapper.notIn requires a non-empty values array.')
  }

  between(property: string, start: RdbScalarValue, end: RdbScalarValue): QueryWrapper<T> {
    requireDeclaredField(this.entityMeta, property)
    if (start === undefined || end === undefined) {
      throw new RdbError('QUERY_WRAPPER_BETWEEN_RANGE_REQUIRED',
        'QueryWrapper.between requires both start and end.')
    }
    const condition: RdbQueryCondition = {
      kind: RdbQueryConditionKind.LEAF,
      join: RdbQueryJoin.AND,
      property: property,
      operator: RdbQueryOperator.BETWEEN,
      value: start,
      secondValue: end,
      values: [],
      children: []
    }
    this.conditions.push(condition)
    return this
  }

  betweenIf(condition: boolean, property: string, start: RdbScalarValue, end: RdbScalarValue): QueryWrapper<T> {
    if (!condition) {
      return this
    }
    return this.between(property, start, end)
  }

  isNull(property: string): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.IS_NULL, null)
  }

  isNotNull(property: string): QueryWrapper<T> {
    return this.pushUnaryCondition(property, RdbQueryOperator.IS_NOT_NULL, null)
  }

  and(builder: (wrapper: QueryWrapper<T>) => void): QueryWrapper<T> {
    return this.pushGroupCondition(RdbQueryJoin.AND, builder)
  }

  or(builder: (wrapper: QueryWrapper<T>) => void): QueryWrapper<T> {
    return this.pushGroupCondition(RdbQueryJoin.OR, builder)
  }

  orderBy(property: string, ascending: boolean = true): QueryWrapper<T> {
    requireDeclaredField(this.entityMeta, property)
    const orderBy: RdbQueryOrderBy = { property: property, ascending: ascending }
    this.orders.push(orderBy)
    return this
  }

  orderByAsc(property: string): QueryWrapper<T> {
    return this.orderBy(property, true)
  }

  orderByAscIf(condition: boolean, property: string): QueryWrapper<T> {
    if (!condition) {
      return this
    }
    return this.orderByAsc(property)
  }

  orderByDesc(property: string): QueryWrapper<T> {
    return this.orderBy(property, false)
  }

  orderByDescIf(condition: boolean, property: string): QueryWrapper<T> {
    if (!condition) {
      return this
    }
    return this.orderByDesc(property)
  }

  page(current: number, size: number): QueryWrapper<T> {
    if (current <= 0 || size <= 0) {
      throw new RdbError('QUERY_WRAPPER_INVALID_PAGE',
        'QueryWrapper.page requires positive current and size.')
    }
    this.pageValue = { current: current, size: size }
    return this
  }

  snapshot(): RdbQueryWrapperState {
    return {
      includeDeleted: this.includeDeletedValue,
      conditions: this.copyConditions(),
      orders: this.orders.slice(),
      page: this.pageValue
    }
  }

  private pushUnaryCondition(property: string, operator: RdbQueryOperator, value: RdbScalarValue): QueryWrapper<T> {
    requireDeclaredField(this.entityMeta, property)
    const condition: RdbQueryCondition = {
      kind: RdbQueryConditionKind.LEAF,
      join: RdbQueryJoin.AND,
      property: property,
      operator: operator,
      value: value,
      secondValue: null,
      values: [],
      children: []
    }
    this.conditions.push(condition)
    return this
  }

  private pushArrayCondition(
    property: string,
    operator: RdbQueryOperator,
    values: Array<RdbScalarValue>,
    errorMessage: string
  ): QueryWrapper<T> {
    requireDeclaredField(this.entityMeta, property)
    if (values.length === 0) {
      throw new RdbError('QUERY_WRAPPER_EMPTY_VALUES', errorMessage)
    }
    const condition: RdbQueryCondition = {
      kind: RdbQueryConditionKind.LEAF,
      join: RdbQueryJoin.AND,
      property: property,
      operator: operator,
      value: null,
      secondValue: null,
      values: values.slice(),
      children: []
    }
    this.conditions.push(condition)
    return this
  }

  private pushGroupCondition(join: RdbQueryJoin, builder: (wrapper: QueryWrapper<T>) => void): QueryWrapper<T> {
    const nested = new QueryWrapper<T>(this.entityMeta)
    builder(nested)
    const state = nested.snapshot()
    this.assertNestedGroupState(state)
    if (state.conditions.length === 0) {
      return this
    }
    const condition: RdbQueryCondition = {
      kind: RdbQueryConditionKind.GROUP,
      join: join,
      property: '',
      operator: RdbQueryOperator.EQ,
      value: null,
      secondValue: null,
      values: [],
      children: state.conditions
    }
    this.conditions.push(condition)
    return this
  }

  private assertNestedGroupState(state: RdbQueryWrapperState): void {
    if (state.orders.length > 0) {
      throw new RdbError('QUERY_WRAPPER_GROUP_STATE_NOT_SUPPORTED',
        'QueryWrapper grouped conditions do not support orderBy.')
    }
    if (state.page !== null) {
      throw new RdbError('QUERY_WRAPPER_GROUP_STATE_NOT_SUPPORTED',
        'QueryWrapper grouped conditions do not support page.')
    }
    if (state.includeDeleted) {
      throw new RdbError('QUERY_WRAPPER_GROUP_STATE_NOT_SUPPORTED',
        'QueryWrapper grouped conditions do not support includeDeleted.')
    }
  }

  private copyConditions(): Array<RdbQueryCondition> {
    const copied: Array<RdbQueryCondition> = []
    const size = this.conditions.length
    for (let index = 0; index < size; index++) {
      const current = this.conditions[index]
      copied.push({
        kind: current.kind,
        join: current.join,
        property: current.property,
        operator: current.operator,
        value: current.value,
        secondValue: current.secondValue,
        values: current.values.slice(),
        children: this.copyConditionChildren(current.children)
      })
    }
    return copied
  }

  private copyConditionChildren(children: Array<RdbQueryCondition>): Array<RdbQueryCondition> {
    const copied: Array<RdbQueryCondition> = []
    const size = children.length
    for (let index = 0; index < size; index++) {
      const current = children[index]
      copied.push({
        kind: current.kind,
        join: current.join,
        property: current.property,
        operator: current.operator,
        value: current.value,
        secondValue: current.secondValue,
        values: current.values.slice(),
        children: this.copyConditionChildren(current.children)
      })
    }
    return copied
  }
}