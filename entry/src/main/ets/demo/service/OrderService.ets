/**
 * 订单服务
 * 
 * 封装订单相关的业务逻辑，包括：
 * - 订单创建（事务）
 * - 订单状态流转
 * - 订单明细管理
 */
import {
  EntityEntry,
  QueryWrapper,
  RdbPage,
  RdbPageRequest
} from 'rdbcore'
import { Order, OrderItem, OrderStatus } from '../entity'
import { getDatabaseManager } from './DatabaseManager'
import { ProductService } from './ProductService'

/**
 * 订单查询参数
 */
export class OrderQueryParams {
  orderNo: string = ''
  userId: number | null = null
  status: number | null = null
  startDate: number | null = null
  endDate: number | null = null
  current: number = 1
  size: number = 20
}

/**
 * 创建订单输入
 */
export class CreateOrderInput {
  userId: number = 0
  items: Array<OrderItemInput> = []
  remark: string = ''
}

/**
 * 订单明细输入
 */
export class OrderItemInput {
  productId: number = 0
  quantity: number = 1
}

/**
 * 创建订单结果
 */
export class CreateOrderResult {
  orderId: number = 0
  orderNo: string = ''
  totalAmount: number = 0
}

/**
 * 订单项临时数据
 */
class OrderItemTemp {
  productId: number = 0
  productName: string = ''
  price: number = 0
  quantity: number = 0
  subtotal: number = 0
}

/**
 * 订单服务
 */
export class OrderService {
  private productService: ProductService = new ProductService()

  /**
   * 创建订单（事务）
   */
  async create(input: CreateOrderInput): Promise<CreateOrderResult> {
    // 验证商品并计算总价
    let totalAmount = 0
    const orderItems: Array<OrderItemTemp> = []

    for (const item of input.items) {
      const product = await this.productService.getById(item.productId)
      if (product === null || product.deleted === 1) {
        throw new Error('商品不存在或已删除: ' + item.productId.toString())
      }
      if (product.status !== 1) {
        throw new Error('商品未上架: ' + product.name)
      }
      if (product.stock < item.quantity) {
        throw new Error('商品库存不足: ' + product.name)
      }

      const subtotal = product.price * item.quantity
      totalAmount += subtotal
      const tempItem = new OrderItemTemp()
      tempItem.productId = product.id
      tempItem.productName = product.name
      tempItem.price = product.price
      tempItem.quantity = item.quantity
      tempItem.subtotal = subtotal
      orderItems.push(tempItem)
    }

    // 事务创建订单
    const result = await getDatabaseManager().tx<CreateOrderResult>(async (): Promise<CreateOrderResult> => {
      // 创建订单
      const order = new Order()
      order.orderNo = this.generateOrderNo()
      order.userId = input.userId
      order.totalAmount = totalAmount
      order.status = OrderStatus.PENDING_PAYMENT
      order.remark = input.remark

      const orderEntry = this.getOrderEntry()
      const orderId = await orderEntry.service().insert(order)

      // 创建订单明细
      const itemEntry = this.getOrderItemEntry()
      for (const item of orderItems) {
        const orderItem = new OrderItem()
        orderItem.orderId = orderId
        orderItem.productId = item.productId
        orderItem.productName = item.productName
        orderItem.price = item.price
        orderItem.quantity = item.quantity
        orderItem.subtotal = item.subtotal

        await itemEntry.service().insert(orderItem)
      }

      // 扣减库存
      for (const item of orderItems) {
        await this.productService.decreaseStock(item.productId, item.quantity)
      }

      const createResult = new CreateOrderResult()
      createResult.orderId = orderId
      createResult.orderNo = order.orderNo
      createResult.totalAmount = totalAmount
      
      return createResult
    })

    return result
  }

  /**
   * 根据ID获取订单
   */
  async getById(id: number): Promise<Order | null> {
    const entry = this.getOrderEntry()
    return await entry.service().getById(id)
  }

  /**
   * 根据订单号获取订单
   */
  async getByOrderNo(orderNo: string): Promise<Order | null> {
    const entry = this.getOrderEntry()
    const query = entry.query()
      .eq('deleted', 0)
      .eq('orderNo', orderNo)
    return await entry.service().getOne(query)
  }

  /**
   * 分页查询订单
   */
  async page(params: OrderQueryParams): Promise<RdbPage<Order>> {
    const entry = this.getOrderEntry()
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
   * 列表查询订单
   */
  async list(params: OrderQueryParams): Promise<Array<Order>> {
    const entry = this.getOrderEntry()
    const query = this.buildQuery(params)
      .orderByDesc('createdAt')
    
    return await entry.service().list(query)
  }

  /**
   * 获取订单明细
   */
  async getOrderItems(orderId: number): Promise<Array<OrderItem>> {
    const entry = this.getOrderItemEntry()
    const query = entry.query()
      .eq('orderId', orderId)
      .orderByAsc('id')
    
    return await entry.service().list(query)
  }

  /**
   * 更新订单状态
   */
  async updateStatus(id: number, status: number): Promise<boolean> {
    if (!OrderStatus.is_valid(status)) {
      throw new Error('Invalid order status: ' + status.toString())
    }

    const order = await this.getById(id)
    if (order === null) {
      throw new Error('Order not found: ' + id.toString())
    }

    // 状态流转验证
    if (!this.isValidStatusTransition(order.status, status)) {
      throw new Error('Invalid status transition: ' + OrderStatus.label(order.status) + ' -> ' + OrderStatus.label(status))
    }

    const entry = this.getOrderEntry()
    const patch = entry.update()
      .set('status', status)
      .set('updatedAt', Date.now())
    
    return await entry.service().patchById(id, patch)
  }

  /**
   * 支付订单
   */
  async pay(id: number): Promise<boolean> {
    return await this.updateStatus(id, OrderStatus.PAID)
  }

  /**
   * 发货
   */
  async ship(id: number): Promise<boolean> {
    return await this.updateStatus(id, OrderStatus.SHIPPED)
  }

  /**
   * 完成订单
   */
  async complete(id: number): Promise<boolean> {
    return await this.updateStatus(id, OrderStatus.COMPLETED)
  }

  /**
   * 取消订单
   */
  async cancel(id: number): Promise<boolean> {
    const order = await this.getById(id)
    if (order === null) {
      throw new Error('Order not found: ' + id.toString())
    }

    // 只有待支付状态可以取消
    if (order.status !== OrderStatus.PENDING_PAYMENT) {
      throw new Error('Only pending payment orders can be cancelled')
    }

    // 事务取消订单并恢复库存
    await getDatabaseManager().tx<void>(async (): Promise<void> => {
      // 更新订单状态
      await this.updateStatus(id, OrderStatus.CANCELLED)

      // 恢复库存
      const items = await this.getOrderItems(id)
      for (const item of items) {
        await this.productService.increaseStock(item.productId, item.quantity)
      }
    })

    return true
  }

  /**
   * 删除订单（逻辑删除）
   */
  async delete(id: number): Promise<boolean> {
    const entry = this.getOrderEntry()
    return await entry.service().removeById(id)
  }

  /**
   * 统计用户订单数量
   */
  async countByUserId(userId: number): Promise<number> {
    const entry = this.getOrderEntry()
    const query = entry.query()
      .eq('deleted', 0)
      .eq('userId', userId)
    return await entry.service().count(query)
  }

  /**
   * 获取订单实体入口
   */
  private getOrderEntry(): EntityEntry<Order, number> {
    return getDatabaseManager().getOrderEntry()
  }

  /**
   * 获取订单明细实体入口
   */
  private getOrderItemEntry(): EntityEntry<OrderItem, number> {
    return getDatabaseManager().getOrderItemEntry()
  }

  /**
   * 构建查询条件
   */
  private buildQuery(params: OrderQueryParams): QueryWrapper<Order> {
    const entry = this.getOrderEntry()
    const query = entry.query().eq('deleted', 0)

    // 订单号搜索
    query.likeIf(params.orderNo !== '', 'orderNo', `%${params.orderNo}%`)

    // 用户筛选
    query.eqIf(params.userId !== null, 'userId', params.userId ?? 0)

    // 状态筛选
    query.eqIf(params.status !== null, 'status', params.status ?? 0)

    // 日期范围（使用 gte/lte 替代不存在的 gteIf/lteIf）
    if (params.startDate !== null) {
      query.gte('createdAt', params.startDate)
    }
    if (params.endDate !== null) {
      query.lte('createdAt', params.endDate)
    }

    return query
  }

  /**
   * 生成订单号
   */
  private generateOrderNo(): string {
    const now = new Date()
    const timestamp = now.getTime()
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0')
    return 'ORD' + timestamp.toString() + random
  }

  /**
   * 验证状态流转
   */
  private isValidStatusTransition(from: number, to: number): boolean {
    // 待支付 -> 已支付、已取消
    if (from === OrderStatus.PENDING_PAYMENT) {
      return to === OrderStatus.PAID || to === OrderStatus.CANCELLED
    }
    // 已支付 -> 已发货
    if (from === OrderStatus.PAID) {
      return to === OrderStatus.SHIPPED
    }
    // 已发货 -> 已完成
    if (from === OrderStatus.SHIPPED) {
      return to === OrderStatus.COMPLETED
    }
    return false
  }
}

/**
 * 获取订单服务实例
 */
export function getOrderService(): OrderService {
  return new OrderService()
}
