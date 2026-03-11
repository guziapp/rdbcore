import { relationalStore } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'

export interface RdbDatabaseOptions {
  name: string
  context: common.Context
  securityLevel?: relationalStore.SecurityLevel
  tag?: string
}