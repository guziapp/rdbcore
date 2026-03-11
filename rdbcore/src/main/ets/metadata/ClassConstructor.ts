export type ClassConstructor<T extends object> = {
  new(...args: object[]): T
  name: string
  prototype: T
}