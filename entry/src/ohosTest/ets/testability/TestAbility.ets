import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { abilityDelegatorRegistry } from '@kit.TestKit'
import { Hypium } from '@ohos/hypium'
import testsuite from '../test/List.test'

const TAG: string = 'EntryOhosTest'

export default class TestAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const delegator = abilityDelegatorRegistry.getAbilityDelegator()
    const args = abilityDelegatorRegistry.getArguments()
    hilog.info(0x0000, TAG, '%{public}s', 'TestAbility onCreate')
    Hypium.hypiumTest(delegator, args, testsuite)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('testability/pages/Index', (err): void => {
      if (err.code) {
        hilog.error(0x0000, TAG, 'load content failed: %{public}s', JSON.stringify(err) ?? '')
      }
    })
  }
}
