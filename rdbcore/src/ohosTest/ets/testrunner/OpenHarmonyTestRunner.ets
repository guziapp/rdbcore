import { Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit'

const TAG: string = 'RdbOhosTest'
export const TEST_MODULE_NAME: string = 'rdb_test'
export const TEST_ABILITY_NAME: string = 'TestAbility'

export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare(): void {
    hilog.info(0x0000, TAG, '%{public}s', 'OpenHarmonyTestRunner onPrepare')
  }

  async onRun(): Promise<void> {
    try {
      const args = abilityDelegatorRegistry.getArguments()
      const delegator = abilityDelegatorRegistry.getAbilityDelegator()
      const want: Want = {
        bundleName: args.bundleName,
        abilityName: TEST_ABILITY_NAME,
        moduleName: TEST_MODULE_NAME
      }

      hilog.info(0x0000, TAG, '%{public}s', 'OpenHarmonyTestRunner onRun')
      await delegator.startAbility(want)
    } catch (_) {
      throw new Error('failed to start ohos test ability')
    }
  }
}