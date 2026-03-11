import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { RdbColumn, RdbEntity, RdbDatabase, RdbIdStrategy, pageConfig } from '../../../../main/ets'

export const LIST_DB_NAME: string = 'rdbcore-list-search-scenario.db'
export const LIST_TABLE_NAME: string = 'list_search_record'

@RdbEntity({
  entityName: 'ListSearchRecord',
  tableName: LIST_TABLE_NAME,
  page: pageConfig(2, 20)
})
export class ListSearchRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  name: string = ''

  @RdbColumn({ name: 'team_id' })
  teamId: number = 0

  @RdbColumn()
  status: number = 0

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at' })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at' })
  updatedAt: number = 0
}

export function createListScenarioDatabase(context: common.Context): RdbDatabase {
  return new RdbDatabase({
    name: LIST_DB_NAME,
    context: context,
    securityLevel: relationalStore.SecurityLevel.S1,
    tag: 'rdbcore-list-search-scenario'
  })
}

export async function rebuildListScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openListScenarioStore(context)
    await store.executeSql(`DROP TABLE IF EXISTS ${LIST_TABLE_NAME}`)
    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${LIST_TABLE_NAME} (` +
        `id INTEGER PRIMARY KEY AUTOINCREMENT, ` +
        `name TEXT NOT NULL, ` +
        `team_id INTEGER NOT NULL, ` +
        `status INTEGER NOT NULL, ` +
        `deleted INTEGER NOT NULL DEFAULT 0, ` +
        `created_at INTEGER NOT NULL, ` +
        `updated_at INTEGER NOT NULL)`
    )
  } catch (_) {
    throw new Error('failed to rebuild list scenario table')
  }
}

export async function seedListScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openListScenarioStore(context)
    await store.executeSql(`DELETE FROM ${LIST_TABLE_NAME}`)
    await insertSeedRow(store, 11, 'alice-vip', 1, 1, 0, 100, 110)
    await insertSeedRow(store, 12, 'alice-pro', 2, 1, 0, 200, 220)
    await insertSeedRow(store, 13, 'vip-center-pro', 3, 2, 0, 210, 230)
    await insertSeedRow(store, 14, 'bob-vip', 1, 2, 0, 220, 240)
    await insertSeedRow(store, 15, 'carol', 2, 1, 1, 230, 250)
    await insertSeedRow(store, 16, 'alice-archive', 1, 1, 1, 240, 260)
  } catch (_) {
    throw new Error('failed to seed list scenario table')
  }
}

export async function clearListScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openListScenarioStore(context)
    await store.executeSql(`DELETE FROM ${LIST_TABLE_NAME}`)
  } catch (_) {
    throw new Error('failed to clear list scenario table')
  }
}

async function openListScenarioStore(context: common.Context): Promise<relationalStore.RdbStore> {
  try {
    return relationalStore.getRdbStore(context, {
      name: LIST_DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    })
  } catch (_) {
    throw new Error('failed to open list scenario store')
  }
}

async function insertSeedRow(
  store: relationalStore.RdbStore,
  id: number,
  name: string,
  teamId: number,
  status: number,
  deleted: number,
  createdAt: number,
  updatedAt: number
): Promise<void> {
  try {
    const values: relationalStore.ValuesBucket = {
      id: id,
      name: name,
      team_id: teamId,
      status: status,
      deleted: deleted,
      created_at: createdAt,
      updated_at: updatedAt
    }
    await store.insert(LIST_TABLE_NAME, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
  } catch (_) {
    throw new Error('failed to insert list scenario seed row')
  }
}