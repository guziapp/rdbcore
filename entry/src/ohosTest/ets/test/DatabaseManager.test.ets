/**
 * 数据库管理器测试
 *
 * 测试数据库初始化、实体入口获取等功能
 * 使用主代码的实体类
 */
import { hilog } from '@kit.PerformanceAnalysisKit'
import { describe, it, expect } from '@ohos/hypium'
import { RdbDatabase } from 'rdbcore'
import { User } from 'entry/ets/demo/entity/User'
import { Product } from 'entry/ets/demo/entity/Product'
import { Order } from 'entry/ets/demo/entity/Order'
import { OrderItem } from 'entry/ets/demo/entity/OrderItem'
import { obtainTestContext } from './support/TestContext'
import { createDemoDatabase, DEMO_DB_NAME } from './support/EntryTestSupport'

export default function databaseManagerTest(): void {
  describe('DatabaseManagerTest', () => {
    it('should_initialize_database_successfully', 0, async () => {
      const context = await obtainTestContext()
      const database = createDemoDatabase(context)
      await database.ensureInitialized()
      
      // 检查数据库是否可用(通过检查实体入口)
      const userEntry = database.entity<User, number>('User')
      expect(userEntry !== null).assertTrue()
    })

    it('should_get_user_entry_after_initialization', 0, async () => {
      const context = await obtainTestContext()
      const database = createDemoDatabase(context)
      await database.ensureInitialized()
      
      const userEntry = database.entity<User, number>('User')
      expect(userEntry !== null).assertTrue()
      expect(userEntry.service() !== null).assertTrue()
    })

    it('should_get_product_entry_after_initialization', 0, async () => {
      const context = await obtainTestContext()
      const database = createDemoDatabase(context)
      await database.ensureInitialized()
      
      const productEntry = database.entity<Product, number>('Product')
      expect(productEntry !== null).assertTrue()
      expect(productEntry.service() !== null).assertTrue()
    })

    it('should_get_order_entry_after_initialization', 0, async () => {
      const context = await obtainTestContext()
      const database = createDemoDatabase(context)
      await database.ensureInitialized()
      
      const orderEntry = database.entity<Order, number>('Order')
      expect(orderEntry !== null).assertTrue()
      expect(orderEntry.service() !== null).assertTrue()
    })

    it('should_get_order_item_entry_after_initialization', 0, async () => {
      const context = await obtainTestContext()
      const database = createDemoDatabase(context)
      await database.ensureInitialized()
      
      const orderItemEntry = database.entity<OrderItem, number>('OrderItem')
      expect(orderItemEntry !== null).assertTrue()
      expect(orderItemEntry.service() !== null).assertTrue()
    })

    it('should_execute_transaction_successfully', 0, async () => {
      const context = await obtainTestContext()
      const database = createDemoDatabase(context)
      await database.ensureInitialized()
      
      const result = await database.tx<number>(async (): Promise<number> => {
        return 42
      })
      expect(result).assertEqual(42)
    })
  })
}
