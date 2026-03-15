import { hilog } from '@kit.PerformanceAnalysisKit'
import { describe, it, expect } from '@ohos/hypium'
import { buildEmptyEntryDemoSnapshot, createEntryDemoEntityMeta } from '../../../main/ets/demo/RdbDemoSupport'

export default function abilityTest(): void {
  describe('EntryDemoAbilityTest', () => {
    it('demo_meta_should_be_visible_in_ohos_test', 0, () => {
      hilog.info(0x0000, 'testTag', '%{public}s', 'entry demo ohosTest begin')
      const meta = createEntryDemoEntityMeta()
      expect(meta.entityName).assertEqual('EntryDemoRecord')
      expect(meta.tableName).assertEqual('entry_demo_record')
      expect(meta.fields.length).assertEqual(5)
    })

    it('empty_snapshot_should_start_from_zero_state', 0, () => {
      const snapshot = buildEmptyEntryDemoSnapshot()
      expect(snapshot.status).assertEqual('')
      expect(snapshot.total).assertEqual(0)
      expect(snapshot.pageSummary).assertEqual('0 / 0')
    })
  })
}