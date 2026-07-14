# `plan` Edge Function contract

This document specifies the server boundary used by the Flutter client. The function is intentionally not implemented in the mobile app: it is deployed with Supabase and owns all provider secrets.

## Endpoint and authentication

```http
POST /functions/v1/plan
Authorization: Bearer <Supabase user access token>
Content-Type: application/json
Accept: text/event-stream
```

Reject missing or invalid JWTs before consuming quota. Create the Supabase client used for `consume_ai_credit` with the caller's `Authorization` header so `auth.uid()` resolves to the traveller; a service-role client must not be used for that RPC.

## Request

```json
{
  "operation": "suggest_destination | curate_places | compose_itinerary | revise_itinerary",
  "tripId": "optional UUID for an existing owned trip",
  "clientRequestId": "UUID used for tracing and idempotency",
  "context": {
    "message": "plain-language Italian input, optional",
    "destination": "optional selected city",
    "dates": { "start": "optional ISO date", "end": "optional ISO date" },
    "selectedPlaceIds": ["catalogue POI ids only"],
    "itinerary": "current visible draft, when revising"
  },
  "lockedItemIds": ["ids that the model may not move or remove"]
}
```

Validate the request and the provider output against a versioned `PlanDraftV1` schema. The request must contain only the minimum planning context. Never send magic-link email, private address, PNR, payment data, document content or work-shift files to Gemini.

## Streaming response

Return Server-Sent Events from this allowlist only:

| Event | Meaning |
| --- | --- |
| `stage` | A user-facing planning stage, such as catalogue match or route check. No hidden reasoning. |
| `proposal` | A typed destination, place or itinerary proposal. |
| `patch` | A local, validated change the Flutter UI can preview. It cannot move/remove a locked item. |
| `warning` | Source, routing, freshness or constraint uncertainty. |
| `complete` | The valid `PlanDraftV1` draft and source snapshot. |
| `error` | A safe, user-actionable failure code and message. |

The function has a 45-second application timeout. On a partial source failure, emit `warning` and a valid partial `complete` when possible. Never stream model prompts, token traces, chain-of-thought or provider secrets.

## Persistence and approvals

`/plan` is read/propose only. It may read catalogues/cache and consume a quota, but it must not create a trip version, booking, redirect or payment.

After the traveller reviews a proposal, Flutter writes a new `trip_versions` row and its `itinerary_items` under RLS. The client must create a new version rather than mutating an accepted one. A locked item stays locked until the traveller unlocks it explicitly.

## Provider and quota rules

- Default provider: deterministic `mock` for development and automated tests.
- Manual demo provider: a configured Gemini Flash model through `GEMINI_API_KEY` / `GEMINI_MODEL` Edge Function secrets.
- Optional walking/drive/bike routing: server-side only through `ORS_API_KEY`, cached in `public.source_cache` with provider and expiry metadata.
- Before a remote generation, call `public.consume_ai_credit(maxPerUser, maxGlobal)`. The configured global ceiling should stay below the current provider free-tier quota; no automatic paid fallback is allowed.
- Return a clear quota or provider-unavailable error; do not silently substitute fabricated routing or availability data.
