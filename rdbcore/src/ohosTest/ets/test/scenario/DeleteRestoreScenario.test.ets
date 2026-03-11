import { common } from '@kit.AbilityKit'
import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium'
import { RdbDatabase, ServiceImpl } from '../../../../main/ets'
import { obtainOhosTestContext } from '../support/OhosTestContext'
import {
  DeleteRestoreRecord,
  clearDeleteRestoreScenarioTable,
  createDeleteRestoreScenarioDatabase,
  rebuildDeleteRestoreScenarioTable,
  seedDeleteRestoreScenarioTable
} from '../support/RdbDeleteRestoreScenarioSupport'

export default function deleteRestoreScenarioTest(): void {
  let context: common.Context | null = null
  let database: RdbDatabase | null = null
  let service: ServiceImpl<DeleteRestoreRecord, number> | null = null

  describe('RdbDeleteRestoreScenario', () => {
    beforeAll(async (): Promise<void> => {
      context = await obtainOhosTestContext()
      await rebuildDeleteRestoreScenarioTable(requireContext(context))
      database = createDeleteRestoreScenarioDatabase(requireContext(context))
      await requireDatabase(database).ensureInitialized()
      service = requireDatabase(database).entity<DeleteRestoreRecord, number>('DeleteRestoreRecord').service()
    })

    beforeEach(async (): Promise<void> => {
      await seedDeleteRestoreScenarioTable(requireContext(context))
    })

    afterAll(async (): Promise<void> => {
      await clearDeleteRestoreScenarioTable(requireContext(context))
    })

    it('include_deleted_should_load_archive', 0, async (): Promise<void> => {
      const activeQuery = await requireService(service).getById(43)
      const archive = await requireService(service).getById(43, true)

      expect(activeQuery === null).assertTrue()
      expect(archive !== null).assertTrue()
      if (archive === null) {
        throw new Error('archive record is not ready')
      }
      expect(archive.name).assertEqual('restore-archive')
      expect(archive.deleted).assertEqual(1)
    })

    it('remove_should_hide_profile', 0, async (): Promise<void> => {
      const removed = await requireService(service).removeById(41)
      const active = await requireService(service).getById(41)
      const deleted = await requireService(service).getById(41, true)
      const total = await requireService(service).count()

      expect(removed).assertTrue()
      expect(active === null).assertTrue()
      expect(deleted !== null).assertTrue()
      expect(total).assertEqual(1)
      if (deleted === null) {
        throw new Error('deleted record is not ready')
      }
      expect(deleted.deleted).assertEqual(1)
      expect(deleted.updatedAt).assertEqual(980)
    })

    it('restore_should_recover_archive', 0, async (): Promise<void> => {
      const restored = await requireService(service).restoreById(43)
      const record = await requireService(service).getById(43)
      const total = await requireService(service).count()

      expect(restored).assertTrue()
      expect(record !== null).assertTrue()
      expect(total).assertEqual(3)
      if (record === null) {
        throw new Error('restored record is not ready')
      }
      expect(record.deleted).assertEqual(0)
      expect(record.updatedAt).assertEqual(980)
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
    throw new Error('delete restore scenario database is not ready')
  }
  return database
}

function requireService(service: ServiceImpl<DeleteRestoreRecord, number> | null): ServiceImpl<DeleteRestoreRecord, number> {
  if (service === null) {
    throw new Error('delete restore scenario service is not ready')
  }
  return service
}