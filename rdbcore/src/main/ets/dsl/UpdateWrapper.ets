import { RdbScalarValue } from '../metadata/EntityMeta'
import { NormalizedEntityMeta, requireDeclaredField } from '../metadata'
import { RdbError } from '../metadata/RdbError'

export const enum RdbPatchMode {
  SET = 'SET',
  CLEAR = 'CLEAR'
}

export interface RdbPatchEntry {
  property: string
  mode: RdbPatchMode
  value: RdbScalarValue
}

export interface RdbSetManyEntry {
  property: string
  value: RdbScalarValue
}

export class UpdateWrapper<T extends object> {
  private readonly entityMeta: NormalizedEntityMeta
  private readonly patches: Array<RdbPatchEntry> = []

  constructor(meta: NormalizedEntityMeta) {
    this.entityMeta = meta
  }

  meta(): NormalizedEntityMeta {
    return this.entityMeta
  }

  set(property: string, value: RdbScalarValue): UpdateWrapper<T> {
    this.assertUpdatable(property)
    this.upsertPatch(property, RdbPatchMode.SET, value)
    return this
  }

  setIf(condition: boolean, property: string, value: RdbScalarValue): UpdateWrapper<T> {
    if (!condition) {
      return this
    }
    return this.set(property, value)
  }

  setIfDefined(property: string, value: RdbScalarValue | undefined): UpdateWrapper<T> {
    if (value === undefined) {
      return this
    }
    return this.set(property, value)
  }

  setMany(entries: Array<RdbSetManyEntry>): UpdateWrapper<T> {
    const size = entries.length
    for (let index = 0; index < size; index++) {
      const entry = entries[index]
      this.set(entry.property, entry.value)
    }
    return this
  }

  clear(property: string): UpdateWrapper<T> {
    this.assertUpdatable(property)
    this.upsertPatch(property, RdbPatchMode.CLEAR, null)
    return this
  }

  clearMany(properties: Array<string>): UpdateWrapper<T> {
    const size = properties.length
    for (let index = 0; index < size; index++) {
      this.clear(properties[index])
    }
    return this
  }

  hasPatch(): boolean {
    return this.patches.length > 0
  }

  patchSize(): number {
    return this.patches.length
  }

  snapshot(): Array<RdbPatchEntry> {
    const copied: Array<RdbPatchEntry> = []
    const size = this.patches.length
    for (let index = 0; index < size; index++) {
      const current = this.patches[index]
      copied.push({ property: current.property, mode: current.mode, value: current.value })
    }
    return copied
  }

  private assertUpdatable(property: string): void {
    const field = requireDeclaredField(this.entityMeta, property)
    if (field.updatable !== true) {
      throw new RdbError('FIELD_NOT_UPDATABLE',
        `Field "${property}" is not updatable in ${this.entityMeta.entityName}.`)
    }
  }

  private upsertPatch(property: string, mode: RdbPatchMode, value: RdbScalarValue): void {
    const size = this.patches.length
    for (let index = 0; index < size; index++) {
      const current = this.patches[index]
      if (current.property !== property) {
        continue
      }
      if (current.mode !== mode) {
        throw new RdbError('UPDATE_WRAPPER_PATCH_CONFLICT',
          `Field "${property}" cannot be both set and clear.`)
      }
      this.patches[index] = { property: property, mode: mode, value: value }
      return
    }
    const patch: RdbPatchEntry = { property: property, mode: mode, value: value }
    this.patches.push(patch)
  }
}