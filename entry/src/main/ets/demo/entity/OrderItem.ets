/**
 * 订单明细实体
 * 
 * 演示明细实体定义，包含：
 * - 自增主键
 * - 外键字段（带索引）
 * - 商品快照字段
 * - 数量和金额
 * - 审计字段（仅创建时间）
 */
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbIdStrategy
} from 'rdbcore'

export const ORDER_ITEM_ENTITY_NAME: string = 'OrderItem'
export const ORDER_ITEM_TABLE_NAME: string = 'order_item'

@RdbEntity({
  entityName: ORDER_ITEM_ENTITY_NAME,
  tableName: ORDER_ITEM_TABLE_NAME,
  nowProvider: (): number => Date.now()
})
export class OrderItem {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn({
    name: 'order_id'
  })
  orderId: number = 0

  @RdbColumn({
    name: 'product_id'
  })
  productId: number = 0

  @RdbColumn({
    name: 'product_name'
  })
  productName: string = ''

  @RdbColumn()
  price: number = 0

  @RdbColumn()
  quantity: number = 1

  @RdbColumn()
  subtotal: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0
}
