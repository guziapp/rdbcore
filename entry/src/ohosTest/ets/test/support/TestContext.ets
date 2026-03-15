import { UIAbility, Want, common } from '@kit.AbilityKit'
import { abilityDelegatorRegistry } from '@kit.TestKit'

export const TEST_ABILITY_NAME: string = 'TestAbility'
export const TEST_MODULE_NAME: string = 'entry_test'

const WAIT_MS: number = 1200

let cachedContext: common.Context | null = null

export async function obtainTestContext(): Promise<common.Context> {
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
    throw new Error('failed to obtain test context')
  }
}

function sleep(waitMs: number): Promise<void> {
  return new Promise<void>((resolve: () => void): void => {
    setTimeout((): void => {
      resolve()
    }, waitMs)
  })
}
