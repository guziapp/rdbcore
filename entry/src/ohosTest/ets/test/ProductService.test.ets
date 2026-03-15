/**
 * 商品服务测试
 *
 * 测试商品 CRUD、库存管理、状态更新等功能
 * 使用主代码的 Product 实体和 ProductService 服务
 */
import { hilog } from '@kit.PerformanceAnalysisKit'
import { describe, it, expect, beforeAll, afterAll, beforeEach } from '@ohos/hypium'
import { common } from '@kit.AbilityKit'
import { Product, ProductStatus } from 'entry/ets/demo/entity/Product'
import { ProductService, ProductQueryParams } from 'entry/ets/demo/service/ProductService'
import { DatabaseManager } from 'entry/ets/demo/service/DatabaseManager'
import { TestDataFactory } from './support/TestDataFactory'
import { obtainTestContext } from './support/TestContext'
import { clearAllTablesForMainDb, createAllTablesForMainDb } from './support/EntryTestSupport'

export default function productServiceTest(): void {
  describe('ProductServiceTest', () => {
    let context: common.Context | null = null
    let productService: ProductService | null = null

    beforeAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'ProductServiceTest beforeAll')
      
      // 重置主代码的 DatabaseManager 单例
      DatabaseManager.resetInstance()
      
      // 获取测试上下文
      context = await obtainTestContext()
      
      // 初始化主代码的 DatabaseManager
      await DatabaseManager.getInstance().initialize(requireContext(context))
      
      // 创建所有表
      await createAllTablesForMainDb(requireContext(context))
      
      // 创建商品服务实例
      productService = new ProductService()
    })

    afterAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'ProductServiceTest afterAll')
      
      // 清理资源
      DatabaseManager.resetInstance()
    })

    beforeEach(async () => {
      // 清空所有表数据
      await clearAllTablesForMainDb(requireContext(context))
    })

    // ==================== CRUD 测试 ====================

    it('should_create_product_successfully', 0, async () => {
      const product = TestDataFactory.createProduct()
      
      const id = await requireProductService(productService).create(product)
      
      expect(id).assertLarger(0)
    })

    it('should_create_batch_products_successfully', 0, async () => {
      const products: Array<Product> = []
      const timestamp = Date.now().toString()
      
      for (let i = 0; i < 3; i++) {
        const product = TestDataFactory.createProduct()
        product.productCode = 'BATCH_' + timestamp + '_' + i.toString()
        products.push(product)
      }

      const ids = await requireProductService(productService).createBatch(products)
      
      expect(ids.length).assertEqual(3)
      for (const id of ids) {
        expect(id).assertLarger(0)
      }
    })

    it('should_get_product_by_id', 0, async () => {
      const product = TestDataFactory.createProduct()
      
      const id = await requireProductService(productService).create(product)
      const found = await requireProductService(productService).getById(id)
      
      expect(found !== null).assertTrue()
      if (found !== null) {
        expect(found.id).assertEqual(id)
        expect(found.productCode).assertEqual(product.productCode)
      }
    })

    it('should_update_product', 0, async () => {
      const product = TestDataFactory.createProduct()
      
      const id = await requireProductService(productService).create(product)

      // 更新商品
      const updates = new Product()
      updates.name = 'Updated Product Name'
      const affected = await requireProductService(productService).update(id, updates)

      expect(affected).assertTrue()

      const updated = await requireProductService(productService).getById(id)
      expect(updated !== null).assertTrue()
      if (updated !== null) {
        expect(updated.name).assertEqual('Updated Product Name')
      }
    })

    it('should_delete_product_logically', 0, async () => {
      const product = TestDataFactory.createProduct()
      
      const id = await requireProductService(productService).create(product)
      
      const affected = await requireProductService(productService).delete(id)
      
      expect(affected).assertTrue()
      
      // 逻辑删除后应该查不到
      const found = await requireProductService(productService).getById(id)
      expect(found).assertNull()
    })

    // ==================== 库存管理测试 ====================

    it('should_decrease_stock', 0, async () => {
      const product = TestDataFactory.createProduct()
      product.stock = 100
      
      const id = await requireProductService(productService).create(product)
      
      const affected = await requireProductService(productService).decreaseStock(id, 10)
      
      expect(affected).assertTrue()
      
      const updated = await requireProductService(productService).getById(id)
      expect(updated !== null).assertTrue()
      if (updated !== null) {
        expect(updated.stock).assertEqual(90)
      }
    })

    it('should_increase_stock', 0, async () => {
      const product = TestDataFactory.createProduct()
      product.stock = 50
      
      const id = await requireProductService(productService).create(product)
      
      const affected = await requireProductService(productService).increaseStock(id, 20)
      
      expect(affected).assertTrue()
      
      const updated = await requireProductService(productService).getById(id)
      expect(updated !== null).assertTrue()
      if (updated !== null) {
        expect(updated.stock).assertEqual(70)
      }
    })

    it('should_auto_sold_out_when_stock_zero', 0, async () => {
      const product = TestDataFactory.createProduct()
      product.stock = 10
      product.status = ProductStatus.ON_SHELF
      
      const id = await requireProductService(productService).create(product)
      
      // 扣减库存到 0
      const affected = await requireProductService(productService).decreaseStock(id, 10)
      
      expect(affected).assertTrue()
      
      const updated = await requireProductService(productService).getById(id)
      expect(updated !== null).assertTrue()
      if (updated !== null) {
        expect(updated.stock).assertEqual(0)
        expect(updated.status).assertEqual(ProductStatus.SOLD_OUT)
      }
    })

    it('should_throw_error_when_insufficient_stock', 0, async () => {
      const product = TestDataFactory.createProduct()
      product.stock = 5
      
      const id = await requireProductService(productService).create(product)
      
      let errorThrown = false
      try {
        await requireProductService(productService).decreaseStock(id, 10)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('Insufficient stock')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    it('should_throw_error_when_update_stock_for_nonexistent', 0, async () => {
      let errorThrown = false
      try {
        await requireProductService(productService).decreaseStock(99999, 1)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('Product not found')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    // ==================== 状态和唯一性测试 ====================

    it('should_update_product_status', 0, async () => {
      const product = TestDataFactory.createProduct()
      product.status = ProductStatus.OFF_SHELF
      
      const id = await requireProductService(productService).create(product)
      
      const affected = await requireProductService(productService).updateStatus(id, ProductStatus.ON_SHELF)
      
      expect(affected).assertTrue()
      
      const updated = await requireProductService(productService).getById(id)
      expect(updated !== null).assertTrue()
      if (updated !== null) {
        expect(updated.status).assertEqual(ProductStatus.ON_SHELF)
      }
    })

    it('should_update_product_status_with_invalid_value', 0, async () => {
      const product = TestDataFactory.createProduct()
      
      const id = await requireProductService(productService).create(product)
      
      let errorThrown = false
      try {
        await requireProductService(productService).updateStatus(id, 999)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('Invalid product status')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    it('should_get_product_by_code', 0, async () => {
      const product = TestDataFactory.createProduct()
      product.productCode = 'UNIQUE_CODE_001'
      
      await requireProductService(productService).create(product)
      
      const found = await requireProductService(productService).getByProductCode('UNIQUE_CODE_001')
      
      expect(found !== null).assertTrue()
      if (found !== null) {
        expect(found.productCode).assertEqual('UNIQUE_CODE_001')
      }
    })

    it('should_check_product_code_exists', 0, async () => {
      const product = TestDataFactory.createProduct()
      product.productCode = 'EXISTS_CHECK_001'
      
      await requireProductService(productService).create(product)
      
      const exists = await requireProductService(productService).existsByProductCode('EXISTS_CHECK_001')
      const notExists = await requireProductService(productService).existsByProductCode('NOT_EXISTS_CODE')
      
      expect(exists).assertTrue()
      expect(notExists).assertFalse()
    })

    it('should_page_products_with_price_range', 0, async () => {
      // 创建不同价格的商品
      const product1 = TestDataFactory.createProduct()
      product1.price = 50.0
      await requireProductService(productService).create(product1)
      
      const product2 = TestDataFactory.createProduct()
      product2.price = 100.0
      await requireProductService(productService).create(product2)
      
      const product3 = TestDataFactory.createProduct()
      product3.price = 150.0
      await requireProductService(productService).create(product3)

      const params = new ProductQueryParams()
      params.minPrice = 75.0
      params.maxPrice = 125.0
      params.current = 1
      params.size = 20
      
      const page = await requireProductService(productService).page(params)
      
      expect(page.records.length).assertEqual(1)
      expect(page.records[0].price).assertEqual(100.0)
    })
  })
}

function requireContext(context: common.Context | null): common.Context {
  if (context === null) {
    throw new Error('test context is not ready')
  }
  return context
}

function requireProductService(service: ProductService | null): ProductService {
  if (service === null) {
    throw new Error('product service is not ready')
  }
  return service
}
