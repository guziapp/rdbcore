import { RdbPage, RdbPageRequest } from './RdbPageModel'
import { QueryWrapper, UpdateWrapper } from '../dsl'
import { NormalizedEntityMeta } from '../metadata'
import { BaseMapper } from './BaseMapper'

export class ServiceImpl<T extends object, ID> {
  private readonly baseMapper: BaseMapper<T, ID>

  constructor(mapper: BaseMapper<T, ID>) {
    this.baseMapper = mapper
  }

  mapper(): BaseMapper<T, ID> {
    return this.baseMapper
  }

  meta(): NormalizedEntityMeta {
    return this.baseMapper.meta()
  }

  async selectById(id: ID, includeDeleted: boolean = false): Promise<T | null> {
    return this.baseMapper.selectById(id, includeDeleted)
  }

  async selectOne(wrapper?: QueryWrapper<T>): Promise<T | null> {
    return this.baseMapper.selectOne(wrapper)
  }

  async selectList(wrapper?: QueryWrapper<T>): Promise<Array<T>> {
    return this.baseMapper.selectList(wrapper)
  }

  async selectCount(wrapper?: QueryWrapper<T>): Promise<number> {
    return this.baseMapper.selectCount(wrapper)
  }

  async selectPage(page: RdbPageRequest, wrapper?: QueryWrapper<T>): Promise<RdbPage<T>> {
    return this.baseMapper.selectPage(page, wrapper)
  }

  async existsById(id: ID): Promise<boolean> {
    return this.baseMapper.existsById(id)
  }

  async insert(entity: T): Promise<ID> {
    return this.baseMapper.insert(entity)
  }

  async insertBatch(entities: Array<T>): Promise<Array<ID>> {
    return this.baseMapper.insertBatch(entities)
  }

  async deleteById(id: ID, hardDelete: boolean = false): Promise<boolean> {
    return this.baseMapper.deleteById(id, hardDelete)
  }

  async deleteBatchByIds(ids: Array<ID>, hardDelete: boolean = false): Promise<number> {
    return this.baseMapper.deleteBatchByIds(ids, hardDelete)
  }

  async restoreById(id: ID): Promise<boolean> {
    return this.baseMapper.restoreById(id)
  }

  async updatePatchById(id: ID, patch: UpdateWrapper<T>): Promise<boolean> {
    return this.baseMapper.updatePatchById(id, patch)
  }

  async getById(id: ID, includeDeleted: boolean = false): Promise<T | null> {
    return this.selectById(id, includeDeleted)
  }

  async getOne(wrapper?: QueryWrapper<T>): Promise<T | null> {
    return this.selectOne(wrapper)
  }

  async list(wrapper?: QueryWrapper<T>): Promise<Array<T>> {
    return this.selectList(wrapper)
  }

  async count(wrapper?: QueryWrapper<T>): Promise<number> {
    return this.selectCount(wrapper)
  }

  async page(pageRequest: RdbPageRequest, wrapper?: QueryWrapper<T>): Promise<RdbPage<T>> {
    return this.selectPage(pageRequest, wrapper)
  }

  async removeById(id: ID, hardDelete: boolean = false): Promise<boolean> {
    return this.deleteById(id, hardDelete)
  }

  async removeByIds(ids: Array<ID>, hardDelete: boolean = false): Promise<number> {
    return this.deleteBatchByIds(ids, hardDelete)
  }

  async patchById(id: ID, patch: UpdateWrapper<T>): Promise<boolean> {
    return this.updatePatchById(id, patch)
  }
}