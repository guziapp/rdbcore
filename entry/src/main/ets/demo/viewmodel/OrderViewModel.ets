/**
 * 订单视图模型
 * 
 * 管理订单页面的状态和业务逻辑
 */
import { Order, OrderItem, OrderStatus } from '../entity'
import { OrderService, OrderQueryParams, CreateOrderInput, OrderItemInput } from '../service'

/**
 * 订单明细视图项
 */
export class OrderItemView {
  productId: number = 0
  productName: string = ''
  price: number = 0
  quantity: number = 0
  subtotal: number = 0
}

/**
 * 订单视图项
 */
export class OrderView {
  id: number = 0
  orderNo: string = ''
  userId: number = 0
  totalAmount: number = 0
  status: number = 0
  statusLabel: string = ''
  remark: string = ''
  createdAt: number = 0
  createdAtLabel: string = ''
  items: Array<OrderItemView> = []
}

/**
 * 订单列表视图状态
 */
export class OrderListViewState {
  initialized: boolean = false
  loading: boolean = false
  orderNo: string = ''
  userId: number | null = null
  statusFilter: number | null = null
  current: number = 1
  size: number = 20
  total: number = 0
  pages: number = 0
  items: Array<OrderView> = []
  errorMessage: string = ''
}

/**
 * 订单详情视图状态
 */
export class OrderDetailViewState {
  loading: boolean = false
  order: OrderView | null = null
  errorMessage: string = ''
}

/**
 * 订单视图模型
 */
export class OrderViewModel {
  private listState: OrderListViewState = new OrderListViewState()
  private detailState: OrderDetailViewState = new OrderDetailViewState()
  private service: OrderService = new OrderService()
  private listStateCallback: ((state: OrderListViewState) => void) | null = null
  private detailStateCallback: ((state: OrderDetailViewState) => void) | null = null

  /**
   * 设置列表状态变化回调
   */
  setListStateCallback(callback: (state: OrderListViewState) => void): void {
    this.listStateCallback = callback
  }

  /**
   * 设置详情状态变化回调
   */
  setDetailStateCallback(callback: (state: OrderDetailViewState) => void): void {
    this.detailStateCallback = callback
  }

  /**
   * 获取列表状态
   */
  getListState(): OrderListViewState {
    return this.listState
  }

  /**
   * 获取详情状态
   */
  getDetailState(): OrderDetailViewState {
    return this.detailState
  }

  /**
   * 初始化列表
   */
  async initializeList(): Promise<void> {
    this.updateListState({ loading: true, errorMessage: '' })
    
    try {
      await this.loadListPage(1)
      this.updateListState({ initialized: true, loading: false })
    } catch (error) {
      this.updateListState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
    }
  }

  /**
   * 刷新列表
   */
  async refreshList(): Promise<void> {
    this.updateListState({ loading: true, errorMessage: '' })
    
    try {
      await this.loadListPage(this.listState.current)
      this.updateListState({ loading: false })
    } catch (error) {
      this.updateListState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
    }
  }

  /**
   * 搜索订单
   */
  async searchByOrderNo(orderNo: string): Promise<void> {
    this.updateListState({ orderNo: orderNo, current: 1 })
    await this.refreshList()
  }

  /**
   * 筛选用户订单
   */
  async filterByUser(userId: number | null): Promise<void> {
    this.updateListState({ userId: userId, current: 1 })
    await this.refreshList()
  }

  /**
   * 筛选订单状态
   */
  async filterByStatus(status: number | null): Promise<void> {
    this.updateListState({ statusFilter: status, current: 1 })
    await this.refreshList()
  }

  /**
   * 翻页
   */
  async goToPage(page: number): Promise<void> {
    this.updateListState({ current: page })
    await this.refreshList()
  }

  /**
   * 加载订单详情
   */
  async loadOrderDetail(id: number): Promise<void> {
    this.updateDetailState({ loading: true, errorMessage: '' })
    
    try {
      const order = await this.service.getById(id)
      if (order === null) {
        throw new Error('订单不存在')
      }

      const items = await this.service.getOrderItems(id)
      const orderView = this.convertToOrderView(order, items)
      
      this.updateDetailState({ 
        loading: false, 
        order: orderView 
      })
    } catch (error) {
      this.updateDetailState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
    }
  }

  /**
   * 创建订单
   */
  async createOrder(userId: number, items: Array<OrderItemInput>, remark: string): Promise<string> {
    this.updateListState({ loading: true, errorMessage: '' })
    
    try {
      const input = new CreateOrderInput()
      input.userId = userId
      input.items = items
      input.remark = remark

      const result = await this.service.create(input)
      await this.refreshList()
      
      return result.orderNo
    } catch (error) {
      this.updateListState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 支付订单
   */
  async payOrder(id: number): Promise<void> {
    this.updateDetailState({ loading: true, errorMessage: '' })
    
    try {
      await this.service.pay(id)
      await this.loadOrderDetail(id)
    } catch (error) {
      this.updateDetailState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 发货
   */
  async shipOrder(id: number): Promise<void> {
    this.updateDetailState({ loading: true, errorMessage: '' })
    
    try {
      await this.service.ship(id)
      await this.loadOrderDetail(id)
    } catch (error) {
      this.updateDetailState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 完成订单
   */
  async completeOrder(id: number): Promise<void> {
    this.updateDetailState({ loading: true, errorMessage: '' })
    
    try {
      await this.service.complete(id)
      await this.loadOrderDetail(id)
    } catch (error) {
      this.updateDetailState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 取消订单
   */
  async cancelOrder(id: number): Promise<void> {
    this.updateDetailState({ loading: true, errorMessage: '' })
    
    try {
      await this.service.cancel(id)
      await this.loadOrderDetail(id)
    } catch (error) {
      this.updateDetailState({ 
        loading: false, 
        errorMessage: (error as Error).message 
      })
      throw new Error((error as Error).message)
    }
  }

  /**
   * 清除错误
   */
  clearListError(): void {
    this.updateListState({ errorMessage: '' })
  }

  clearDetailError(): void {
    this.updateDetailState({ errorMessage: '' })
  }

  /**
   * 加载分页数据
   */
  private async loadListPage(page: number): Promise<void> {
    const params = new OrderQueryParams()
    params.orderNo = this.listState.orderNo
    params.userId = this.listState.userId
    params.status = this.listState.statusFilter
    params.current = page
    params.size = this.listState.size

    const pageResult = await this.service.page(params)
    const items = this.convertToOrderViews(pageResult.records)

    this.updateListState({
      current: pageResult.current,
      total: pageResult.total,
      pages: pageResult.pages,
      items: items
    })
  }

  /**
   * 转换为订单视图列表
   */
  private convertToOrderViews(orders: Array<Order>): Array<OrderView> {
    const views: Array<OrderView> = []
    
    for (const order of orders) {
      views.push(this.convertToOrderView(order, []))
    }
    
    return views
  }

  /**
   * 转换为订单视图
   */
  private convertToOrderView(order: Order, items: Array<OrderItem>): OrderView {
    const view = new OrderView()
    view.id = order.id
    view.orderNo = order.orderNo
    view.userId = order.userId
    view.totalAmount = order.totalAmount
    view.status = order.status
    view.statusLabel = OrderStatus.label(order.status)
    view.remark = order.remark
    view.createdAt = order.createdAt
    view.createdAtLabel = this.formatDate(order.createdAt)
    
    const itemViews: Array<OrderItemView> = []
    for (const item of items) {
      const itemView = new OrderItemView()
      itemView.productId = item.productId
      itemView.productName = item.productName
      itemView.price = item.price
      itemView.quantity = item.quantity
      itemView.subtotal = item.subtotal
      itemViews.push(itemView)
    }
    view.items = itemViews
    
    return view
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
   * 更新列表状态
   */
  private updateListState(updates: Partial<OrderListViewState>): void {
    const newState = new OrderListViewState()
    newState.initialized = updates.initialized !== undefined ? updates.initialized : this.listState.initialized
    newState.loading = updates.loading !== undefined ? updates.loading : this.listState.loading
    newState.orderNo = updates.orderNo !== undefined ? updates.orderNo : this.listState.orderNo
    newState.userId = updates.userId !== undefined ? updates.userId : this.listState.userId
    newState.statusFilter = updates.statusFilter !== undefined ? updates.statusFilter : this.listState.statusFilter
    newState.current = updates.current !== undefined ? updates.current : this.listState.current
    newState.size = updates.size !== undefined ? updates.size : this.listState.size
    newState.total = updates.total !== undefined ? updates.total : this.listState.total
    newState.pages = updates.pages !== undefined ? updates.pages : this.listState.pages
    newState.items = updates.items !== undefined ? updates.items : this.listState.items
    newState.errorMessage = updates.errorMessage !== undefined ? updates.errorMessage : this.listState.errorMessage
    this.listState = newState
    if (this.listStateCallback !== null) {
      this.listStateCallback(this.listState)
    }
  }

  /**
   * 更新详情状态
   */
  private updateDetailState(updates: Partial<OrderDetailViewState>): void {
    const newState = new OrderDetailViewState()
    newState.loading = updates.loading !== undefined ? updates.loading : this.detailState.loading
    newState.order = updates.order !== undefined ? updates.order : this.detailState.order
    newState.errorMessage = updates.errorMessage !== undefined ? updates.errorMessage : this.detailState.errorMessage
    this.detailState = newState
    if (this.detailStateCallback !== null) {
      this.detailStateCallback(this.detailState)
    }
  }
}

/**
 * 创建订单视图模型
 */
export function createOrderViewModel(): OrderViewModel {
  return new OrderViewModel()
}
