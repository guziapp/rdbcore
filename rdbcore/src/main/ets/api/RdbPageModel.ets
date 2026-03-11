import { NormalizedEntityMeta } from '../metadata'

export interface RdbPageRequest {
  current: number
  size: number
}

export interface RdbPage<T extends object> {
  current: number
  size: number
  total: number
  pages: number
  records: Array<T>
  hasNext: boolean
  hasPrevious: boolean
}

export function normalizeRdbPageRequest(
  meta: NormalizedEntityMeta,
  current: number,
  size: number
): RdbPageRequest {
  const defaultSize = meta.page !== null && meta.page.defaultSize !== undefined ? meta.page.defaultSize : 20
  const maxSize = meta.page !== null && meta.page.maxSize !== undefined ? meta.page.maxSize : 200
  const safeCurrent = current < 1 ? 1 : current
  const safeSizeTmp = size < 1 ? defaultSize : size
  const safeSize = safeSizeTmp > maxSize ? maxSize : safeSizeTmp
  return {
    current: safeCurrent,
    size: safeSize
  }
}

export function buildRdbPageResult<T extends object>(
  request: RdbPageRequest,
  total: number,
  records: Array<T>
): RdbPage<T> {
  const pages = total > 0 ? Math.ceil(total / request.size) : 0
  return {
    current: request.current,
    size: request.size,
    total: total,
    pages: pages,
    records: records,
    hasNext: pages > 0 && request.current < pages,
    hasPrevious: request.current > 1
  }
}