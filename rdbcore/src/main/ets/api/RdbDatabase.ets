import {
  EntityMeta,
  NormalizedEntityMeta,
  buildNormalizedEntityMetaSignature,
  normalizeEntityMeta,
  resolveDecoratedEntityMeta
} from '../metadata'
import { RdbDatabaseOptions, RdbDatabaseRuntime, RdbError, RdbTransactionScope } from '../runtime'
import { EntityEntry } from './EntityEntry'

export class RdbDatabase {
  private readonly runtime: RdbDatabaseRuntime
  private readonly metaCache: Map<string, NormalizedEntityMeta> = new Map<string, NormalizedEntityMeta>()
  private readonly metaSignatureCache: Map<string, string> = new Map<string, string>()

  constructor(options: RdbDatabaseOptions) {
    this.runtime = new RdbDatabaseRuntime(options)
  }

  tag(): string {
    return this.runtime.tag()
  }

  async ensureInitialized(): Promise<void> {
    await this.runtime.ensureInitialized()
  }

  entity<T extends object, ID>(metaOrEntityName: EntityMeta | string): EntityEntry<T, ID> {
    const normalized = this.resolveMeta(metaOrEntityName)
    return new EntityEntry<T, ID>(this.runtime, normalized)
  }

  async tx<Result>(task: (scope: RdbTransactionScope) => Promise<Result>): Promise<Result> {
    return this.runtime.tx(task)
  }

  private resolveMeta(metaOrEntityName: EntityMeta | string): NormalizedEntityMeta {
    const meta = typeof metaOrEntityName === 'string'
      ? resolveDecoratedEntityMeta(metaOrEntityName)
      : metaOrEntityName
    const normalized = normalizeEntityMeta(meta)
    const cached = this.metaCache.get(normalized.entityName)
    const signature = buildNormalizedEntityMetaSignature(normalized)
    if (cached === undefined) {
      this.metaCache.set(normalized.entityName, normalized)
      this.metaSignatureCache.set(normalized.entityName, signature)
      return normalized
    }
    const cachedSignature = this.metaSignatureCache.get(normalized.entityName)
    if (cachedSignature !== signature) {
      throw new RdbError('META_CONFLICT', `EntityMeta for ${normalized.entityName} conflicts with cached metadata.`)
    }
    return cached
  }
}