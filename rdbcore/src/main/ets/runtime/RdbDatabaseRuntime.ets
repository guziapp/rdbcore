import { relationalStore } from '@kit.ArkData'
import { NormalizedEntityMeta } from '../metadata'
import { RdbDatabaseOptions } from './RdbConfig'
import { mapRowToEntity } from './RdbEntityCodec'
import { RdbError, toRdbError } from './RdbError'
import { RdbTransactionScope } from './RdbTransactionScope'

export class RdbDatabaseRuntime {
  private readonly options: RdbDatabaseOptions
  private readonly databaseTag: string
  private storeTask: Promise<relationalStore.RdbStore> | null = null
  private transactionActive: boolean = false

  constructor(options: RdbDatabaseOptions) {
    if (options.name.length === 0) {
      throw new RdbError('DATABASE_NAME_REQUIRED', 'RdbDatabaseOptions.name is required.')
    }
    this.options = options
    this.databaseTag = options.tag !== undefined && options.tag.length > 0 ? options.tag : options.name
  }

  tag(): string {
    return this.databaseTag
  }

  async ensureInitialized(): Promise<void> {
    await this.ensureStore()
  }

  async runInTransactionBoundary<Result>(task: () => Promise<Result>): Promise<Result> {
    if (this.transactionActive) {
      return task()
    }
    return this.tx<Result>(async (_scope): Promise<Result> => {
      return task()
    })
  }

  async tx<Result>(task: (scope: RdbTransactionScope) => Promise<Result>): Promise<Result> {
    if (this.transactionActive) {
      throw new RdbError('NESTED_TX_NOT_ALLOWED', `Nested transaction is not allowed for ${this.databaseTag}.`)
    }
    const store = await this.ensureStore()
    const scope = new RdbTransactionScope(this.databaseTag)
    let transactionBegun: boolean = false
    this.transactionActive = true
    try {
      store.beginTransaction()
      transactionBegun = true
      const result = await task(scope)
      store.commit()
      scope.close()
      return result
    } catch (error) {
      if (transactionBegun) {
        try {
          store.rollBack()
        } catch (rollbackError) {
          scope.close()
          throw new RdbError(
            'TX_ROLLBACK_FAILED',
            `Rollback failed after transaction failure for ${this.databaseTag}. Original error: ${(error as Error).message}`,
            rollbackError as Error
          )
        }
      }
      scope.close()
      throw toRdbError('TX_FAILED', `Transaction failed for ${this.databaseTag}.`, error as Error)
    } finally {
      this.transactionActive = false
    }
  }

  async insert(meta: NormalizedEntityMeta, values: relationalStore.ValuesBucket): Promise<number> {
    const store = await this.ensureStore()
    try {
      return await store.insert(meta.tableName, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
    } catch (error) {
      throw toRdbError('INSERT_FAILED', `Insert failed for ${meta.entityName}.`, error as Error)
    }
  }

  async update(
    meta: NormalizedEntityMeta,
    values: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates
  ): Promise<number> {
    const store = await this.ensureStore()
    try {
      return await store.update(values, predicates, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
    } catch (error) {
      throw toRdbError('UPDATE_FAILED', `Update failed for ${meta.entityName}.`, error as Error)
    }
  }

  async delete(meta: NormalizedEntityMeta, predicates: relationalStore.RdbPredicates): Promise<number> {
    const store = await this.ensureStore()
    try {
      return await store.delete(predicates)
    } catch (error) {
      throw toRdbError('DELETE_FAILED', `Delete failed for ${meta.entityName}.`, error as Error)
    }
  }

  async query<T extends object>(
    meta: NormalizedEntityMeta,
    predicates: relationalStore.RdbPredicates,
    columns?: Array<string>
  ): Promise<Array<T>> {
    const store = await this.ensureStore()
    let resultSet: relationalStore.ResultSet | null = null
    let queryFailed: boolean = false
    try {
      resultSet = await store.query(predicates, columns)
      const result: Array<T> = []
      if (resultSet.goToFirstRow()) {
        do {
          result.push(mapRowToEntity<T>(meta, resultSet.getRow()))
        } while (resultSet.goToNextRow())
      }
      return result
    } catch (error) {
      queryFailed = true
      throw toRdbError('QUERY_FAILED', `Query failed for ${meta.entityName}.`, error as Error)
    } finally {
      if (resultSet !== null) {
        try {
          resultSet.close()
        } catch (closeError) {
          if (!queryFailed) {
            throw toRdbError('RESULT_SET_CLOSE_FAILED', `ResultSet close failed for ${meta.entityName}.`, closeError as Error)
          }
        }
      }
    }
  }

  async count(meta: NormalizedEntityMeta, predicates: relationalStore.RdbPredicates): Promise<number> {
    const store = await this.ensureStore()
    let resultSet: relationalStore.ResultSet | null = null
    let countFailed: boolean = false
    try {
      resultSet = await store.query(predicates)
      return resultSet.rowCount
    } catch (error) {
      countFailed = true
      throw toRdbError('COUNT_FAILED', `Count failed for ${meta.entityName}.`, error as Error)
    } finally {
      if (resultSet !== null) {
        try {
          resultSet.close()
        } catch (closeError) {
          if (!countFailed) {
            throw toRdbError('RESULT_SET_CLOSE_FAILED', `ResultSet close failed for ${meta.entityName}.`, closeError as Error)
          }
        }
      }
    }
  }

  private ensureStore(): Promise<relationalStore.RdbStore> {
    if (this.storeTask === null) {
      const storeConfig = this.createStoreConfig()
      this.storeTask = this.openStore(storeConfig)
    }
    return this.storeTask
  }

  protected async openStore(storeConfig: relationalStore.StoreConfig): Promise<relationalStore.RdbStore> {
    try {
      return await relationalStore.getRdbStore(this.options.context, storeConfig)
    } catch (error) {
      throw toRdbError('OPEN_STORE_FAILED', `Open store failed for ${this.databaseTag}.`, error as Error)
    }
  }

  private createStoreConfig(): relationalStore.StoreConfig {
    return {
      name: this.options.name,
      securityLevel: this.options.securityLevel !== undefined ? this.options.securityLevel : relationalStore.SecurityLevel.S1
    }
  }
}