import { common } from '@kit.AbilityKit'
import {
  EntityEntry,
  RdbDatabase,
  ServiceImpl
} from '../../../../main/ets'
import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium'
import { obtainOhosTestContext } from '../support/OhosTestContext'
import {
  ProfileFlowRecord,
  clearProfileFlowScenarioTable,
  createProfileFlowScenarioDatabase,
  rebuildProfileFlowScenarioTable,
  seedProfileFlowScenarioTable
} from '../support/RdbProfileFlowScenarioSupport'

export default function profileFlowScenarioTest(): void {
  let context: common.Context | null = null
  let database: RdbDatabase | null = null
  let entry: EntityEntry<ProfileFlowRecord, number> | null = null
  let service: ServiceImpl<ProfileFlowRecord, number> | null = null

  describe('RdbProfileFlowScenario', () => {
    beforeAll(async (): Promise<void> => {
      context = await obtainOhosTestContext()
      await rebuildProfileFlowScenarioTable(requireContext(context))
      database = createProfileFlowScenarioDatabase(requireContext(context))
      await requireDatabase(database).ensureInitialized()
      entry = requireDatabase(database).entity<ProfileFlowRecord, number>('ProfileFlowRecord')
      service = requireEntry(entry).service()
    })

    beforeEach(async (): Promise<void> => {
      await seedProfileFlowScenarioTable(requireContext(context))
    })

    afterAll(async (): Promise<void> => {
      await clearProfileFlowScenarioTable(requireContext(context))
    })

    it('flow_should_patch_from_list', 0, async (): Promise<void> => {
      const listQuery = requireEntry(entry).query()
      listQuery.eq('teamId', 1).eq('status', 1).likeRight('name', 'flow-').orderByAsc('id')
      const list = await requireService(service).list(listQuery)
      expect(list.length).assertEqual(2)
      if (list.length !== 2) {
        throw new Error('profile flow list is not ready')
      }

      const patch = requireEntry(entry).update()
      patch.set('name', 'flow-alpha-ready').set('status', 2).clear('nickname')
      const updated = await requireService(service).patchById(list[0].id, patch)
      const detail = await requireService(service).getById(51)

      const reviewQuery = requireEntry(entry).query()
      reviewQuery.eq('teamId', 1).eq('status', 2).orderByAsc('id')
      const reviewList = await requireService(service).list(reviewQuery)

      expect(updated).assertTrue()
      expect(detail !== null).assertTrue()
      expect(reviewList.length).assertEqual(1)
      if (reviewList.length !== 1) {
        throw new Error('profile flow review list is not ready')
      }
      if (detail === null) {
        throw new Error('profile flow detail is not ready')
      }
      expect(detail.name).assertEqual('flow-alpha-ready')
      expect(detail.nickname === null).assertTrue()
      expect(detail.status).assertEqual(2)
      expect(detail.updatedAt).assertEqual(990)
      expect(reviewList[0].id).assertEqual(51)
    })

    it('flow_should_archive_from_detail', 0, async (): Promise<void> => {
      const activeQuery = requireEntry(entry).query()
      activeQuery.eq('teamId', 1).orderByAsc('id')
      const beforeList = await requireService(service).list(activeQuery)
      expect(beforeList.length).assertEqual(2)
      if (beforeList.length !== 2) {
        throw new Error('profile flow active list is not ready')
      }

      const removed = await requireService(service).removeById(52)
      const active = await requireService(service).getById(52)
      const archived = await requireService(service).getById(52, true)

      const afterQuery = requireEntry(entry).query()
      afterQuery.eq('teamId', 1).orderByAsc('id')
      const afterList = await requireService(service).list(afterQuery)

      expect(removed).assertTrue()
      expect(active === null).assertTrue()
      expect(archived !== null).assertTrue()
      expect(afterList.length).assertEqual(1)
      if (afterList.length !== 1) {
        throw new Error('profile flow archived list is not ready')
      }
      if (archived === null) {
        throw new Error('profile flow archive is not ready')
      }
      expect(archived.deleted).assertEqual(1)
      expect(archived.updatedAt).assertEqual(990)
      expect(afterList[0].id).assertEqual(51)
    })

    it('flow_should_restore_to_list', 0, async (): Promise<void> => {
      const archive = await requireService(service).getById(53, true)
      const restored = await requireService(service).restoreById(53)
      const detail = await requireService(service).getById(53)

      const listQuery = requireEntry(entry).query()
      listQuery.eq('teamId', 1).orderByAsc('id')
      const activeList = await requireService(service).list(listQuery)

      expect(archive !== null).assertTrue()
      expect(restored).assertTrue()
      expect(detail !== null).assertTrue()
      expect(activeList.length).assertEqual(3)
      if (activeList.length !== 3) {
        throw new Error('profile flow restored list is not ready')
      }
      if (detail === null) {
        throw new Error('profile flow restored detail is not ready')
      }
      expect(detail.deleted).assertEqual(0)
      expect(detail.updatedAt).assertEqual(990)
      expect(activeList[2].id).assertEqual(53)
    })
  })
}

function requireContext(context: common.Context | null): common.Context {
  if (context === null) {
    throw new Error('ohos test context is not ready')
  }
  return context
}

function requireDatabase(database: RdbDatabase | null): RdbDatabase {
  if (database === null) {
    throw new Error('profile flow scenario database is not ready')
  }
  return database
}

function requireEntry(entry: EntityEntry<ProfileFlowRecord, number> | null): EntityEntry<ProfileFlowRecord, number> {
  if (entry === null) {
    throw new Error('profile flow scenario entry is not ready')
  }
  return entry
}

function requireService(service: ServiceImpl<ProfileFlowRecord, number> | null): ServiceImpl<ProfileFlowRecord, number> {
  if (service === null) {
    throw new Error('profile flow scenario service is not ready')
  }
  return service
}