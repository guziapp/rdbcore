/**
 * 用户服务测试
 *
 * 测试用户 CRUD、分页、状态更新等功能
 * 使用主代码的 User 实体和 UserService 服务
 */
import { hilog } from '@kit.PerformanceAnalysisKit'
import { describe, it, expect, beforeAll, afterAll, beforeEach } from '@ohos/hypium'
import { common } from '@kit.AbilityKit'
import { User, UserStatus } from 'entry/ets/demo/entity/User'
import { UserService, UserQueryParams } from 'entry/ets/demo/service/UserService'
import { DatabaseManager } from 'entry/ets/demo/service/DatabaseManager'
import { TestDataFactory } from './support/TestDataFactory'
import { obtainTestContext } from './support/TestContext'
import { clearAllTablesForMainDb, createAllTablesForMainDb } from './support/EntryTestSupport'

export default function userServiceTest(): void {
  describe('UserServiceTest', () => {
    let context: common.Context | null = null
    let userService: UserService | null = null

    beforeAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'UserServiceTest beforeAll')
      
      // 重置主代码的 DatabaseManager 单例
      DatabaseManager.resetInstance()
      
      // 获取测试上下文
      context = await obtainTestContext()
      
      // 初始化主代码的 DatabaseManager
      await DatabaseManager.getInstance().initialize(requireContext(context))
      
      // 创建所有表
      await createAllTablesForMainDb(requireContext(context))
      
      // 创建用户服务实例
      userService = new UserService()
    })

    afterAll(async () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'UserServiceTest afterAll')
      
      // 清理资源
      DatabaseManager.resetInstance()
    })

    beforeEach(async () => {
      // 清空所有表数据
      await clearAllTablesForMainDb(requireContext(context))
    })

    // ==================== CRUD 测试 ====================

    it('should_create_user_successfully', 0, async () => {
      const user = TestDataFactory.createUser()
      
      const id = await requireUserService(userService).create(user)
      
      expect(id).assertLarger(0)
    })

    it('should_create_batch_users_successfully', 0, async () => {
      const users: Array<User> = []
      const timestamp = Date.now().toString()
      
      for (let i = 0; i < 3; i++) {
        const user = TestDataFactory.createUser()
        user.username = 'batch_user_' + timestamp + '_' + i.toString()
        user.nickname = 'Batch User ' + i.toString()
        users.push(user)
      }

      const ids = await requireUserService(userService).createBatch(users)
      
      expect(ids.length).assertEqual(3)
      for (const id of ids) {
        expect(id).assertLarger(0)
      }
    })

    it('should_get_user_by_id', 0, async () => {
      const user = TestDataFactory.createUser()
      
      const id = await requireUserService(userService).create(user)
      const found = await requireUserService(userService).getById(id)
      
      expect(found !== null).assertTrue()
      if (found !== null) {
        expect(found.id).assertEqual(id)
        expect(found.username).assertEqual(user.username)
      }
    })

    it('should_update_user', 0, async () => {
      const user = TestDataFactory.createUser()
      
      const id = await requireUserService(userService).create(user)

      // 更新用户
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

    it('should_delete_user_logically', 0, async () => {
      const user = TestDataFactory.createUser()
      
      const id = await requireUserService(userService).create(user)
      
      const affected = await requireUserService(userService).delete(id)
      
      expect(affected).assertTrue()
      
      // 逻辑删除后应该查不到
      const found = await requireUserService(userService).getById(id)
      expect(found).assertNull()
    })

    it('should_delete_users_by_ids', 0, async () => {
      const ids: Array<number> = []
      const timestamp = Date.now().toString()
      
      for (let i = 0; i < 3; i++) {
        const user = TestDataFactory.createUser()
        user.username = 'delete_ids_' + timestamp + '_' + i.toString()
        const id = await requireUserService(userService).create(user)
        ids.push(id)
      }

      const affected = await requireUserService(userService).deleteByIds(ids)
      
      expect(affected).assertEqual(3)
    })

    it('should_restore_user', 0, async () => {
      const user = TestDataFactory.createUser()
      
      const id = await requireUserService(userService).create(user)
      await requireUserService(userService).delete(id)
      
      const affected = await requireUserService(userService).restore(id)
      
      expect(affected).assertTrue()
      
      const restored = await requireUserService(userService).getById(id)
      expect(restored !== null).assertTrue()
    })

    it('should_hard_delete_user', 0, async () => {
      const user = TestDataFactory.createUser()
      
      const id = await requireUserService(userService).create(user)
      
      const affected = await requireUserService(userService).hardDelete(id)
      
      expect(affected).assertTrue()
    })

    // ==================== 状态管理测试 ====================

    it('should_update_user_status', 0, async () => {
      const user = TestDataFactory.createUser()
      user.status = UserStatus.INACTIVE
      
      const id = await requireUserService(userService).create(user)
      
      const affected = await requireUserService(userService).updateStatus(id, UserStatus.ACTIVE)
      
      expect(affected).assertTrue()
      
      const updated = await requireUserService(userService).getById(id)
      expect(updated !== null).assertTrue()
      if (updated !== null) {
        expect(updated.status).assertEqual(UserStatus.ACTIVE)
      }
    })

    it('should_update_user_status_with_invalid_value', 0, async () => {
      const user = TestDataFactory.createUser()
      
      const id = await requireUserService(userService).create(user)
      
      let errorThrown = false
      try {
        await requireUserService(userService).updateStatus(id, 999)
      } catch (e) {
        const error = e as Error
        expect(error.message.includes('Invalid user status')).assertTrue()
        errorThrown = true
      }
      
      expect(errorThrown).assertTrue()
    })

    // ==================== 查询测试 ====================

    it('should_page_users', 0, async () => {
      // 创建测试数据
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
      expect(page.current).assertEqual(1)
      expect(page.size).assertEqual(3)
    })

    it('should_page_users_with_keyword', 0, async () => {
      // 创建测试数据
      const user1 = TestDataFactory.createUser()
      user1.username = 'alice_test'
      await requireUserService(userService).create(user1)
      
      const user2 = TestDataFactory.createUser()
      user2.username = 'bob_test'
      await requireUserService(userService).create(user2)
      
      const user3 = TestDataFactory.createUser()
      user3.username = 'charlie_test'
      await requireUserService(userService).create(user3)

      const params = new UserQueryParams()
      params.keyword = 'alice'
      params.current = 1
      params.size = 20
      
      const page = await requireUserService(userService).page(params)
      
      expect(page.records.length).assertEqual(1)
      expect(page.records[0].username).assertEqual('alice_test')
    })

    it('should_page_users_with_status', 0, async () => {
      // 创建测试数据
      const user1 = TestDataFactory.createUser()
      user1.status = UserStatus.ACTIVE
      await requireUserService(userService).create(user1)
      
      const user2 = TestDataFactory.createUser()
      user2.status = UserStatus.INACTIVE
      await requireUserService(userService).create(user2)

      const params = new UserQueryParams()
      params.status = UserStatus.ACTIVE
      params.current = 1
      params.size = 20
      
      const page = await requireUserService(userService).page(params)
      
      expect(page.records.length).assertEqual(1)
      expect(page.records[0].status).assertEqual(UserStatus.ACTIVE)
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

    it('should_count_users', 0, async () => {
      for (let i = 0; i < 2; i++) {
        const user = TestDataFactory.createUser()
        await requireUserService(userService).create(user)
      }

      const params = new UserQueryParams()
      const count = await requireUserService(userService).count(params)
      
      expect(count).assertLarger(0)
    })

    it('should_get_user_by_username', 0, async () => {
      const user = TestDataFactory.createUser()
      user.username = 'unique_username_test'
      
      await requireUserService(userService).create(user)
      
      const found = await requireUserService(userService).getByUsername('unique_username_test')
      
      expect(found !== null).assertTrue()
      if (found !== null) {
        expect(found.username).assertEqual('unique_username_test')
      }
    })

    it('should_check_username_exists', 0, async () => {
      const user = TestDataFactory.createUser()
      user.username = 'exists_check_test'
      
      await requireUserService(userService).create(user)
      
      const exists = await requireUserService(userService).existsByUsername('exists_check_test')
      const notExists = await requireUserService(userService).existsByUsername('not_exists_username')
      
      expect(exists).assertTrue()
      expect(notExists).assertFalse()
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
