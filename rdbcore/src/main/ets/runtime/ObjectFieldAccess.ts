import { relationalStore } from '@kit.ArkData'

type DynamicFieldValue = relationalStore.ValueType | Date | undefined

type DynamicRecord = Record<string, DynamicFieldValue>

export function createDynamicObject(): object {
  return {}
}

export function hasDynamicField(target: object, property: string): boolean {
  return Object.prototype.hasOwnProperty.call(target, property)
}

export function readDynamicField(target: object, property: string): DynamicFieldValue {
  return (target as DynamicRecord)[property]
}

export function writeDynamicField(target: object, property: string, value: DynamicFieldValue): void {
  ;(target as DynamicRecord)[property] = value
}