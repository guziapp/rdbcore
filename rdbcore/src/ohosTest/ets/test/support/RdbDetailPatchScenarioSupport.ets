import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbDatabase,
  RdbIdStrategy
} from '../../../../main/ets'

export const DETAIL_DB_NAME: string = 'rdbcore-detail-patch-scenario.db'
export const DETAIL_TABLE_NAME: string = 'detail_patch_record'

@RdbEntity({
  entityName: 'DetailPatchRecord',
  tableName: DETAIL_TABLE_NAME,
  nowProvider: (): number => 900
})
export class DetailPatchRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  name: string = ''

  @RdbColumn({ nullable: true })
  nickname: string | null = null

  @RdbColumn()
  status: number = 0

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}

export function createDetailScenarioDatabase(context: common.Context): RdbDatabase {
  return new RdbDatabase({
    name: DETAIL_DB_NAME,
    context: context,
    securityLevel: relationalStore.SecurityLevel.S1,
    tag: 'rdbcore-detail-patch-scenario'
  })
}

export async function rebuildDetailScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openDetailScenarioStore(context)
    await store.executeSql(`DROP TABLE IF EXISTS ${DETAIL_TABLE_NAME}`)
    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${DETAIL_TABLE_NAME} (` +
        `id INTEGER PRIMARY KEY AUTOINCREMENT, ` +
        `name TEXT NOT NULL, ` +
        `nickname TEXT NULL, ` +
        `status INTEGER NOT NULL, ` +
        `deleted INTEGER NOT NULL DEFAULT 0, ` +
        `created_at INTEGER NOT NULL, ` +
        `updated_at INTEGER NOT NULL)`
    )
  } catch (_) {
    throw new Error('failed to rebuild detail scenario table')
  }
}

export async function seedDetailScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openDetailScenarioStore(context)
    await store.executeSql(`DELETE FROM ${DETAIL_TABLE_NAME}`)
    await insertDetailSeedRow(store, 21, 'detail-alpha', 'alpha-note', 1, 0, 100, 120)
    await insertDetailSeedRow(store, 22, 'detail-beta', 'beta-note', 2, 0, 110, 130)
    await insertDetailSeedRow(store, 23, 'detail-gone', 'gone-note', 1, 1, 120, 140)
  } catch (_) {
    throw new Error('failed to seed detail scenario table')
  }
}

export async function clearDetailScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openDetailScenarioStore(context)
    await store.executeSql(`DELETE FROM ${DETAIL_TABLE_NAME}`)
  } catch (_) {
    throw new Error('failed to clear detail scenario table')
  }
}

async function openDetailScenarioStore(context: common.Context): Promise<relationalStore.RdbStore> {
  try {
    return relationalStore.getRdbStore(context, {
      name: DETAIL_DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    })
  } catch (_) {
    throw new Error('failed to open detail scenario store')
  }
}

async function insertDetailSeedRow(
  store: relationalStore.RdbStore,
  id: number,
  name: string,
  nickname: string | null,
  status: number,
  deleted: number,
  createdAt: number,
  updatedAt: number
): Promise<void> {
  try {
    const values: relationalStore.ValuesBucket = {
      id: id,
      name: name,
      nickname: nickname,
      status: status,
      deleted: deleted,
      created_at: createdAt,
      updated_at: updatedAt
    }
    await store.insert(DETAIL_TABLE_NAME, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
  } catch (_) {
    throw new Error('failed to insert detail scenario seed row')
  }
}