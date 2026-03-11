import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import {
  RdbColumn,
  RdbColumnAuditKind,
  RdbEntity,
  RdbDatabase,
  RdbIdStrategy
} from '../../../../main/ets'

export const PROFILE_FLOW_DB_NAME: string = 'rdbcore-profile-flow-scenario.db'
export const PROFILE_FLOW_TABLE_NAME: string = 'profile_flow_record'

@RdbEntity({
  entityName: 'ProfileFlowRecord',
  tableName: PROFILE_FLOW_TABLE_NAME,
  nowProvider: (): number => 990
})
export class ProfileFlowRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  name: string = ''

  @RdbColumn({ nullable: true })
  nickname: string | null = null

  @RdbColumn({ name: 'team_id' })
  teamId: number = 0

  @RdbColumn()
  status: number = 0

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}

export function createProfileFlowScenarioDatabase(context: common.Context): RdbDatabase {
  return new RdbDatabase({
    name: PROFILE_FLOW_DB_NAME,
    context: context,
    securityLevel: relationalStore.SecurityLevel.S1,
    tag: 'rdbcore-profile-flow-scenario'
  })
}

export async function rebuildProfileFlowScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openProfileFlowScenarioStore(context)
    await store.executeSql(`DROP TABLE IF EXISTS ${PROFILE_FLOW_TABLE_NAME}`)
    await store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${PROFILE_FLOW_TABLE_NAME} (` +
        `id INTEGER PRIMARY KEY AUTOINCREMENT, ` +
        `name TEXT NOT NULL, ` +
        `nickname TEXT NULL, ` +
        `team_id INTEGER NOT NULL, ` +
        `status INTEGER NOT NULL, ` +
        `deleted INTEGER NOT NULL DEFAULT 0, ` +
        `created_at INTEGER NOT NULL, ` +
        `updated_at INTEGER NOT NULL)`
    )
  } catch (_) {
    throw new Error('failed to rebuild profile flow scenario table')
  }
}

export async function seedProfileFlowScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openProfileFlowScenarioStore(context)
    await store.executeSql(`DELETE FROM ${PROFILE_FLOW_TABLE_NAME}`)
    await insertProfileFlowSeedRow(store, 51, 'flow-alpha', 'alpha-note', 1, 1, 0, 100, 120)
    await insertProfileFlowSeedRow(store, 52, 'flow-beta', 'beta-note', 1, 1, 0, 110, 130)
    await insertProfileFlowSeedRow(store, 53, 'flow-archive', 'archive-note', 1, 3, 1, 120, 140)
    await insertProfileFlowSeedRow(store, 54, 'flow-gamma', 'gamma-note', 2, 1, 0, 130, 150)
  } catch (_) {
    throw new Error('failed to seed profile flow scenario table')
  }
}

export async function clearProfileFlowScenarioTable(context: common.Context): Promise<void> {
  try {
    const store = await openProfileFlowScenarioStore(context)
    await store.executeSql(`DELETE FROM ${PROFILE_FLOW_TABLE_NAME}`)
  } catch (_) {
    throw new Error('failed to clear profile flow scenario table')
  }
}

async function openProfileFlowScenarioStore(context: common.Context): Promise<relationalStore.RdbStore> {
  try {
    return relationalStore.getRdbStore(context, {
      name: PROFILE_FLOW_DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    })
  } catch (_) {
    throw new Error('failed to open profile flow scenario store')
  }
}

async function insertProfileFlowSeedRow(
  store: relationalStore.RdbStore,
  id: number,
  name: string,
  nickname: string | null,
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
      nickname: nickname,
      team_id: teamId,
      status: status,
      deleted: deleted,
      created_at: createdAt,
      updated_at: updatedAt
    }
    await store.insert(PROFILE_FLOW_TABLE_NAME, values, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
  } catch (_) {
    throw new Error('failed to insert profile flow scenario seed row')
  }
}