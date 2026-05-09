/**
 * Lightweight Firestore REST client for server-side metadata generation.
 * Uses the public REST API (no Firebase Admin SDK needed).
 */

const PROJECT_ID = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? ""
const API_KEY    = process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? ""
const BASE       = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`

// Firestore typed value → JS value
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function unwrap(v: Record<string, unknown>): unknown {
  if ("stringValue"  in v) return v.stringValue
  if ("integerValue" in v) return Number(v.integerValue)
  if ("doubleValue"  in v) return Number(v.doubleValue)
  if ("booleanValue" in v) return v.booleanValue
  if ("nullValue"    in v) return null
  if ("arrayValue"   in v) {
    const av = v.arrayValue as { values?: unknown[] }
    return (av.values ?? []).map(i => unwrap(i as Record<string, unknown>))
  }
  if ("mapValue" in v) {
    const mv = v.mapValue as { fields?: Record<string, unknown> }
    return parseFields(mv.fields ?? {})
  }
  return null
}

function parseFields(fields: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {}
  for (const [k, val] of Object.entries(fields)) {
    out[k] = unwrap(val as Record<string, unknown>)
  }
  return out
}

export async function getDocument(
  collection: string,
  docId: string
): Promise<Record<string, unknown> | null> {
  try {
    const url = `${BASE}/${collection}/${docId}?key=${API_KEY}`
    const res  = await fetch(url, { next: { revalidate: 60 } })
    if (!res.ok) return null
    const json = await res.json()
    if (!json.fields) return null
    return parseFields(json.fields)
  } catch {
    return null
  }
}
