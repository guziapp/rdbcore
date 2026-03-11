import { common } from '@kit.AbilityKit'
import {
  EntityEntry,
  RdbDatabase,
  ServiceImpl
} from '../../../../main/ets'
import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium'
import { obtainOhosTestContext } from '../support/OhosTestContext'
import {
  DetailPatchRecord,
  clearDetailScenarioTable,
  createDetailScenarioDatabase,
  rebuildDetailScenarioTable,
  seedDetailScenarioTable
} from '../support/RdbDetailPatchScenarioSupport'

export default function detailPatchScenarioTest(): void {
  let context: common.Context | null = null
  let database: RdbDatabase | null = null
  let entry: EntityEntry<DetailPatchRecord, number> | null = null
  let service: ServiceImpl<DetailPatchRecord, number> | null = null

  describe('RdbDetailPatchScenario', () => {
    beforeAll(async (): Promise<void> => {
      context = await obtainOhosTestContext()
      await rebuildDetailScenarioTable(requireContext(context))
      database = createDetailScenarioDatabase(requireContext(context))
      await requireDatabase(database).ensureInitialized()
      entry = requireDatabase(database).entity<DetailPatchRecord, number>('DetailPatchRecord')
      service = requireEntry(entry).service()
    })

    beforeEach(async (): Promise<void> => {
      await seedDetailScenarioTable(requireContext(context))
    })

    afterAll(async (): Promise<void> => {
      await clearDetailScenarioTable(requireContext(context))
    })

    it('detail_should_load_by_id', 0, async (): Promise<void> => {
      const record = await requireService(service).getById(21)

      expect(record !== null).assertTrue()
      if (record === null) {
        throw new Error('detail record is not ready')
      }
      expect(record.name).assertEqual('detail-alpha')
      expect(record.nickname).assertEqual('alpha-note')
      expect(record.updatedAt).assertEqual(120)
    })

    it('patch_should_update_profile', 0, async (): Promise<void> => {
      const patch = requireEntry(entry).update()
      patch.set('name', 'detail-alpha-updated').set('status', 2)

      const updated = await requireService(service).patchById(21, patch)
      const record = await requireService(service).getById(21)

      expect(updated).assertTrue()
      expect(record !== null).assertTrue()
      if (record === null) {
        throw new Error('patched detail record is not ready')
      }
      expect(record.name).assertEqual('detail-alpha-updated')
      expect(record.status).assertEqual(2)
      expect(record.createdAt).assertEqual(100)
      expect(record.updatedAt).assertEqual(900)
    })

    it('patch_should_clear_nickname', 0, async (): Promise<void> => {
      const patch = requireEntry(entry).update()
      patch.clear('nickname')

      const updated = await requireService(service).patchById(22, patch)
      const record = await requireService(service).getById(22)

      expect(updated).assertTrue()
      expect(record !== null).assertTrue()
      if (record === null) {
        throw new Error('cleared detail record is not ready')
      }
      expect(record.nickname === null).assertTrue()
      expect(record.updatedAt).assertEqual(900)
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
    throw new Error('detail scenario database is not ready')
  }
  return database
}

function requireEntry(entry: EntityEntry<DetailPatchRecord, number> | null): EntityEntry<DetailPatchRecord, number> {
  if (entry === null) {
    throw new Error('detail scenario entry is not ready')
  }
  return entry
}

function requireService(service: ServiceImpl<DetailPatchRecord, number> | null): ServiceImpl<DetailPatchRecord, number> {
  if (service === null) {
    throw new Error('detail scenario service is not ready')
  }
  return service
}