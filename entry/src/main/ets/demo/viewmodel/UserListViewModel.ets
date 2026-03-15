/**
 * 用户列表视图模型
 * 
 * 管理用户列表页面的状态和业务逻辑
 */
import { User, UserStatus } from '../entity'
import { UserService, UserQueryParams } from '../service'

/**
 * 用户列表项视图状态
 */
export class UserListItem {
  id: number = 0
  username: string = ''
  nickname: string = ''
  status: number = 0
  statusLabel: string = ''
  createdAt: number = 0
  createdAtLabel: string = ''
}

/**
 * 用户列表视图状态
 */
export class UserListViewState {
  initialized: boolean = false
  loading: boolean = false
  keyword: string = ''
  statusFilter: number | null = null
  current: number = 1
  size: number = 20
  total: number = 0
  pages: number = 0
  items: Array<UserListItem> = []
  errorMessage: string = ''
}

/**
 * 用户列表视图模型
 */
export class UserListViewModel {
  private state: UserListViewState = new UserListViewState()
  private service: UserService = new UserService()
  private stateChangeCallback: ((state: UserListViewState) => void) | null = null

  /**
   * 设置状态变化回调
   */
  setStateChangeCallback(callback: (state: UserListViewState) => void): void {
    this.stateChangeCallback = callback
  }

  /**
   * 获取当前状态
   */
  getState(): UserListViewState {
    return this.state
  }

  /**
   * 初始化
   */
  async initialize(): Promise<void> {
    this.updateState({ loading: true, errorMessage: '' })
    
    try {
      await this.loadPage(1)
      this.updateState({ initialized: true, loading: false })
    } catch (error) {
      this.updateState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
    }
  }

  /**
   * 刷新
   */
  async refresh(): Promise<void> {
    this.updateState({ loading: true, errorMessage: '' })
    
    try {
      await this.loadPage(this.state.current)
      this.updateState({ loading: false })
    } catch (error) {
      this.updateState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
    }
  }

  /**
   * 搜索
   */
  async search(keyword: string): Promise<void> {
    this.updateState({ keyword: keyword, current: 1 })
    await this.refresh()
  }

  /**
   * 筛选状态
   */
  async filterByStatus(status: number | null): Promise<void> {
    this.updateState({ statusFilter: status, current: 1 })
    await this.refresh()
  }

  /**
   * 翻页
   */
  async goToPage(page: number): Promise<void> {
    this.updateState({ current: page })
    await this.refresh()
  }

  /**
   * 上一页
   */
  async prevPage(): Promise<void> {
    if (this.state.current > 1) {
      await this.goToPage(this.state.current - 1)
    }
  }

  /**
   * 下一页
   */
  async nextPage(): Promise<void> {
    if (this.state.current < this.state.pages) {
      await this.goToPage(this.state.current + 1)
    }
  }

  /**
   * 创建用户
   */
  async createUser(username: string, nickname: string): Promise<number> {
    this.updateState({ loading: true, errorMessage: '' })
    
    try {
      // 检查用户名是否存在
      const exists = await this.service.existsByUsername(username)
      if (exists) {
        throw new Error('用户名已存在')
      }

      const user = new User()
      user.username = username
      user.nickname = nickname
      user.status = UserStatus.ACTIVE

      const id = await this.service.create(user)
      await this.refresh()
      
      return id
    } catch (error) {
      this.updateState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 更新用户状态
   */
  async updateUserStatus(id: number, status: number): Promise<void> {
    this.updateState({ loading: true, errorMessage: '' })
    
    try {
      await this.service.updateStatus(id, status)
      await this.refresh()
    } catch (error) {
      this.updateState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 删除用户
   */
  async deleteUser(id: number): Promise<void> {
    this.updateState({ loading: true, errorMessage: '' })
    
    try {
      await this.service.delete(id)
      await this.refresh()
    } catch (error) {
      this.updateState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 清除错误
   */
  clearError(): void {
    this.updateState({ errorMessage: '' })
  }

  /**
   * 加载分页数据
   */
  private async loadPage(page: number): Promise<void> {
    const params = new UserQueryParams()
    params.keyword = this.state.keyword
    params.status = this.state.statusFilter
    params.current = page
    params.size = this.state.size

    const pageResult = await this.service.page(params)
    const items = this.convertToItems(pageResult.records)

    this.updateState({
      current: pageResult.current,
      total: pageResult.total,
      pages: pageResult.pages,
      items: items
    })
  }

  /**
   * 转换为列表项
   */
  private convertToItems(users: Array<User>): Array<UserListItem> {
    const items: Array<UserListItem> = []
    
    for (const user of users) {
      const item = new UserListItem()
      item.id = user.id
      item.username = user.username
      item.nickname = user.nickname
      item.status = user.status
      item.statusLabel = UserStatus.label(user.status)
      item.createdAt = user.createdAt
      item.createdAtLabel = this.formatDate(user.createdAt)
      items.push(item)
    }
    
    return items
  }

  /**
   * 格式化日期
   */
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp)
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    return year.toString() + '-' + month + '-' + day + ' ' + hour + ':' + minute
  }

  /**
   * 更新状态
   */
  private updateState(updates: Partial<UserListViewState>): void {
    const newState = new UserListViewState()
    newState.initialized = updates.initialized !== undefined ? updates.initialized : this.state.initialized
    newState.loading = updates.loading !== undefined ? updates.loading : this.state.loading
    newState.keyword = updates.keyword !== undefined ? updates.keyword : this.state.keyword
    newState.statusFilter = updates.statusFilter !== undefined ? updates.statusFilter : this.state.statusFilter
    newState.current = updates.current !== undefined ? updates.current : this.state.current
    newState.size = updates.size !== undefined ? updates.size : this.state.size
    newState.total = updates.total !== undefined ? updates.total : this.state.total
    newState.pages = updates.pages !== undefined ? updates.pages : this.state.pages
    newState.items = updates.items !== undefined ? updates.items : this.state.items
    newState.errorMessage = updates.errorMessage !== undefined ? updates.errorMessage : this.state.errorMessage
    this.state = newState
    if (this.stateChangeCallback !== null) {
      this.stateChangeCallback(this.state)
    }
  }
}

/**
 * 创建用户列表视图模型
 */
export function createUserListViewModel(): UserListViewModel {
  return new UserListViewModel()
}
