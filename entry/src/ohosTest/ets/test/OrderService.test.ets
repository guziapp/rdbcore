/**
 * 订单服务测试
 *
 * 测试订单创建、状态流转、查询等功能
 * 使用主代码的 Order、OrderItem 实体和 OrderService 服务
 */
import { hilog } from '@kit.PerformanceAnalysisKit'
import { describe, it, expect, beforeAll, afterAll, beforeEach } from '@ohos/hypium'
import { common } from '@kit.AbilityKit'
import { Order, OrderStatus } from 'entry/ets/demo/entity/Order'
import { OrderItem } from 'entry/ets/demo/entity/OrderItem'
import { User, UserStatus } from 'entry/ets/demo/entity/User'
import { Product, ProductStatus } from 'entry/ets/demo/entity/Product'
import { OrderService, OrderQueryParams, CreateOrderInput, OrderItemInput } from 'entry/ets/demo/service/OrderService'
import { UserService } from 'entry/ets/demo/service/UserService'
import { ProductService } from 'entry/ets/demo/service/ProductService'
import { DatabaseManager } from 'entry/ets/demo/service/DatabaseManager'
import { TestDataFactory } from './support/TestDataFactory'
import { obtainTestContext } from './support/TestContext'
import { clearAllTablesForMainDb, clearOrderTablesForMainDb, createAllTablesForMainDb } from './support/EntryTestSupport'

export default function orderServiceTest(): void {
  describe('OrderServiceTest', () => {
    let context: common.Context | null = null
    let orderService: OrderService | null = null
    let userService: UserService | null = null
    let productService: ProductService | null = null
    
    // 测试数据
    let testUserId: number = 0
    let testProductId: number = 0

    beforeAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'OrderServiceTest beforeAll')
      
      // 重置主代码的 DatabaseManager 单例
      DatabaseManager.resetInstance()
      
      // 获取测试上下文
      context = await obtainTestContext()
      
      // 初始化主代码的 DatabaseManager
      await DatabaseManager.getInstance().initialize(requireContext(context))
      
      // 创建所有表
      await createAllTablesForMainDb(requireContext(context))
      
      // 创建服务实例
      orderService = new OrderService()
      userService = new UserService()
      productService = new ProductService()
    })

    afterAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'OrderServiceTest afterAll')
      
      // 清理资源
      DatabaseManager.resetInstance()
    })

    beforeEach(async () => {
      // 清空所有表数据
      await clearAllTablesForMainDb(requireContext(context))
      
      // 创建测试用户
      const user = TestDataFactory.createUser()
      user.username = 'order_test_user'
      user.status = UserStatus.ACTIVE
      testUserId = await requireUserService(userService).create(user)
      
      // 创建测试商品
      const product = TestDataFactory.createProduct()
      product.productCode = 'ORDER_TEST_PROD'
      product.price = 100.0
      product.stock = 100
      product.status = ProductStatus.ON_SHELF
      testProductId = await requireProductService(productService).create(product)
    })

    // ==================== 订单创建测试 ====================

    it('should_create_order_successfully', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 2)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      
      expect(result.orderId).assertLarger(0)
      expect(result.orderNo !== '').assertTrue()
      expect(result.totalAmount).assertEqual(200.0)
    })

    it('should_create_order_with_multiple_items', 0, async () => {
      // 创建第二个商品
      const product2 = TestDataFactory.createProduct()
      product2.price = 50.0
      product2.stock = 50
      product2.status = ProductStatus.ON_SHELF
      const product2Id = await requireProductService(productService).create(product2)
      
      const item1 = TestDataFactory.createOrderItemInput(testProductId, 2)
      const item2 = TestDataFactory.createOrderItemInput(product2Id, 3)
      const input = TestDataFactory.createOrderInput(testUserId, [item1, item2])
      
      const result = await requireOrderService(orderService).create(input)
      
      expect(result.orderId).assertLarger(0)
      expect(result.totalAmount).assertEqual(350.0) // 100*2 + 50*3
    })

    it('should_deduct_stock_when_create_order', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 5)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      await requireOrderService(orderService).create(input)
      
      const product = await requireProductService(productService).getById(testProductId)
      expect(product !== null).assertTrue()
      if (product !== null) {
        expect(product.stock).assertEqual(95) // 100 - 5
      }
    })

    it('should_throw_error_when_product_not_found', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(99999, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      let errorThrown = false
      try {
        await requireOrderService(orderService).create(input)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('商品不存在或已删除')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    it('should_throw_error_when_product_not_on_shelf', 0, async () => {
      // 创建未上架商品
      const product = TestDataFactory.createProduct()
      product.status = ProductStatus.OFF_SHELF
      const productId = await requireProductService(productService).create(product)
      
      const itemInput = TestDataFactory.createOrderItemInput(productId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      let errorThrown = false
      try {
        await requireOrderService(orderService).create(input)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('商品未上架')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    it('should_throw_error_when_insufficient_stock', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 200)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      let errorThrown = false
      try {
        await requireOrderService(orderService).create(input)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('商品库存不足')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    // ==================== 订单状态流转测试 ====================

    it('should_pay_order', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      
      const affected = await requireOrderService(orderService).pay(result.orderId)
      
      expect(affected).assertTrue()
      
      const order = await requireOrderService(orderService).getById(result.orderId)
      expect(order !== null).assertTrue()
      if (order !== null) {
        expect(order.status).assertEqual(OrderStatus.PAID)
      }
    })

    it('should_ship_order', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      await requireOrderService(orderService).pay(result.orderId)
      
      const affected = await requireOrderService(orderService).ship(result.orderId)
      
      expect(affected).assertTrue()
      
      const order = await requireOrderService(orderService).getById(result.orderId)
      expect(order !== null).assertTrue()
      if (order !== null) {
        expect(order.status).assertEqual(OrderStatus.SHIPPED)
      }
    })

    it('should_complete_order', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      await requireOrderService(orderService).pay(result.orderId)
      await requireOrderService(orderService).ship(result.orderId)
      
      const affected = await requireOrderService(orderService).complete(result.orderId)
      
      expect(affected).assertTrue()
      
      const order = await requireOrderService(orderService).getById(result.orderId)
      expect(order !== null).assertTrue()
      if (order !== null) {
        expect(order.status).assertEqual(OrderStatus.COMPLETED)
      }
    })

    it('should_cancel_order', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 5)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      
      // 记录扣减后的库存
      const productBefore = await requireProductService(productService).getById(testProductId)
      const stockBefore = productBefore !== null ? productBefore.stock : 0
      
      const affected = await requireOrderService(orderService).cancel(result.orderId)
      
      expect(affected).assertTrue()
      
      const order = await requireOrderService(orderService).getById(result.orderId)
      expect(order !== null).assertTrue()
      if (order !== null) {
        expect(order.status).assertEqual(OrderStatus.CANCELLED)
      }
      
      // 验证库存恢复
      const productAfter = await requireProductService(productService).getById(testProductId)
      expect(productAfter !== null).assertTrue()
      if (productAfter !== null) {
        expect(productAfter.stock).assertEqual(stockBefore + 5)
      }
    })

    it('should_throw_error_on_invalid_status_transition', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      
      // 尝试从待支付直接到已发货（非法流转）
      let errorThrown = false
      try {
        await requireOrderService(orderService).ship(result.orderId)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('Invalid status transition')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    it('should_throw_error_when_cancel_non_pending_order', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      await requireOrderService(orderService).pay(result.orderId)
      
      // 尝试取消已支付订单
      let errorThrown = false
      try {
        await requireOrderService(orderService).cancel(result.orderId)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('Only pending payment orders can be cancelled')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    // ==================== 订单查询测试 ====================

    it('should_get_order_by_id', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      
      const order = await requireOrderService(orderService).getById(result.orderId)
      
      expect(order !== null).assertTrue()
      if (order !== null) {
        expect(order.id).assertEqual(result.orderId)
        expect(order.orderNo).assertEqual(result.orderNo)
      }
    })

    it('should_get_order_by_order_no', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      
      const order = await requireOrderService(orderService).getByOrderNo(result.orderNo)
      
      expect(order !== null).assertTrue()
      if (order !== null) {
        expect(order.id).assertEqual(result.orderId)
      }
    })

    it('should_get_order_items', 0, async () => {
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 2)
      const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
      
      const result = await requireOrderService(orderService).create(input)
      
      const items = await requireOrderService(orderService).getOrderItems(result.orderId)
      
      expect(items.length).assertEqual(1)
      expect(items[0].productId).assertEqual(testProductId)
      expect(items[0].quantity).assertEqual(2)
    })

    it('should_page_orders', 0, async () => {
      // 创建多个订单
      for (let i = 0; i < 3; i++) {
        const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
        const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
        await requireOrderService(orderService).create(input)
      }

      const params = new OrderQueryParams()
      params.current = 1
      params.size = 2
      
      const page = await requireOrderService(orderService).page(params)
      
      expect(page.records.length).assertLarger(0)
      expect(page.total).assertLarger(0)
    })

    it('should_page_orders_with_user_filter', 0, async () => {
      // 创建另一个用户
      const user2 = TestDataFactory.createUser()
      user2.username = 'order_test_user2'
      const user2Id = await requireUserService(userService).create(user2)
      
      // 为两个用户创建订单
      for (let i = 0; i < 2; i++) {
        const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
        const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
        await requireOrderService(orderService).create(input)
      }
      
      const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
      const input = TestDataFactory.createOrderInput(user2Id, [itemInput])
      await requireOrderService(orderService).create(input)

      const params = new OrderQueryParams()
      params.userId = testUserId
      params.current = 1
      params.size = 20
      
      const page = await requireOrderService(orderService).page(params)
      
      expect(page.records.length).assertEqual(2)
    })

    it('should_count_orders_by_user_id', 0, async () => {
      // 创建多个订单
      for (let i = 0; i < 3; i++) {
        const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
        const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
        await requireOrderService(orderService).create(input)
      }

      const count = await requireOrderService(orderService).countByUserId(testUserId)
      
      expect(count).assertEqual(3)
    })
  })
}

function requireContext(context: common.Context | null): common.Context {
  if (context === null) {
    throw new Error('test context is not ready')
  }
  return context
}

function requireOrderService(service: OrderService | null): OrderService {
  if (service === null) {
    throw new Error('order service is not ready')
  }
  return service
}

function requireUserService(service: UserService | null): UserService {
  if (service === null) {
    throw new Error('user service is not ready')
  }
  return service
}

function requireProductService(service: ProductService | null): ProductService {
  if (service === null) {
    throw new Error('product service is not ready')
  }
  return service
}
