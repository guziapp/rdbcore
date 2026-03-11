import { QueryWrapper, UpdateWrapper } from '../dsl'
import { NormalizedEntityMeta } from '../metadata'
import { RdbDatabaseRuntime } from '../runtime'
import { BaseMapper } from './BaseMapper'
import { ServiceImpl } from './ServiceImpl'

export class EntityEntry<T extends object, ID> {
  private readonly runtime: RdbDatabaseRuntime
  private readonly entityMeta: NormalizedEntityMeta

  constructor(runtime: RdbDatabaseRuntime, meta: NormalizedEntityMeta) {
    this.runtime = runtime
    this.entityMeta = meta
  }

  meta(): NormalizedEntityMeta {
    return this.entityMeta
  }

  mapper(): BaseMapper<T, ID> {
    return new BaseMapper<T, ID>(this.runtime, this.entityMeta)
  }

  service(): ServiceImpl<T, ID> {
    return new ServiceImpl<T, ID>(this.mapper())
  }

  query(): QueryWrapper<T> {
    return new QueryWrapper<T>(this.entityMeta)
  }

  update(): UpdateWrapper<T> {
    return new UpdateWrapper<T>(this.entityMeta)
  }
}