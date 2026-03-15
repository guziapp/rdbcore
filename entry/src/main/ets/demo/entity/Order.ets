/**
 * 订单实体
 * 
 * 演示关联实体定义，包含：
 * - 自增主键
 * - 唯一业务编号
 * - 外键字段（带索引）
 * - 金额字段
 * - 状态字段
 * - 逻辑删除
 * - 审计字段
 */
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbIdStrategy,
  pageConfig
} from 'rdbcore'

export const ORDER_ENTITY_NAME: string = 'Order'
export const ORDER_TABLE_NAME: string = 'order_info'
export const ORDER_PAGE_SIZE: number = 20
export const ORDER_MAX_PAGE_SIZE: number = 100

@RdbEntity({
  entityName: ORDER_ENTITY_NAME,
  tableName: ORDER_TABLE_NAME,
  page: pageConfig(ORDER_PAGE_SIZE, ORDER_MAX_PAGE_SIZE),
  nowProvider: (): number => Date.now()
})
export class Order {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn({
    name: 'order_no'
  })
  orderNo: string = ''

  @RdbColumn({
    name: 'user_id'
  })
  userId: number = 0

  @RdbColumn({
    name: 'total_amount'
  })
  totalAmount: number = 0

  @RdbColumn()
  status: number = 0

  @RdbColumn()
  remark: string = ''

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}

/**
 * 订单状态枚举
 */
export class OrderStatus {
  static readonly PENDING_PAYMENT: number = 0
  static readonly PAID: number = 1
  static readonly SHIPPED: number = 2
  static readonly COMPLETED: number = 3
  static readonly CANCELLED: number = 4

  static is_valid(status: number): boolean {
    return status >= OrderStatus.PENDING_PAYMENT && status <= OrderStatus.CANCELLED
  }

  static label(status: number): string {
    if (status === OrderStatus.PENDING_PAYMENT) {
      return '待支付'
    }
    if (status === OrderStatus.PAID) {
      return '已支付'
    }
    if (status === OrderStatus.SHIPPED) {
      return '已发货'
    }
    if (status === OrderStatus.COMPLETED) {
      return '已完成'
    }
    if (status === OrderStatus.CANCELLED) {
      return '已取消'
    }
    return '未知'
  }
}
