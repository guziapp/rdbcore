/**
 * 数据库管理器
 *
 * 统一管理数据库初始化、实体入口和事务
 */
import { common } from '@kit.AbilityKit'
import {
  RdbDatabase,
  RdbDatabaseOptions
} from 'rdbcore'
import {
  User,
  Product,
  Order,
  OrderItem,
  USER_ENTITY_NAME,
  PRODUCT_ENTITY_NAME,
  ORDER_ENTITY_NAME,
  ORDER_ITEM_ENTITY_NAME
} from '../entity'

// 导入实体类以触发装饰器注册
// 注意: 装饰器需要在类被导入时执行,才能注册实体元数据
import '../entity/User'
import '../entity/Product'
import '../entity/Order'
import '../entity/OrderItem'
import { relationalStore } from '@kit.ArkData'

export const DEMO_DB_NAME: string = 'demo.db'
export const DEMO_DB_VERSION: number = 1

/**
 * 数据库管理器
 * 
 * 单例模式，管理数据库生命周期
 */
export class DatabaseManager {
  private static instance: DatabaseManager | null = null
  private database: RdbDatabase | null = null
  private context: common.Context | null = null
  private initialized: boolean = false

  private constructor() {}

  static getInstance(): DatabaseManager {
    if (DatabaseManager.instance === null) {
      DatabaseManager.instance = new DatabaseManager()
    }
    return DatabaseManager.instance
  }

  /**
   * 初始化数据库
   */
  async initialize(context: common.Context): Promise<void> {
    // 幂等性检查：如果已初始化，直接返回
    if (this.initialized) {
      return
    }

    this.context = context

    // 创建数据库表
    await createAllTablesForDemoDb(context)

    const options: RdbDatabaseOptions = {
      name: DEMO_DB_NAME,
      context: this.context,
      tag: 'demo'
    }

    this.database = new RdbDatabase(options)
    await this.database.ensureInitialized()
    this.initialized = true
  }

  /**
   * 获取数据库实例
   */
  getDatabase(): RdbDatabase {
    if (this.database === null) {
      throw new Error('Database not initialized. Call initialize() first.')
    }
    return this.database
  }

  /**
   * 获取用户实体入口
   */
  getUserEntry() {
    return this.getDatabase().entity<User, number>(USER_ENTITY_NAME)
  }

  /**
   * 获取商品实体入口
   */
  getProductEntry() {
    return this.getDatabase().entity<Product, number>(PRODUCT_ENTITY_NAME)
  }

  /**
   * 获取订单实体入口
   */
  getOrderEntry() {
    return this.getDatabase().entity<Order, number>(ORDER_ENTITY_NAME)
  }

  /**
   * 获取订单明细实体入口
   */
  getOrderItemEntry() {
    return this.getDatabase().entity<OrderItem, number>(ORDER_ITEM_ENTITY_NAME)
  }

  /**
   * 执行事务
   */
  async tx<T>(task: () => Promise<T>): Promise<T> {
    return this.getDatabase().tx<T>(async (_scope): Promise<T> => {
      return await task()
    })
  }

  /**
   * 关闭数据库
   */
  async close(): Promise<void> {
    if (this.database !== null) {
      // RdbDatabase 没有显式的 close 方法，置空引用
      this.database = null
    }
    this.context = null
    this.initialized = false
  }

  /**
   * 重置实例（用于测试）
   */
  static resetInstance(): void {
    DatabaseManager.instance = null
  }

  /**
   * 检查是否已初始化
   */
  isInitialized(): boolean {
    return this.initialized
  }
}

/**
 * 获取数据库管理器实例
 */
export function getDatabaseManager(): DatabaseManager {
  return DatabaseManager.getInstance()
}

/**
 * 创建所有表 (使用主数据库)
 */
export async function createAllTablesForDemoDb(context: common.Context): Promise<void> {
  const store = await openDemoStore(context)
  // 创建用户表
  await store.executeSql(
    'CREATE TABLE IF NOT EXISTS user (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'username TEXT NOT NULL, ' +
      'nickname TEXT NOT NULL, ' +
      'status INTEGER NOT NULL DEFAULT 0, ' +
      'deleted INTEGER NOT NULL DEFAULT 0, ' +
      'created_at INTEGER NOT NULL, ' +
      'updated_at INTEGER NOT NULL)'
  )
  // 创建商品表
  await store.executeSql(
    'CREATE TABLE IF NOT EXISTS product (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'name TEXT NOT NULL, ' +
      'product_code TEXT NOT NULL UNIQUE, ' +
      'price REAL NOT NULL, ' +
      'stock INTEGER NOT NULL, ' +
      'status INTEGER NOT NULL DEFAULT 1, ' +
      'deleted INTEGER NOT NULL DEFAULT 0, ' +
      'created_at INTEGER NOT NULL, ' +
      'updated_at INTEGER NOT NULL)'
  )
  // 创建订单表
  await store.executeSql(
    'CREATE TABLE IF NOT EXISTS order_info (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'order_no TEXT NOT NULL UNIQUE, ' +
      'user_id INTEGER NOT NULL, ' +
      'total_amount REAL NOT NULL, ' +
      'status INTEGER NOT NULL DEFAULT 0, ' +
      'remark TEXT, ' +
      'deleted INTEGER NOT NULL DEFAULT 0, ' +
      'created_at INTEGER NOT NULL, ' +
      'updated_at INTEGER NOT NULL)'
  )
  // 创建订单明细表
  await store.executeSql(
    'CREATE TABLE IF NOT EXISTS order_item (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'order_id INTEGER NOT NULL, ' +
      'product_id INTEGER NOT NULL, ' +
      'product_name TEXT NOT NULL, ' +
      'price REAL NOT NULL, ' +
      'quantity INTEGER NOT NULL, ' +
      'subtotal REAL NOT NULL, ' +
      'created_at INTEGER NOT NULL)'
  )
}

// ============ Store Helper ============
async function openDemoStore(context: common.Context): Promise<relationalStore.RdbStore> {
  try {
    return await relationalStore.getRdbStore(context, {
      name: DEMO_DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    })
  } catch (_) {
    throw new Error('failed to open demo store')
  }
}