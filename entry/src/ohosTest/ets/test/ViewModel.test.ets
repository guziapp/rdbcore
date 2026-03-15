/**
 * 视图模型测试
 *
 * 测试视图模型的状态管理和业务逻辑
 * 使用主代码的实体和服务
 */
import { hilog } from '@kit.PerformanceAnalysisKit'
import { describe, it, expect, beforeAll, afterAll, beforeEach } from '@ohos/hypium'
import { common } from '@kit.AbilityKit'
import { User, UserStatus } from 'entry/ets/demo/entity/User'
import { Product, ProductStatus } from 'entry/ets/demo/entity/Product'
import { Order, OrderStatus } from 'entry/ets/demo/entity/Order'
import { UserService, UserQueryParams } from 'entry/ets/demo/service/UserService'
import { ProductService, ProductQueryParams } from 'entry/ets/demo/service/ProductService'
import { OrderService, OrderQueryParams, OrderItemInput } from 'entry/ets/demo/service/OrderService'
import { DatabaseManager } from 'entry/ets/demo/service/DatabaseManager'
import { TestDataFactory } from './support/TestDataFactory'
import { obtainTestContext } from './support/TestContext'
import { clearAllTablesForMainDb, createAllTablesForMainDb } from './support/EntryTestSupport'

export default function viewModelTest(): void {
  describe('ViewModelTest', () => {
    let context: common.Context | null = null
    let userService: UserService | null = null
    let productService: ProductService | null = null
    let orderService: OrderService | null = null

    beforeAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'ViewModelTest beforeAll')
      
      // 重置主代码的 DatabaseManager 单例
      DatabaseManager.resetInstance()
      
      // 获取测试上下文
      context = await obtainTestContext()
      
      // 初始化主代码的 DatabaseManager
      await DatabaseManager.getInstance().initialize(requireContext(context))
      
      // 创建所有表
      await createAllTablesForMainDb(requireContext(context))
      
      // 创建服务实例
      userService = new UserService()
      productService = new ProductService()
      orderService = new OrderService()
    })

    afterAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'ViewModelTest afterAll')
      
      // 清理资源
      DatabaseManager.resetInstance()
    })

    beforeEach(async () => {
      // 清空所有表数据
      await clearAllTablesForMainDb(requireContext(context))
    })

    // ============ User ViewModel Tests ============
    describe('UserViewModelTest', () => {
      it('should_create_user_successfully', 0, async () => {
        const user = TestDataFactory.createUser()
        
        const id = await requireUserService(userService).create(user)
        
        expect(id).assertLarger(0)
      })

      it('should_list_users', 0, async () => {
        for (let i = 0; i < 3; i++) {
          const user = TestDataFactory.createUser()
          await requireUserService(userService).create(user)
        }

        const params = new UserQueryParams()
        const list = await requireUserService(userService).list(params)
        
        expect(list.length).assertLarger(0)
      })

      it('should_page_users', 0, async () => {
        for (let i = 0; i < 5; i++) {
          const user = TestDataFactory.createUser()
          await requireUserService(userService).create(user)
        }

        const params = new UserQueryParams()
        params.current = 1
        params.size = 3
        
        const page = await requireUserService(userService).page(params)
        
        expect(page.records.length).assertLarger(0)
        expect(page.total).assertLarger(0)
      })

      it('should_update_user', 0, async () => {
        const user = TestDataFactory.createUser()
        
        const id = await requireUserService(userService).create(user)

        const updates = new User()
        updates.nickname = 'After Update'
        const affected = await requireUserService(userService).update(id, updates)

        expect(affected).assertTrue()

        const updated = await requireUserService(userService).getById(id)
        expect(updated !== null).assertTrue()
        if (updated !== null) {
          expect(updated.nickname).assertEqual('After Update')
        }
      })

      it('should_delete_user', 0, async () => {
        const user = TestDataFactory.createUser()
        
        const id = await requireUserService(userService).create(user)
        
        const affected = await requireUserService(userService).delete(id)
        
        expect(affected).assertTrue()
        
        const found = await requireUserService(userService).getById(id)
        expect(found).assertNull()
      })
    })

    // ============ Product ViewModel Tests ============
    describe('ProductViewModelTest', () => {
      it('should_create_product_successfully', 0, async () => {
        const product = TestDataFactory.createProduct()
        
        const id = await requireProductService(productService).create(product)
        
        expect(id).assertLarger(0)
      })

      it('should_list_products', 0, async () => {
        for (let i = 0; i < 3; i++) {
          const product = TestDataFactory.createProduct()
          await requireProductService(productService).create(product)
        }

        const params = new ProductQueryParams()
        const list = await requireProductService(productService).list(params)
        
        expect(list.length).assertLarger(0)
      })

      it('should_page_products', 0, async () => {
        for (let i = 0; i < 5; i++) {
          const product = TestDataFactory.createProduct()
          await requireProductService(productService).create(product)
        }

        const params = new ProductQueryParams()
        params.current = 1
        params.size = 3
        
        const page = await requireProductService(productService).page(params)
        
        expect(page.records.length).assertLarger(0)
        expect(page.total).assertLarger(0)
      })
    })

    // ============ Order ViewModel Tests ============
    describe('OrderViewModelTest', () => {
      let testUserId: number = 0
      let testProductId: number = 0

      beforeEach(async () => {
        // 创建测试用户
        const user = TestDataFactory.createUser()
        testUserId = await requireUserService(userService).create(user)
        
        // 创建测试商品
        const product = TestDataFactory.createProduct()
        product.stock = 100
        product.status = ProductStatus.ON_SHELF
        testProductId = await requireProductService(productService).create(product)
      })

      it('should_create_order_successfully', 0, async () => {
        const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
        const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
        
        const result = await requireOrderService(orderService).create(input)
        
        expect(result.orderId).assertLarger(0)
      })

      it('should_list_orders', 0, async () => {
        for (let i = 0; i < 3; i++) {
          const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
          const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
          await requireOrderService(orderService).create(input)
        }

        const params = new OrderQueryParams()
        const list = await requireOrderService(orderService).list(params)
        
        expect(list.length).assertLarger(0)
      })

      it('should_page_orders', 0, async () => {
        for (let i = 0; i < 5; i++) {
          const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
          const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
          await requireOrderService(orderService).create(input)
        }

        const params = new OrderQueryParams()
        params.current = 1
        params.size = 3
        
        const page = await requireOrderService(orderService).page(params)
        
        expect(page.records.length).assertLarger(0)
        expect(page.total).assertLarger(0)
      })

      it('should_update_order_status', 0, async () => {
        const itemInput = TestDataFactory.createOrderItemInput(testProductId, 1)
        const input = TestDataFactory.createOrderInput(testUserId, [itemInput])
        
        const result = await requireOrderService(orderService).create(input)
        
        // 支付订单
        const affected = await requireOrderService(orderService).pay(result.orderId)

        expect(affected).assertTrue()

        const updated = await requireOrderService(orderService).getById(result.orderId)
        expect(updated !== null).assertTrue()
        if (updated !== null) {
          expect(updated.status).assertEqual(OrderStatus.PAID)
        }
      })
    })
  })
}

function requireContext(context: common.Context | null): common.Context {
  if (context === null) {
    throw new Error('test context is not ready')
  }
  return context
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

function requireOrderService(service: OrderService | null): OrderService {
  if (service === null) {
    throw new Error('order service is not ready')
  }
  return service
}
