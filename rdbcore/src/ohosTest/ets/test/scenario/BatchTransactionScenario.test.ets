import { common } from '@kit.AbilityKit'
import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@ohos/hypium'
import { RdbDatabase, ServiceImpl } from '../../../../main/ets'
import { obtainOhosTestContext } from '../support/OhosTestContext'
import {
  BatchTransactionRecord,
  clearBatchScenarioTable,
  createBatchScenarioDatabase,
  rebuildBatchScenarioTable,
  seedBatchScenarioTable
} from '../support/RdbBatchTransactionScenarioSupport'

export default function batchTransactionScenarioTest(): void {
  let context: common.Context | null = null
  let database: RdbDatabase | null = null
  let service: ServiceImpl<BatchTransactionRecord, number> | null = null

  describe('RdbBatchTransactionScenario', () => {
    beforeAll(async (): Promise<void> => {
      context = await obtainOhosTestContext()
      await rebuildBatchScenarioTable(requireContext(context))
      database = createBatchScenarioDatabase(requireContext(context))
      await requireDatabase(database).ensureInitialized()
      service = requireDatabase(database).entity<BatchTransactionRecord, number>('BatchTransactionRecord').service()
    })

    beforeEach(async (): Promise<void> => {
      await seedBatchScenarioTable(requireContext(context))
    })

    afterAll(async (): Promise<void> => {
      await clearBatchScenarioTable(requireContext(context))
    })

    it('batch_should_insert_profiles', 0, async (): Promise<void> => {
      const first = createRecord('import-alpha', 3)
      const second = createRecord('import-beta', 3)

      const ids = await requireService(service).insertBatch([first, second])
      const total = await requireService(service).count()
      const loaded = await requireService(service).getById(ids[0])

      expect(ids.length).assertEqual(2)
      expect(total).assertEqual(5)
      expect(loaded !== null).assertTrue()
      if (loaded === null) {
        throw new Error('inserted batch record is not ready')
      }
      expect(loaded.name).assertEqual('import-alpha')
      expect(loaded.createdAt).assertEqual(950)
      expect(loaded.updatedAt).assertEqual(950)
    })

    it('tx_should_commit_remove_batch', 0, async (): Promise<void> => {
      const removed = await requireDatabase(database).tx<number>(async (_scope): Promise<number> => {
        return requireService(service).removeByIds([31, 32])
      })
      const total = await requireService(service).count()
      const alive = await requireService(service).getById(31)
      const deleted = await requireService(service).getById(31, true)

      expect(removed).assertEqual(2)
      expect(total).assertEqual(1)
      expect(alive === null).assertTrue()
      expect(deleted !== null).assertTrue()
      if (deleted === null) {
        throw new Error('deleted batch record is not ready')
      }
      expect(deleted.deleted).assertEqual(1)
      expect(deleted.updatedAt).assertEqual(950)
    })

    it('tx_should_rollback_batch_import', 0, async (): Promise<void> => {
      const first = createRecord('rollback-alpha', 4)
      const second = createRecord('rollback-beta', 4)
      let insertedIds: Array<number> = []
      let failed: boolean = false

      try {
        await requireDatabase(database).tx<void>(async (_scope): Promise<void> => {
          insertedIds = await requireService(service).insertBatch([first, second])
          throw new Error('mock batch failure')
        })
      } catch (_) {
        failed = true
      }

      const total = await requireService(service).count()
      const firstLoaded = insertedIds.length > 0
        ? await requireService(service).getById(insertedIds[0])
        : null
      const secondLoaded = insertedIds.length > 1
        ? await requireService(service).getById(insertedIds[1])
        : null

      expect(failed).assertTrue()
      expect(insertedIds.length).assertEqual(2)
      expect(total).assertEqual(3)
      expect(firstLoaded === null).assertTrue()
      expect(secondLoaded === null).assertTrue()
    })
  })
}

function createRecord(name: string, status: number): BatchTransactionRecord {
  const record = new BatchTransactionRecord()
  record.name = name
  record.status = status
  return record
}

function requireContext(context: common.Context | null): common.Context {
  if (context === null) {
    throw new Error('ohos test context is not ready')
  }
  return context
}

function requireDatabase(database: RdbDatabase | null): RdbDatabase {
  if (database === null) {
    throw new Error('batch scenario database is not ready')
  }
  return database
}

function requireService(service: ServiceImpl<BatchTransactionRecord, number> | null): ServiceImpl<BatchTransactionRecord, number> {
  if (service === null) {
    throw new Error('batch scenario service is not ready')
  }
  return service
}