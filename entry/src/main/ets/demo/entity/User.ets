/**
 * 用户实体
 * 
 * 演示最简实体定义，包含：
 * - 自增主键
 * - 基础字段（带索引）
 * - 逻辑删除
 * - 审计字段
 */
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbIdStrategy,
  pageConfig
} from 'rdbcore'

export const USER_ENTITY_NAME: string = 'User'
export const USER_TABLE_NAME: string = 'user'
export const USER_PAGE_SIZE: number = 20
export const USER_MAX_PAGE_SIZE: number = 100

@RdbEntity({
  entityName: USER_ENTITY_NAME,
  tableName: USER_TABLE_NAME,
  page: pageConfig(USER_PAGE_SIZE, USER_MAX_PAGE_SIZE),
  nowProvider: (): number => Date.now()
})
export class User {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  username: string = ''

  @RdbColumn()
  nickname: string = ''

  @RdbColumn()
  status: number = 0

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}

/**
 * 用户状态枚举
 */
export class UserStatus {
  static readonly INACTIVE: number = 0
  static readonly ACTIVE: number = 1
  static readonly BANNED: number = 2

  static is_valid(status: number): boolean {
    return status === UserStatus.INACTIVE || status === UserStatus.ACTIVE || status === UserStatus.BANNED
  }

  static label(status: number): string {
    if (status === UserStatus.INACTIVE) {
      return '未激活'
    }
    if (status === UserStatus.ACTIVE) {
      return '已激活'
    }
    if (status === UserStatus.BANNED) {
      return '已禁用'
    }
    return '未知'
  }
}
