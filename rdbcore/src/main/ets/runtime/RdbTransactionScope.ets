export class RdbTransactionScope {
  private readonly databaseTag: string
  private active: boolean = true

  constructor(databaseTag: string) {
    this.databaseTag = databaseTag
  }

  tag(): string {
    return this.databaseTag
  }

  isActive(): boolean {
    return this.active
  }

  close(): void {
    this.active = false
  }
}