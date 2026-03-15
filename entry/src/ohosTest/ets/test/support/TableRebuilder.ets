/**
 * 表结构重建工具类
 * 
 * 提供使用原生 SQL 重建表结构的功能，确保测试环境与主代码实体定义一致
 */
import { relationalStore } from '@kit.ArkData'

/**
 * 重建 user 表
 */
export async function rebuildUserTable(store: relationalStore.RdbStore): Promise<void> {
  const sql: string = `CREATE TABLE IF NOT EXISTS user (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    nickname TEXT NOT NULL,
    status INTEGER NOT NULL DEFAULT 0,
    deleted INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL DEFAULT 0
  )`
  await store.executeSql('DROP TABLE IF EXISTS user')
  await store.executeSql(sql)
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_user_username ON user(username)')
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_user_status ON user(status)')
}

/**
 * 重建 product 表
 */
export async function rebuildProductTable(store: relationalStore.RdbStore): Promise<void> {
  const sql: string = `CREATE TABLE IF NOT EXISTS product (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    product_code TEXT NOT NULL UNIQUE,
    price REAL NOT NULL DEFAULT 0.0,
    stock INTEGER NOT NULL DEFAULT 0,
    status INTEGER NOT NULL DEFAULT 1,
    deleted INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL DEFAULT 0
  )`
  await store.executeSql('DROP TABLE IF EXISTS product')
  await store.executeSql(sql)
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_product_name ON product(name)')
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_product_stock ON product(stock)')
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_product_status ON product(status)')
}

/**
 * 重建 order_info 表
 */
export async function rebuildOrderTable(store: relationalStore.RdbStore): Promise<void> {
  const sql: string = `CREATE TABLE IF NOT EXISTS order_info (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_no TEXT NOT NULL UNIQUE,
    user_id INTEGER NOT NULL,
    total_amount REAL NOT NULL DEFAULT 0.0,
    status INTEGER NOT NULL DEFAULT 0,
    remark TEXT,
    deleted INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL DEFAULT 0
  )`
  await store.executeSql('DROP TABLE IF EXISTS order_info')
  await store.executeSql(sql)
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_order_no ON order_info(order_no)')
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_order_user_id ON order_info(user_id)')
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_order_status ON order_info(status)')
}

/**
 * 重建 order_item 表
 */
export async function rebuildOrderItemTable(store: relationalStore.RdbStore): Promise<void> {
  const sql: string = `CREATE TABLE IF NOT EXISTS order_item (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    price REAL NOT NULL DEFAULT 0.0,
    quantity INTEGER NOT NULL DEFAULT 1,
    subtotal REAL NOT NULL DEFAULT 0.0,
    created_at INTEGER NOT NULL DEFAULT 0
  )`
  await store.executeSql('DROP TABLE IF EXISTS order_item')
  await store.executeSql(sql)
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_order_item_order_id ON order_item(order_id)')
  await store.executeSql('CREATE INDEX IF NOT EXISTS idx_order_item_product_id ON order_item(product_id)')
}

/**
 * 重建所有表
 */
export async function rebuildAllTables(store: relationalStore.RdbStore): Promise<void> {
  await rebuildUserTable(store)
  await rebuildProductTable(store)
  await rebuildOrderTable(store)
  await rebuildOrderItemTable(store)
}
