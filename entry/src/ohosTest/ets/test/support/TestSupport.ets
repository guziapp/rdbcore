import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import {
  DatabaseManager,
  getDatabaseManager,
  DEMO_DB_NAME
} from '../../../../main/ets/demo/service/DatabaseManager'

// 导入实体类以触发装饰器注册
import '../../../../main/ets/demo/entity/User'
import '../../../../main/ets/demo/entity/Product'
import '../../../../main/ets/demo/entity/Order'
import '../../../../main/ets/demo/entity/OrderItem'

export async function setupDatabase(context: common.Context): Promise<DatabaseManager> {
  // 删除旧的数据库文件,确保干净的测试环境
  try {
    await relationalStore.deleteRdbStore(context, DEMO_DB_NAME)
  } catch (_) {
    // 忽略删除失败(文件可能不存在)
  }

  DatabaseManager.resetInstance()
  const dbManager: DatabaseManager = getDatabaseManager()
  await dbManager.initialize(context)
  return dbManager
}

export async function teardownDatabase(dbManager: DatabaseManager | null): Promise<void> {
  if (dbManager !== null) {
    await dbManager.close()
  }
  DatabaseManager.resetInstance()
}
