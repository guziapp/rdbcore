/**
 * 用户服务
 * 
 * 封装用户相关的业务逻辑
 */
import {
  EntityEntry,
  QueryWrapper,
  RdbPage,
  RdbPageRequest,
  UpdateWrapper
} from 'rdbcore'
import { User, UserStatus } from '../entity'
import { getDatabaseManager } from './DatabaseManager'

/**
 * 用户查询参数
 */
export class UserQueryParams {
  keyword: string = ''
  status: number | null = null
  current: number = 1
  size: number = 20
}

/**
 * 用户服务
 */
export class UserService {
  /**
   * 创建用户
   */
  async create(user: User): Promise<number> {
    const entry = this.getEntry()
    return await entry.service().insert(user)
  }

  /**
   * 批量创建用户
   */
  async createBatch(users: Array<User>): Promise<Array<number>> {
    const entry = this.getEntry()
    return await entry.service().insertBatch(users)
  }

  /**
   * 根据ID获取用户
   */
  async getById(id: number): Promise<User | null> {
    const entry = this.getEntry()
    return await entry.service().getById(id)
  }

  /**
   * 根据用户名获取用户
   */
  async getByUsername(username: string): Promise<User | null> {
    const entry = this.getEntry()
    const query = entry.query()
      .eq('deleted', 0)
      .eq('username', username)
    return await entry.service().getOne(query)
  }

  /**
   * 检查用户名是否存在
   */
  async existsByUsername(username: string): Promise<boolean> {
    const user = await this.getByUsername(username)
    return user !== null
  }

  /**
   * 分页查询用户
   */
  async page(params: UserQueryParams): Promise<RdbPage<User>> {
    const entry = this.getEntry()
    const query = this.buildQuery(params)
      .orderByDesc('createdAt')
      .page(params.current, params.size)
    
    const request: RdbPageRequest = {
      current: params.current,
      size: params.size
    }
    
    return await entry.service().page(request, query)
  }

  /**
   * 列表查询用户
   */
  async list(params: UserQueryParams): Promise<Array<User>> {
    const entry = this.getEntry()
    const query = this.buildQuery(params)
      .orderByDesc('createdAt')
    
    return await entry.service().list(query)
  }

  /**
   * 统计用户数量
   */
  async count(params: UserQueryParams): Promise<number> {
    const entry = this.getEntry()
    const query = this.buildQuery(params)
    return await entry.service().count(query)
  }

  /**
   * 更新用户
   */
  async update(id: number, updates: Partial<User>): Promise<boolean> {
    const entry = this.getEntry()
    const patch = this.buildUpdate(updates)
    return await entry.service().patchById(id, patch)
  }

  /**
   * 更新用户状态
   */
  async updateStatus(id: number, status: number): Promise<boolean> {
    if (!UserStatus.is_valid(status)) {
      throw new Error('Invalid user status: ' + status.toString())
    }
    
    const entry = this.getEntry()
    const patch = entry.update()
      .set('status', status)
      .set('updatedAt', Date.now())
    
    return await entry.service().patchById(id, patch)
  }

  /**
   * 删除用户（逻辑删除）
   */
  async delete(id: number): Promise<boolean> {
    const entry = this.getEntry()
    return await entry.service().removeById(id)
  }

  /**
   * 批量删除用户
   */
  async deleteByIds(ids: Array<number>): Promise<number> {
    const entry = this.getEntry()
    return await entry.service().removeByIds(ids)
  }

  /**
   * 恢复用户
   */
  async restore(id: number): Promise<boolean> {
    const entry = this.getEntry()
    return await entry.service().restoreById(id)
  }

  /**
   * 物理删除用户
   */
  async hardDelete(id: number): Promise<boolean> {
    const entry = this.getEntry()
    return await entry.service().removeById(id, true)
  }

  /**
   * 获取实体入口
   */
  private getEntry(): EntityEntry<User, number> {
    return getDatabaseManager().getUserEntry()
  }

  /**
   * 构建查询条件
   */
  private buildQuery(params: UserQueryParams): QueryWrapper<User> {
    const entry = this.getEntry()
    const query = entry.query().eq('deleted', 0)

    // 关键字搜索
    query.likeIf(params.keyword !== '', 'username', `%${params.keyword}%`)

    // 状态筛选
    query.eqIf(params.status !== null, 'status', params.status ?? 0)

    return query
  }

  /**
   * 构建更新条件
   */
  private buildUpdate(updates: Partial<User>): UpdateWrapper<User> {
    const entry = this.getEntry()
    const patch = entry.update()

    if (updates.username !== undefined) {
      patch.set('username', updates.username)
    }
    if (updates.nickname !== undefined) {
      patch.set('nickname', updates.nickname)
    }
    if (updates.status !== undefined) {
      patch.set('status', updates.status)
    }

    patch.set('updatedAt', Date.now())

    return patch
  }
}

/**
 * 获取用户服务实例
 */
export function getUserService(): UserService {
  return new UserService()
}
