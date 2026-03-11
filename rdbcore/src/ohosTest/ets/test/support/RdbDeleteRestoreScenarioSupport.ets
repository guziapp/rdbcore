import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbDatabase,
  RdbIdStrategy
} from '../../../../main/ets'

export const DELETE_RESTORE_DB_NAME: string = 'rdbcore-delete-restore-scenario.db'
export const DELETE_RESTORE_TABLE_NAME: string = 'delete_restore_record'

@RdbEntity({
  entityName: 'DeleteRestoreRecord',
  tableName: DELETE_RESTORE_TABLE_NAME,
  nowProvider: (): number => 980
})
export class DeleteRestoreRecord {
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

export function createDeleteRestoreScenarioDatabase(context: common.Context): RdbDatabase {
  return new RdbDatabase({
    name: DELETE_RESTORE_DB_NAME,
    context: context,
    securityLevel: relationalStore.SecurityLevel.S1,
    tag: 'rdbcore-delete-restore-scenario'
  })
}

export async function rebuildDeleteRestoreScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openDeleteRestoreScenarioStore(context)
    await store.executeSql(`DROP TABLE IF EXISTS ${DELETE_RESTORE_TABLE_NAME}`)
    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${DELETE_RESTORE_TABLE_NAME} (` +
        `id INTEGER PRIMARY KEY AUTOINCREMENT, ` +
        `name TEXT NOT NULL, ` +
        `status INTEGER NOT NULL, ` +
        `deleted INTEGER NOT NULL DEFAULT 0, ` +
        `created_at INTEGER NOT NULL, ` +
        `updated_at INTEGER NOT NULL)`
    )
  } catch (_) {
    throw new Error('failed to rebuild delete restore scenario table')
  }
}

export async function seedDeleteRestoreScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openDeleteRestoreScenarioStore(context)
    await store.executeSql(`DELETE FROM ${DELETE_RESTORE_TABLE_NAME}`)
    await insertDeleteRestoreSeedRow(store, 41, 'restore-alpha', 1, 0, 100, 120)
    await insertDeleteRestoreSeedRow(store, 42, 'restore-beta', 2, 0, 110, 130)
    await insertDeleteRestoreSeedRow(store, 43, 'restore-archive', 3, 1, 120, 140)
  } catch (_) {
    throw new Error('failed to seed delete restore scenario table')
  }
}

export async function clearDeleteRestoreScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openDeleteRestoreScenarioStore(context)
    await store.executeSql(`DELETE FROM ${DELETE_RESTORE_TABLE_NAME}`)
  } catch (_) {
    throw new Error('failed to clear delete restore scenario table')
  }
}

async function openDeleteRestoreScenarioStore(context: common.Context): Promise<relationalStore.RdbStore> {
  try {
    return relationalStore.getRdbStore(context, {
      name: DELETE_RESTORE_DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    })
  } catch (_) {
    throw new Error('failed to open delete restore scenario store')
  }
}

async function insertDeleteRestoreSeedRow(
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
    await store.insert(DELETE_RESTORE_TABLE_NAME, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
  } catch (_) {
    throw new Error('failed to insert delete restore scenario seed row')
  }
}