export class RdbError extends Error {
  readonly code: string

  constructor(code: string, message: string, cause?: Error) {
    super(cause !== undefined ? `${message} detail: ${cause.message}` : message)
    this.code = code
    this.name = 'RdbError'
  }
}

export function toRdbError(code: string, message: string, cause?: Error): RdbError {
  return new RdbError(code, message, cause)
}

export function createNotImplementedError(feature: string): RdbError {
  return new RdbError('NOT_IMPLEMENTED', `${feature} is not implemented in the current rdbcore skeleton yet.`)
}