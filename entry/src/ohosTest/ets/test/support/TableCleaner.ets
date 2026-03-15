/**
 * 表数据清理工具类
 * 
 * 提供清空表数据的功能，确保测试间的数据隔离
 */
import { relationalStore } from '@kit.ArkData'

/**
 * 清空 user 表数据
 */
export async function clearUserTable(store: relationalStore.RdbStore): Promise<void> {
  await store.executeSql('DELETE FROM user')
}

/**
 * 清空 product 表数据
 */
export async function clearProductTable(store: relationalStore.RdbStore): Promise<void> {
  await store.executeSql('DELETE FROM product')
}

/**
 * 清空 order_info 表数据
 */
export async function clearOrderTable(store: relationalStore.RdbStore): Promise<void> {
  await store.executeSql('DELETE FROM order_info')
}

/**
 * 清空 order_item 表数据
 */
export async function clearOrderItemTable(store: relationalStore.RdbStore): Promise<void> {
  await store.executeSql('DELETE FROM order_item')
}

/**
 * 清空所有表数据
 * 
 * 清空顺序：order_item -> order_info -> product -> user
 * 确保外键约束不会导致删除失败
 */
export async function clearAllTables(store: relationalStore.RdbStore): Promise<void> {
  await clearOrderItemTable(store)
  await clearOrderTable(store)
  await clearProductTable(store)
  await clearUserTable(store)
}

/**
 * 清空订单相关表数据
 * 
 * 仅清空 order_info 和 order_item 表，保留用户和商品数据
 */
export async function clearOrderTables(store: relationalStore.RdbStore): Promise<void> {
  await clearOrderItemTable(store)
  await clearOrderTable(store)
}
