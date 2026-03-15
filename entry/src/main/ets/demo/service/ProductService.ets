/**
 * 商品服务
 * 
 * 封装商品相关的业务逻辑
 */
import {
  EntityEntry,
  QueryWrapper,
  RdbPage,
  RdbPageRequest,
  UpdateWrapper
} from 'rdbcore'
import { Product, ProductStatus } from '../entity'
import { getDatabaseManager } from './DatabaseManager'

/**
 * 商品查询参数
 */
export class ProductQueryParams {
  keyword: string = ''
  status: number | null = null
  minPrice: number | null = null
  maxPrice: number | null = null
  current: number = 1
  size: number = 20
}

/**
 * 商品服务
 */
export class ProductService {
  /**
   * 创建商品
   */
  async create(product: Product): Promise<number> {
    const entry = this.getEntry()
    return await entry.service().insert(product)
  }

  /**
   * 批量创建商品
   */
  async createBatch(products: Array<Product>): Promise<Array<number>> {
    const entry = this.getEntry()
    return await entry.service().insertBatch(products)
  }

  /**
   * 根据ID获取商品
   */
  async getById(id: number): Promise<Product | null> {
    const entry = this.getEntry()
    return await entry.service().getById(id)
  }

  /**
   * 根据商品编码获取商品
   */
  async getByProductCode(productCode: string): Promise<Product | null> {
    const entry = this.getEntry()
    const query = entry.query()
      .eq('deleted', 0)
      .eq('productCode', productCode)
    return await entry.service().getOne(query)
  }

  /**
   * 检查商品编码是否存在
   */
  async existsByProductCode(productCode: string): Promise<boolean> {
    const product = await this.getByProductCode(productCode)
    return product !== null
  }

  /**
   * 分页查询商品
   */
  async page(params: ProductQueryParams): Promise<RdbPage<Product>> {
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
   * 列表查询商品
   */
  async list(params: ProductQueryParams): Promise<Array<Product>> {
    const entry = this.getEntry()
    const query = this.buildQuery(params)
      .orderByDesc('createdAt')
    
    return await entry.service().list(query)
  }

  /**
   * 统计商品数量
   */
  async count(params: ProductQueryParams): Promise<number> {
    const entry = this.getEntry()
    const query = this.buildQuery(params)
    return await entry.service().count(query)
  }

  /**
   * 更新商品
   */
  async update(id: number, updates: Partial<Product>): Promise<boolean> {
    const entry = this.getEntry()
    const patch = this.buildUpdate(updates)
    return await entry.service().patchById(id, patch)
  }

  /**
   * 更新商品状态
   */
  async updateStatus(id: number, status: number): Promise<boolean> {
    if (!ProductStatus.is_valid(status)) {
      throw new Error('Invalid product status: ' + status.toString())
    }
    
    const entry = this.getEntry()
    const patch = entry.update()
      .set('status', status)
      .set('updatedAt', Date.now())
    
    return await entry.service().patchById(id, patch)
  }

  /**
   * 更新库存
   */
  async updateStock(id: number, quantity: number): Promise<boolean> {
    const product = await this.getById(id)
    if (product === null) {
      throw new Error('Product not found: ' + id.toString())
    }
    
    const newStock = product.stock + quantity
    if (newStock < 0) {
      throw new Error('Insufficient stock')
    }
    
    const entry = this.getEntry()
    const patch = entry.update()
      .set('stock', newStock)
      .set('status', newStock === 0 ? ProductStatus.SOLD_OUT : product.status)
      .set('updatedAt', Date.now())
    
    return await entry.service().patchById(id, patch)
  }

  /**
   * 扣减库存
   */
  async decreaseStock(id: number, quantity: number): Promise<boolean> {
    return await this.updateStock(id, -quantity)
  }

  /**
   * 增加库存
   */
  async increaseStock(id: number, quantity: number): Promise<boolean> {
    return await this.updateStock(id, quantity)
  }

  /**
   * 删除商品（逻辑删除）
   */
  async delete(id: number): Promise<boolean> {
    const entry = this.getEntry()
    return await entry.service().removeById(id)
  }

  /**
   * 批量删除商品
   */
  async deleteByIds(ids: Array<number>): Promise<number> {
    const entry = this.getEntry()
    return await entry.service().removeByIds(ids)
  }

  /**
   * 获取实体入口
   */
  private getEntry(): EntityEntry<Product, number> {
    return getDatabaseManager().getProductEntry()
  }

  /**
   * 构建查询条件
   */
  private buildQuery(params: ProductQueryParams): QueryWrapper<Product> {
    const entry = this.getEntry()
    const query = entry.query().eq('deleted', 0)

    // 关键字搜索
    query.likeIf(params.keyword !== '', 'name', `%${params.keyword}%`)

    // 状态筛选
    query.eqIf(params.status !== null, 'status', params.status ?? 0)

    // 价格范围（使用 gte/lte 替代不存在的 gteIf/lteIf）
    if (params.minPrice !== null) {
      query.gte('price', params.minPrice)
    }
    if (params.maxPrice !== null) {
      query.lte('price', params.maxPrice)
    }

    return query
  }

  /**
   * 构建更新条件
   */
  private buildUpdate(updates: Partial<Product>): UpdateWrapper<Product> {
    const entry = this.getEntry()
    const patch = entry.update()

    if (updates.name !== undefined) {
      patch.set('name', updates.name)
    }
    if (updates.productCode !== undefined) {
      patch.set('productCode', updates.productCode)
    }
    if (updates.price !== undefined) {
      patch.set('price', updates.price)
    }
    if (updates.stock !== undefined) {
      patch.set('stock', updates.stock)
    }
    if (updates.status !== undefined) {
      patch.set('status', updates.status)
    }

    patch.set('updatedAt', Date.now())

    return patch
  }
}

/**
 * 获取商品服务实例
 */
export function getProductService(): ProductService {
  return new ProductService()
}
