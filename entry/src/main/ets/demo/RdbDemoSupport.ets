import { common } from '@kit.AbilityKit'
import {
  EntityMeta,
  RdbColumn,
  RdbColumnAuditKind,
  RdbDatabase,
  RdbDatabaseOptions,
  RdbEntity,
  RdbIdStrategy,
  RdbPage,
  RdbPageRequest,
  pageConfig,
  resolveDecoratedEntityMeta
} from 'rdbcore'

const ENTRY_DEMO_ENTITY_NAME: string = 'EntryDemoRecord'
const ENTRY_DEMO_TABLE_NAME: string = 'entry_demo_record'
const ENTRY_DEMO_DB_NAME: string = 'entry-demo.db'
const ENTRY_DEMO_PAGE_SIZE: number = 5

@RdbEntity({
  entityName: ENTRY_DEMO_ENTITY_NAME,
  tableName: ENTRY_DEMO_TABLE_NAME,
  page: pageConfig(ENTRY_DEMO_PAGE_SIZE, 20),
  nowProvider: (): number => Date.now()
})
export class EntryDemoRecord {
  @RdbColumn({ idStrategy: RdbIdStrategy.AUTO })
  id: number = 0

  @RdbColumn()
  name: string = ''

  @RdbColumn({ logicDelete: { aliveValue: 0, deletedValue: 1 } })
  deleted: number = 0

  @RdbColumn({ name: 'created_at', audit: RdbColumnAuditKind.CREATED_AT })
  createdAt: number = 0

  @RdbColumn({ name: 'updated_at', audit: RdbColumnAuditKind.UPDATED_AT })
  updatedAt: number = 0
}

class EntryDemoPageRequest implements RdbPageRequest {
  current: number = 1
  size: number = ENTRY_DEMO_PAGE_SIZE
}

export class EntryDemoSnapshot {
  initialized: boolean = false
  status: string = ''
  latestId: number = 0
  latestName: string = ''
  total: number = 0
  pageSummary: string = '0 / 0'
  recordNames: string = ''
}

class EntryDemoSupport {
  private readonly context: common.Context
  private readonly database: RdbDatabase
  private sequence: number = 1

  constructor(context: common.Context) {
    this.context = context
    const options: RdbDatabaseOptions = {
      name: ENTRY_DEMO_DB_NAME,
      context: this.context,
      tag: 'entry-demo'
    }
    this.database = new RdbDatabase(options)
  }

  async initialize(): Promise<EntryDemoSnapshot> {
    await this.database.ensureInitialized()
    return this.buildSnapshot('initialized')
  }

  async refresh(): Promise<EntryDemoSnapshot> {
    await this.database.ensureInitialized()
    return this.buildSnapshot('refreshed')
  }

  async insertSample(): Promise<EntryDemoSnapshot> {
    await this.database.ensureInitialized()
    const service = this.database.entity<EntryDemoRecord, number>(ENTRY_DEMO_ENTITY_NAME).service()
    const record = new EntryDemoRecord()
    record.name = createEntryDemoRecordName(this.sequence)
    this.sequence += 1
    await service.insert(record)
    return this.buildSnapshot('inserted sample record')
  }

  async patchLatest(): Promise<EntryDemoSnapshot> {
    await this.database.ensureInitialized()
    const page = await this.queryLatestPage()
    if (page.records.length === 0) {
      return this.buildSnapshot('patch skipped: no active record')
    }
    const latest = page.records[0]
    const entry = this.database.entity<EntryDemoRecord, number>(ENTRY_DEMO_ENTITY_NAME)
    await entry.service().patchById(latest.id, entry.update().set('name', latest.name + '-updated'))
    return this.buildSnapshot('patched latest record')
  }

  async deleteLatest(): Promise<EntryDemoSnapshot> {
    await this.database.ensureInitialized()
    const page = await this.queryLatestPage()
    if (page.records.length === 0) {
      return this.buildSnapshot('delete skipped: no active record')
    }
    const latest = page.records[0]
    const service = this.database.entity<EntryDemoRecord, number>(ENTRY_DEMO_ENTITY_NAME).service()
    await service.removeById(latest.id)
    return this.buildSnapshot('deleted latest record')
  }

  private async queryLatestPage(): Promise<RdbPage<EntryDemoRecord>> {
    const request = new EntryDemoPageRequest()
    const entry = this.database.entity<EntryDemoRecord, number>(ENTRY_DEMO_ENTITY_NAME)
    const query = entry.query().eq('deleted', 0).orderByDesc('id')
    return entry.service().page(request, query)
  }

  private async buildSnapshot(status: string): Promise<EntryDemoSnapshot> {
    const page = await this.queryLatestPage()
    const snapshot = buildEmptyEntryDemoSnapshot()
    const current = page.pages === 0 ? 0 : page.current
    snapshot.initialized = true
    snapshot.status = status
    snapshot.total = page.total
    snapshot.pageSummary = current.toString() + ' / ' + page.pages.toString()
    if (page.records.length > 0) {
      const latest = page.records[0]
      snapshot.latestId = latest.id
      snapshot.latestName = latest.name
      snapshot.recordNames = summarizeEntryDemoRecords(page.records)
    }
    return snapshot
  }
}

let entryDemoAbilityContext: common.Context | null = null
let entryDemoSupport: EntryDemoSupport | null = null

export function createEntryDemoEntityMeta(): EntityMeta {
  return resolveDecoratedEntityMeta(ENTRY_DEMO_ENTITY_NAME)
}

export function createEntryDemoRecordName(sequence: number): string {
  return 'demo-user-' + sequence.toString()
}

export function summarizeEntryDemoRecords(records: Array<EntryDemoRecord>): string {
  let summary = ''
  const size = records.length
  for (let index = 0; index < size; index++) {
    if (index > 0) {
      summary += ', '
    }
    summary += records[index].name
  }
  return summary
}

export function buildEmptyEntryDemoSnapshot(): EntryDemoSnapshot {
  return new EntryDemoSnapshot()
}

export function setEntryDemoAbilityContext(context: common.Context): void {
  entryDemoAbilityContext = context
  entryDemoSupport = null
}

export function clearEntryDemoAbilityContext(): void {
  entryDemoAbilityContext = null
  entryDemoSupport = null
}

export async function initializeEntryDemo(): Promise<EntryDemoSnapshot> {
  return obtainEntryDemoSupport().initialize()
}

export async function refreshEntryDemo(): Promise<EntryDemoSnapshot> {
  return obtainEntryDemoSupport().refresh()
}

export async function insertEntryDemoRecord(): Promise<EntryDemoSnapshot> {
  return obtainEntryDemoSupport().insertSample()
}

export async function patchLatestEntryDemoRecord(): Promise<EntryDemoSnapshot> {
  return obtainEntryDemoSupport().patchLatest()
}

export async function deleteLatestEntryDemoRecord(): Promise<EntryDemoSnapshot> {
  return obtainEntryDemoSupport().deleteLatest()
}

function obtainEntryDemoSupport(): EntryDemoSupport {
  if (entryDemoSupport !== null) {
    return entryDemoSupport
  }
  if (entryDemoAbilityContext === null) {
    throw new Error('Entry demo context is not ready. Restart the ability and try again.')
  }
  entryDemoSupport = new EntryDemoSupport(entryDemoAbilityContext)
  return entryDemoSupport
}