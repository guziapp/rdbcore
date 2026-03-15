/**
 * 实体模型测试
 * 
 * 测试实体定义、状态枚举等功能
 */
import { hilog } from '@kit.PerformanceAnalysisKit'
import { describe, it, expect } from '@ohos/hypium'
import { 
  User, 
  UserStatus, 
  USER_ENTITY_NAME, 
  USER_TABLE_NAME,
  Product, 
  ProductStatus, 
  PRODUCT_ENTITY_NAME, 
  PRODUCT_TABLE_NAME,
  Order, 
  OrderStatus, 
  ORDER_ENTITY_NAME, 
  ORDER_TABLE_NAME,
  OrderItem,
  ORDER_ITEM_ENTITY_NAME,
  ORDER_ITEM_TABLE_NAME
} from '../../../main/ets/demo/entity'
import { resolveDecoratedEntityMeta } from 'rdbcore'

export default function entityTest(): void {
  describe('EntityTest', () => {
    
    // ============ User Entity Tests ============
    describe('UserEntityTest', () => {
      it('user_entity_name_should_be_correct', 0, () => {
        expect(USER_ENTITY_NAME).assertEqual('User')
      })

      it('user_table_name_should_be_correct', 0, () => {
        expect(USER_TABLE_NAME).assertEqual('user')
      })

      it('user_meta_should_have_correct_fields', 0, () => {
        const meta = resolveDecoratedEntityMeta(USER_ENTITY_NAME)
        expect(meta.entityName).assertEqual('User')
        expect(meta.tableName).assertEqual('user')
        expect(meta.fields.length).assertLarger(0)
      })

      it('user_instance_should_have_default_values', 0, () => {
        const user = new User()
        expect(user.id).assertEqual(0)
        expect(user.username).assertEqual('')
        expect(user.nickname).assertEqual('')
        expect(user.status).assertEqual(0)
        expect(user.deleted).assertEqual(0)
      })

      it('user_status_is_valid_should_work', 0, () => {
        expect(UserStatus.is_valid(UserStatus.INACTIVE)).assertTrue()
        expect(UserStatus.is_valid(UserStatus.ACTIVE)).assertTrue()
        expect(UserStatus.is_valid(UserStatus.BANNED)).assertTrue()
        expect(UserStatus.is_valid(999)).assertFalse()
      })

      it('user_status_label_should_work', 0, () => {
        expect(UserStatus.label(UserStatus.INACTIVE)).assertEqual('未激活')
        expect(UserStatus.label(UserStatus.ACTIVE)).assertEqual('已激活')
        expect(UserStatus.label(UserStatus.BANNED)).assertEqual('已禁用')
        expect(UserStatus.label(999)).assertEqual('未知')
      })
    })

    // ============ Product Entity Tests ============
    describe('ProductEntityTest', () => {
      it('product_entity_name_should_be_correct', 0, () => {
        expect(PRODUCT_ENTITY_NAME).assertEqual('Product')
      })

      it('product_table_name_should_be_correct', 0, () => {
        expect(PRODUCT_TABLE_NAME).assertEqual('product')
      })

      it('product_meta_should_have_correct_fields', 0, () => {
        const meta = resolveDecoratedEntityMeta(PRODUCT_ENTITY_NAME)
        expect(meta.entityName).assertEqual('Product')
        expect(meta.tableName).assertEqual('product')
        expect(meta.fields.length).assertLarger(0)
      })

      it('product_instance_should_have_default_values', 0, () => {
        const product = new Product()
        expect(product.id).assertEqual(0)
        expect(product.name).assertEqual('')
        expect(product.productCode).assertEqual('')
        expect(product.price).assertEqual(0)
        expect(product.stock).assertEqual(0)
        expect(product.status).assertEqual(1)
      })

      it('product_status_is_valid_should_work', 0, () => {
        expect(ProductStatus.is_valid(ProductStatus.OFF_SHELF)).assertTrue()
        expect(ProductStatus.is_valid(ProductStatus.ON_SHELF)).assertTrue()
        expect(ProductStatus.is_valid(ProductStatus.SOLD_OUT)).assertTrue()
        expect(ProductStatus.is_valid(999)).assertFalse()
      })

      it('product_status_label_should_work', 0, () => {
        expect(ProductStatus.label(ProductStatus.OFF_SHELF)).assertEqual('已下架')
        expect(ProductStatus.label(ProductStatus.ON_SHELF)).assertEqual('在售')
        expect(ProductStatus.label(ProductStatus.SOLD_OUT)).assertEqual('售罄')
        expect(ProductStatus.label(999)).assertEqual('未知')
      })
    })

    // ============ Order Entity Tests ============
    describe('OrderEntityTest', () => {
      it('order_entity_name_should_be_correct', 0, () => {
        expect(ORDER_ENTITY_NAME).assertEqual('Order')
      })

      it('order_table_name_should_be_correct', 0, () => {
        expect(ORDER_TABLE_NAME).assertEqual('order_info')
      })

      it('order_meta_should_have_correct_fields', 0, () => {
        const meta = resolveDecoratedEntityMeta(ORDER_ENTITY_NAME)
        expect(meta.entityName).assertEqual('Order')
        expect(meta.tableName).assertEqual('order_info')
        expect(meta.fields.length).assertLarger(0)
      })

      it('order_instance_should_have_default_values', 0, () => {
        const order = new Order()
        expect(order.id).assertEqual(0)
        expect(order.orderNo).assertEqual('')
        expect(order.userId).assertEqual(0)
        expect(order.totalAmount).assertEqual(0)
        expect(order.status).assertEqual(0)
        expect(order.remark).assertEqual('')
      })

      it('order_status_is_valid_should_work', 0, () => {
        expect(OrderStatus.is_valid(OrderStatus.PENDING_PAYMENT)).assertTrue()
        expect(OrderStatus.is_valid(OrderStatus.PAID)).assertTrue()
        expect(OrderStatus.is_valid(OrderStatus.SHIPPED)).assertTrue()
        expect(OrderStatus.is_valid(OrderStatus.COMPLETED)).assertTrue()
        expect(OrderStatus.is_valid(OrderStatus.CANCELLED)).assertTrue()
        expect(OrderStatus.is_valid(999)).assertFalse()
      })

      it('order_status_label_should_work', 0, () => {
        expect(OrderStatus.label(OrderStatus.PENDING_PAYMENT)).assertEqual('待支付')
        expect(OrderStatus.label(OrderStatus.PAID)).assertEqual('已支付')
        expect(OrderStatus.label(OrderStatus.SHIPPED)).assertEqual('已发货')
        expect(OrderStatus.label(OrderStatus.COMPLETED)).assertEqual('已完成')
        expect(OrderStatus.label(OrderStatus.CANCELLED)).assertEqual('已取消')
        expect(OrderStatus.label(999)).assertEqual('未知')
      })
    })

    // ============ OrderItem Entity Tests ============
    describe('OrderItemEntityTest', () => {
      it('order_item_entity_name_should_be_correct', 0, () => {
        expect(ORDER_ITEM_ENTITY_NAME).assertEqual('OrderItem')
      })

      it('order_item_table_name_should_be_correct', 0, () => {
        expect(ORDER_ITEM_TABLE_NAME).assertEqual('order_item')
      })

      it('order_item_meta_should_have_correct_fields', 0, () => {
        const meta = resolveDecoratedEntityMeta(ORDER_ITEM_ENTITY_NAME)
        expect(meta.entityName).assertEqual('OrderItem')
        expect(meta.tableName).assertEqual('order_item')
        expect(meta.fields.length).assertLarger(0)
      })

      it('order_item_instance_should_have_default_values', 0, () => {
        const orderItem = new OrderItem()
        expect(orderItem.id).assertEqual(0)
        expect(orderItem.orderId).assertEqual(0)
        expect(orderItem.productId).assertEqual(0)
        expect(orderItem.productName).assertEqual('')
        expect(orderItem.price).assertEqual(0)
        expect(orderItem.quantity).assertEqual(1)
        expect(orderItem.subtotal).assertEqual(0)
      })
    })
  })
}
