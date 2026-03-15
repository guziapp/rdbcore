/**
 * 测试数据工厂类
 * 
 * 提供便捷的测试实体创建方法，支持覆盖默认值
 */
import { User, UserStatus } from 'entry/ets/demo/entity/User'
import { Product, ProductStatus } from 'entry/ets/demo/entity/Product'
import { Order, OrderStatus } from 'entry/ets/demo/entity/Order'
import { OrderItem } from 'entry/ets/demo/entity/OrderItem'
import { CreateOrderInput, OrderItemInput } from 'entry/ets/demo/service/OrderService'

/**
 * 生成唯一的时间戳后缀
 */
function uniqueSuffix(): string {
  return Date.now().toString()
}

/**
 * 测试数据工厂
 */
export class TestDataFactory {
  /**
   * 创建测试用户
   */
  static createUser(overrides: Partial<User> = new User()): User {
    const user = new User()
    const suffix = uniqueSuffix()
    user.username = 'test_user_' + suffix
    user.nickname = '测试用户_' + suffix
    user.status = UserStatus.ACTIVE
    user.deleted = 0
    
    // 应用覆盖值
    if (overrides.username !== undefined && overrides.username !== '') {
      user.username = overrides.username
    }
    if (overrides.nickname !== undefined && overrides.nickname !== '') {
      user.nickname = overrides.nickname
    }
    if (overrides.status !== undefined) {
      user.status = overrides.status
    }
    if (overrides.deleted !== undefined) {
      user.deleted = overrides.deleted
    }
    
    return user
  }

  /**
   * 创建测试商品
   */
  static createProduct(overrides: Partial<Product> = new Product()): Product {
    const product = new Product()
    const suffix = uniqueSuffix()
    product.name = '测试商品_' + suffix
    product.productCode = 'PROD_' + suffix
    product.price = 100.0
    product.stock = 100
    product.status = ProductStatus.ON_SHELF
    product.deleted = 0
    
    // 应用覆盖值
    if (overrides.name !== undefined && overrides.name !== '') {
      product.name = overrides.name
    }
    if (overrides.productCode !== undefined && overrides.productCode !== '') {
      product.productCode = overrides.productCode
    }
    if (overrides.price !== undefined) {
      product.price = overrides.price
    }
    if (overrides.stock !== undefined) {
      product.stock = overrides.stock
    }
    if (overrides.status !== undefined) {
      product.status = overrides.status
    }
    if (overrides.deleted !== undefined) {
      product.deleted = overrides.deleted
    }
    
    return product
  }

  /**
   * 创建测试订单
   */
  static createOrder(overrides: Partial<Order> = new Order()): Order {
    const order = new Order()
    const suffix = uniqueSuffix()
    order.orderNo = 'ORD_' + suffix
    order.userId = 1
    order.totalAmount = 0.0
    order.status = OrderStatus.PENDING_PAYMENT
    order.remark = ''
    order.deleted = 0
    
    // 应用覆盖值
    if (overrides.orderNo !== undefined && overrides.orderNo !== '') {
      order.orderNo = overrides.orderNo
    }
    if (overrides.userId !== undefined) {
      order.userId = overrides.userId
    }
    if (overrides.totalAmount !== undefined) {
      order.totalAmount = overrides.totalAmount
    }
    if (overrides.status !== undefined) {
      order.status = overrides.status
    }
    if (overrides.remark !== undefined) {
      order.remark = overrides.remark
    }
    if (overrides.deleted !== undefined) {
      order.deleted = overrides.deleted
    }
    
    return order
  }

  /**
   * 创建测试订单明细
   */
  static createOrderItem(overrides: Partial<OrderItem> = new OrderItem()): OrderItem {
    const orderItem = new OrderItem()
    orderItem.orderId = 1
    orderItem.productId = 1
    orderItem.productName = '测试商品'
    orderItem.price = 100.0
    orderItem.quantity = 1
    orderItem.subtotal = 100.0
    
    // 应用覆盖值
    if (overrides.orderId !== undefined) {
      orderItem.orderId = overrides.orderId
    }
    if (overrides.productId !== undefined) {
      orderItem.productId = overrides.productId
    }
    if (overrides.productName !== undefined && overrides.productName !== '') {
      orderItem.productName = overrides.productName
    }
    if (overrides.price !== undefined) {
      orderItem.price = overrides.price
    }
    if (overrides.quantity !== undefined) {
      orderItem.quantity = overrides.quantity
    }
    if (overrides.subtotal !== undefined) {
      orderItem.subtotal = overrides.subtotal
    }
    
    return orderItem
  }

  /**
   * 创建订单输入
   */
  static createOrderInput(userId: number, items: Array<OrderItemInput> = [], remark: string = ''): CreateOrderInput {
    const input = new CreateOrderInput()
    input.userId = userId
    input.items = items
    input.remark = remark
    return input
  }

  /**
   * 创建订单明细输入
   */
  static createOrderItemInput(productId: number, quantity: number = 1): OrderItemInput {
    const input = new OrderItemInput()
    input.productId = productId
    input.quantity = quantity
    return input
  }
}
