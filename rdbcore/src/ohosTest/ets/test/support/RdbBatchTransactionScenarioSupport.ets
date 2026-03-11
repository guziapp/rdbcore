import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbDatabase,
  RdbIdStrategy
} from '../../../../main/ets'

export const BATCH_DB_NAME: string = 'rdbcore-batch-transaction-scenario.db'
export const BATCH_TABLE_NAME: string = 'batch_transaction_record'

@RdbEntity({
  entityName: 'BatchTransactionRecord',
  tableName: BATCH_TABLE_NAME,
  nowProvider: (): number => 950
})
export class BatchTransactionRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  name: string = ''

  @RdbColumn()
  status: number = 0

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}

export function createBatchScenarioDatabase(context: common.Context): RdbDatabase {
  return new RdbDatabase({
    name: BATCH_DB_NAME,
    context: context,
    securityLevel: relationalStore.SecurityLevel.S1,
    tag: 'rdbcore-batch-transaction-scenario'
  })
}

export async function rebuildBatchScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openBatchScenarioStore(context)
    await store.executeSql(`DROP TABLE IF EXISTS ${BATCH_TABLE_NAME}`)
    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${BATCH_TABLE_NAME} (` +
        `id INTEGER PRIMARY KEY AUTOINCREMENT, ` +
        `name TEXT NOT NULL, ` +
        `status INTEGER NOT NULL, ` +
        `deleted INTEGER NOT NULL DEFAULT 0, ` +
        `created_at INTEGER NOT NULL, ` +
        `updated_at INTEGER NOT NULL)`
    )
  } catch (_) {
    throw new Error('failed to rebuild batch scenario table')
  }
}

export async function seedBatchScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openBatchScenarioStore(context)
    await store.executeSql(`DELETE FROM ${BATCH_TABLE_NAME}`)
    await insertBatchSeedRow(store, 31, 'batch-alpha', 1, 0, 100, 120)
    await insertBatchSeedRow(store, 32, 'batch-beta', 1, 0, 110, 130)
    await insertBatchSeedRow(store, 33, 'batch-gamma', 2, 0, 120, 140)
  } catch (_) {
    throw new Error('failed to seed batch scenario table')
  }
}

export async function clearBatchScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openBatchScenarioStore(context)
    await store.executeSql(`DELETE FROM ${BATCH_TABLE_NAME}`)
  } catch (_) {
    throw new Error('failed to clear batch scenario table')
  }
}

async function openBatchScenarioStore(context: common.Context): Promise<relationalStore.RdbStore> {
  try {
    return relationalStore.getRdbStore(context, {
      name: BATCH_DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    })
  } catch (_) {
    throw new Error('failed to open batch scenario store')
  }
}

async function insertBatchSeedRow(
  store: relationalStore.RdbStore,
  id: number,
  name: string,
  status: number,
  deleted: number,
  createdAt: number,
  updatedAt: number
): Promise<void> {
  try {
    const values: relationalStore.ValuesBucket = {
      id: id,
      name: name,
      status: status,
      deleted: deleted,
      created_at: createdAt,
      updated_at: updatedAt
    }
    await store.insert(BATCH_TABLE_NAME, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
  } catch (_) {
    throw new Error('failed to insert batch scenario seed row')
  }
}