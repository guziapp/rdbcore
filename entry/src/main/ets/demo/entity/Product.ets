/**
 * 商品实体
 * 
 * 演示完整实体定义，包含：
 * - 自增主键
 * - 唯一约束字段
 * - 默认值
 * - 索引字段
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

export const PRODUCT_ENTITY_NAME: string = 'Product'
export const PRODUCT_TABLE_NAME: string = 'product'
export const PRODUCT_PAGE_SIZE: number = 20
export const PRODUCT_MAX_PAGE_SIZE: number = 100

@RdbEntity({
  entityName: PRODUCT_ENTITY_NAME,
  tableName: PRODUCT_TABLE_NAME,
  page: pageConfig(PRODUCT_PAGE_SIZE, PRODUCT_MAX_PAGE_SIZE),
  nowProvider: (): number => Date.now()
})
export class Product {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  name: string = ''

  @RdbColumn({
    name: 'product_code'
  })
  productCode: string = ''

  @RdbColumn()
  price: number = 0

  @RdbColumn()
  stock: number = 0

  @RdbColumn()
  status: number = 1

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}

/**
 * 商品状态枚举
 */
export class ProductStatus {
  static readonly OFF_SHELF: number = 0
  static readonly ON_SHELF: number = 1
  static readonly SOLD_OUT: number = 2

  static is_valid(status: number): boolean {
    return status === ProductStatus.OFF_SHELF || status === ProductStatus.ON_SHELF || status === ProductStatus.SOLD_OUT
  }

  static label(status: number): string {
    if (status === ProductStatus.OFF_SHELF) {
      return '已下架'
    }
    if (status === ProductStatus.ON_SHELF) {
      return '在售'
    }
    if (status === ProductStatus.SOLD_OUT) {
      return '售罄'
    }
    return '未知'
  }
}
