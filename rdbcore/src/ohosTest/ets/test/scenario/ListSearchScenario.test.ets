import { common } from '@kit.AbilityKit'
import { beforeAll, beforeEach, afterAll, describe, expect, it } from '@ohos/hypium'
import {
  BaseMapper,
  QueryWrapper,
  RdbDatabase,
  RdbPageRequest
} from '../../../../main/ets'
import { obtainOhosTestContext } from '../support/OhosTestContext'
import {
  ListSearchRecord,
  clearListScenarioTable,
  createListScenarioDatabase,
  rebuildListScenarioTable,
  seedListScenarioTable
} from '../support/RdbListSearchScenarioSupport'

class ScenarioPageRequest implements RdbPageRequest {
  current: number = 1
  size: number = 2
}

export default function listSearchScenarioTest(): void {
  let context: common.Context | null = null
  let database: RdbDatabase | null = null
  let mapper: BaseMapper<ListSearchRecord, number> | null = null

  describe('RdbListSearchScenario', () => {
    beforeAll(async (): Promise<void> => {
      context = await obtainOhosTestContext()
      await rebuildListScenarioTable(requireContext(context))
      database = createListScenarioDatabase(requireContext(context))
      await requireDatabase(database).ensureInitialized()
      mapper = requireDatabase(database).entity<ListSearchRecord, number>('ListSearchRecord').mapper()
    })

    beforeEach(async (): Promise<void> => {
      await seedListScenarioTable(requireContext(context))
    })

    afterAll(async (): Promise<void> => {
      await clearListScenarioTable(requireContext(context))
    })

    it('list_should_filter_by_keyword', 0, async (): Promise<void> => {
      const query = new QueryWrapper<ListSearchRecord>(requireMapper(mapper).meta())
      query.likeIf(true, 'name', '%ali%')
        .inIf(true, 'teamId', [1, 2])
        .betweenIf(true, 'updatedAt', 100, 260)
        .orderByDescIf(true, 'updatedAt')

      const records = await requireMapper(mapper).list(query)

      expect(records.length).assertEqual(2)
      expect(records[0].name).assertEqual('alice-pro')
      expect(records[1].name).assertEqual('alice-vip')
    })

    it('list_should_support_group_filter', 0, async (): Promise<void> => {
      const query = new QueryWrapper<ListSearchRecord>(requireMapper(mapper).meta())
      query.eq('status', 2)
        .or((nested: QueryWrapper<ListSearchRecord>): void => {
          nested.likeRight('name', 'vip').likeLeft('name', 'pro')
        })
        .orderByDesc('updatedAt')

      const records = await requireMapper(mapper).list(query)

      expect(records.length).assertEqual(2)
      expect(records[0].name).assertEqual('bob-vip')
      expect(records[1].name).assertEqual('vip-center-pro')
    })

    it('page_should_match_count', 0, async (): Promise<void> => {
      const query = new QueryWrapper<ListSearchRecord>(requireMapper(mapper).meta())
      const pageRequest = new ScenarioPageRequest()
      query.likeIf(true, 'name', '%vip%')
        .inIf(true, 'status', [1, 2])
        .betweenIf(true, 'updatedAt', 100, 240)
        .orderByDescIf(true, 'updatedAt')

      const total = await requireMapper(mapper).count(query)
      const page = await requireMapper(mapper).page(pageRequest, query)

      expect(total).assertEqual(3)
      expect(page.total).assertEqual(3)
      expect(page.pages).assertEqual(2)
      expect(page.records.length).assertEqual(2)
      expect(page.records[0].name).assertEqual('bob-vip')
      expect(page.hasNext).assertTrue()
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
    throw new Error('scenario database is not ready')
  }
  return database
}

function requireMapper(mapper: BaseMapper<ListSearchRecord, number> | null): BaseMapper<ListSearchRecord, number> {
  if (mapper === null) {
    throw new Error('scenario mapper is not ready')
  }
  return mapper
}