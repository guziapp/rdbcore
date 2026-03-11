import { UIAbility, Want, common } from '@kit.AbilityKit'
import { abilityDelegatorRegistry } from '@kit.TestKit'
import { TEST_ABILITY_NAME, TEST_MODULE_NAME } from '../../testrunner/OpenHarmonyTestRunner'

const WAIT_MS: number = 1200

let cachedContext: common.Context | null = null

export async function obtainOhosTestContext(): Promise<common.Context> {
  if (cachedContext !== null) {
    return cachedContext
  }

  try {
    const delegator = abilityDelegatorRegistry.getAbilityDelegator()
    const args = abilityDelegatorRegistry.getArguments()
    const want: Want = {
      bundleName: args.bundleName,
      abilityName: TEST_ABILITY_NAME,
      moduleName: TEST_MODULE_NAME
    }

    await delegator.startAbility(want)
    await sleep(WAIT_MS)

    const ability: UIAbility = await delegator.getCurrentTopAbility()
    cachedContext = ability.context
    return cachedContext
  } catch (_) {
    throw new Error('failed to obtain ohos test context')
  }
}

function sleep(waitMs: number): Promise<void> {
  return new Promise<void>((resolve: () => void): void => {
    setTimeout((): void => {
      resolve()
    }, waitMs)
  })
}