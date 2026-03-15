/**
 * 测试支持工具
 * 
 * 提供测试数据库创建和表操作功能
 * 注意: 测试实体已移除,请使用主代码的实体类
 */
import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { RdbDatabase } from 'rdbcore'

export const DEMO_DB_NAME: string = 'entry-demo-test.db'
export const MAIN_DB_NAME: string = 'demo.db'

/**
 * 清空所有表数据 (使用主数据库)
 * 注意: 如果表不存在则忽略错误
 */
export async function clearAllTablesForMainDb(context: common.Context): Promise<void> {
  const store = await openMainStore(context)
  // 按依赖顺序删除，忽略表不存在的错误
  await safeDeleteFrom(store, 'order_item')
  await safeDeleteFrom(store, 'order_info')
  await safeDeleteFrom(store, 'product')
  await safeDeleteFrom(store, 'user')
}

/**
 * 安全删除表数据，忽略表不存在的错误
 */
async function safeDeleteFrom(store: relationalStore.RdbStore, tableName: string): Promise<void> {
  try {
    await store.executeSql('DELETE FROM ' + tableName)
  } catch (_) {
    // 表不存在时忽略错误
  }
}

/**
 * 创建所有表 (使用主数据库)
 */
export async function createAllTablesForMainDb(context: common.Context): Promise<void> {
  const store = await openMainStore(context)
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

/**
 * 清空订单相关表数据 (使用主数据库)
 * 注意: 如果表不存在则忽略错误
 */
export async function clearOrderTablesForMainDb(context: common.Context): Promise<void> {
  const store = await openMainStore(context)
  await safeDeleteFrom(store, 'order_item')
  await safeDeleteFrom(store, 'order_info')
}

/**
 * 打开主数据库 Store
 */
async function openMainStore(context: common.Context): Promise<relationalStore.RdbStore> {
  try {
    return await relationalStore.getRdbStore(context, {
      name: MAIN_DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    })
  } catch (_) {
    throw new Error('failed to open main store')
  }
}

// ============ Database Creation ============
export function createDemoDatabase(context: common.Context): RdbDatabase {
  return new RdbDatabase({
    name: DEMO_DB_NAME,
    context: context,
    securityLevel: relationalStore.SecurityLevel.S1,
    tag: 'entry-demo-test'
  })
}

// ============ Table Rebuild ============
export async function rebuildUserTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DROP TABLE IF EXISTS user')
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
  } catch (_) {
    throw new Error('failed to rebuild user table')
  }
}

export async function rebuildProductTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DROP TABLE IF EXISTS product')
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
  } catch (_) {
    throw new Error('failed to rebuild product table')
  }
}

export async function rebuildOrderTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DROP TABLE IF EXISTS order_info')
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
  } catch (_) {
    throw new Error('failed to rebuild order table')
  }
}

export async function rebuildOrderItemTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DROP TABLE IF EXISTS order_item')
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS order_item (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'order_id INTEGER NOT NULL, ' +
        'product_id INTEGER NOT NULL, ' +
        'product_name TEXT NOT NULL, ' +
        'price REAL NOT NULL, ' +
        'quantity INTEGER NOT NULL, ' +
        'subtotal REAL NOT NULL, ' +
        'deleted INTEGER NOT NULL DEFAULT 0, ' +
        'created_at INTEGER NOT NULL, ' +
        'updated_at INTEGER NOT NULL)'
    )
  } catch (_) {
    throw new Error('failed to rebuild order_item table')
  }
}

export async function rebuildAllTables(context: common.Context): Promise<void> {
  await rebuildUserTable(context)
  await rebuildProductTable(context)
  await rebuildOrderTable(context)
  await rebuildOrderItemTable(context)
}

// ============ Clear Tables ============
export async function clearUserTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DELETE FROM user')
  } catch (_) {
    throw new Error('failed to clear user table')
  }
}

export async function clearProductTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DELETE FROM product')
  } catch (_) {
    throw new Error('failed to clear product table')
  }
}

export async function clearOrderTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DELETE FROM order_info')
  } catch (_) {
    throw new Error('failed to clear order table')
  }
}

export async function clearOrderItemTable(context: common.Context): Promise<void> {
  try {
    const store = await openDemoStore(context)
    await store.executeSql('DELETE FROM order_item')
  } catch (_) {
    throw new Error('failed to clear order_item table')
  }
}

export async function clearAllTables(context: common.Context): Promise<void> {
  await clearOrderItemTable(context)
  await clearOrderTable(context)
  await clearProductTable(context)
  await clearUserTable(context)
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
