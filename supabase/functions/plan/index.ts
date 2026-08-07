import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, accept, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const OPERATIONS = [
  "suggest_destination",
  "curate_places",
  "compose_itinerary",
  "revise_itinerary",
] as const;

type Operation = (typeof OPERATIONS)[number];
type ProviderName = "mock" | "gemini";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

// ---------------------------------------------------------------------------
// PlanDraftV1 — server contract. Schema documented in supabase/functions/plan/README.md.
// ---------------------------------------------------------------------------
interface PlanDraftV1 {
  schemaVersion: "PlanDraftV1";
  operation: Operation;
  destination: string;
  dates: { start: string | null; end: string | null };
  places: PlanPlaceV1[];
  days: PlanDayV1[];
  lockedItemIds: string[];
  source: PlanSourceV1;
}

interface PlanPlaceV1 {
  poiId: string;
  title: string;
  category: string;
}

interface PlanDayV1 {
  dayIndex: number;
  title: string;
  items: PlanItemV1[];
}

interface PlanItemV1 {
  poiId: string;
  title: string;
  category: string;
  timeSlot: string;
  locked: boolean;
}

interface PlanSourceV1 {
  provider: ProviderName;
  generatedAt: string;
  catalogue: string;
}

interface PatchV1 {
  kind: "move_item";
  itemId: string;
  from: { dayIndex: number; timeSlot: string };
  to: { dayIndex: number; timeSlot: string };
  reason: string;
}

interface DatesInput {
  start?: string;
  end?: string;
}

interface PlanContext {
  message?: string;
  destination?: string;
  dates?: DatesInput;
  selectedPlaceIds?: string[];
  itinerary?: unknown;
}

interface PlanRequest {
  operation: Operation;
  tripId?: string;
  clientRequestId?: string;
  context: PlanContext;
  lockedItemIds?: string[];
}

// ---------------------------------------------------------------------------
// Deterministic mock catalogue. No external keys required.
// ---------------------------------------------------------------------------
interface MockPlaceDef {
  poiId: string;
  title: string;
  category: string;
}

interface MockDestination {
  name: string;
  country: string;
  why: string;
  places: MockPlaceDef[];
}

const MOCK_CATALOGUE: MockDestination[] = [
  {
    name: "Porto",
    country: "Portogallo",
    why: "Mare, fiume Douro e una città a misura di passeggiata.",
    places: [
      { poiId: "porto-ribeira", title: "Ribeira", category: "quartiere" },
      {
        poiId: "porto-clerigos",
        title: "Torre dos Clérigos",
        category: "panorama",
      },
      { poiId: "porto-lello", title: "Livraria Lello", category: "cultura" },
      {
        poiId: "porto-douro",
        title: "Passeggiata sul Douro",
        category: "passeggiata",
      },
      {
        poiId: "porto-gaia",
        title: "Cantine a Vila Nova de Gaia",
        category: "food",
      },
    ],
  },
  {
    name: "Roma",
    country: "Italia",
    why: "Storia, buon cibo e quartieri da vivere a piedi.",
    places: [
      { poiId: "roma-colosseo", title: "Colosseo", category: "monumento" },
      { poiId: "roma-borghese", title: "Villa Borghese", category: "parco" },
      { poiId: "roma-trastevere", title: "Trastevere", category: "quartiere" },
      { poiId: "roma-navona", title: "Piazza Navona", category: "piazza" },
      {
        poiId: "roma-vaticano",
        title: "Vaticano e San Pietro",
        category: "cultura",
      },
    ],
  },
  {
    name: "Lisbona",
    country: "Portogallo",
    why: "Colline, tram e tramonti sull'estuario del Tago.",
    places: [
      { poiId: "lis-belem", title: "Torre di Belém", category: "monumento" },
      { poiId: "lis-alfama", title: "Alfama", category: "quartiere" },
      { poiId: "lis-tram28", title: "Tram 28", category: "esperienza" },
      {
        poiId: "lis-miradouro",
        title: "Miradouro da Senhora do Monte",
        category: "panorama",
      },
    ],
  },
  {
    name: "Barcellona",
    country: "Spagna",
    why: "Architettura, mare e tapas tra quartieri vivaci.",
    places: [
      { poiId: "bcn-sagrada", title: "Sagrada Família", category: "monumento" },
      { poiId: "bcn-gotic", title: "Barri Gòtic", category: "quartiere" },
      {
        poiId: "bcn-boqueria",
        title: "Mercat de la Boqueria",
        category: "food",
      },
      { poiId: "bcn-barceloneta", title: "Barceloneta", category: "spiaggia" },
    ],
  },
];

const SLOT_POOL = [
  "09:00–10:30",
  "11:00–12:30",
  "14:30–16:00",
  "16:30–18:00",
  "19:00–20:30",
];

// ---------------------------------------------------------------------------
// SSE writer. Emits only the allowlisted events (stage|proposal|patch|warning|complete|error).
// ---------------------------------------------------------------------------
class Sse {
  constructor(
    private readonly controller: ReadableStreamDefaultController<Uint8Array>,
    private readonly encoder: TextEncoder,
  ) {}

  send(event: string, data: unknown): void {
    const payload = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
    this.controller.enqueue(this.encoder.encode(payload));
  }
}

// ---------------------------------------------------------------------------
// Auth and quota.
// ---------------------------------------------------------------------------
function createUserClient(authHeader: string): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !anonKey) {
    throw new Error("SUPABASE_URL or SUPABASE_ANON_KEY is not set");
  }
  return createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

type QuotaResult = "ok" | "quota-exceeded" | "unavailable";

// Best-effort quota guard. If the RPC/table is missing the caller is only
// warned and the deterministic mock proceeds (no crash, no paid fallback).
async function consumeCredit(client: SupabaseClient): Promise<QuotaResult> {
  try {
    const { data, error } = await client.rpc("consume_ai_credit", {
      max_generations: 2,
      max_global_generations: 70,
    });
    if (error) return "unavailable";
    return data === true ? "ok" : "quota-exceeded";
  } catch (err) {
    console.warn("consume_ai_credit unavailable", err);
    return "unavailable";
  }
}

function resolveProvider(): ProviderName {
  const key = Deno.env.get("GEMINI_API_KEY");
  const model = Deno.env.get("GEMINI_MODEL");
  return key && model ? "gemini" : "mock";
}

// ---------------------------------------------------------------------------
// Request validation (mirrors supabase/functions/plan/README.md).
// ---------------------------------------------------------------------------
type ValidationResult =
  | { ok: true; value: PlanRequest }
  | { ok: false; error: string };

function validateRequest(body: unknown): ValidationResult {
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    return { ok: false, error: "Body must be a JSON object." };
  }
  const b = body as Record<string, unknown>;

  if (
    typeof b.operation !== "string" ||
    !(OPERATIONS as readonly string[]).includes(b.operation)
  ) {
    return { ok: false, error: "Unknown or missing operation." };
  }
  const operation = b.operation as Operation;

  if (b.clientRequestId !== undefined) {
    if (
      typeof b.clientRequestId !== "string" || !UUID_RE.test(b.clientRequestId)
    ) {
      return { ok: false, error: "clientRequestId must be a UUID." };
    }
  }
  if (b.tripId !== undefined) {
    if (typeof b.tripId !== "string" || !UUID_RE.test(b.tripId)) {
      return { ok: false, error: "tripId must be a UUID." };
    }
  }

  const context: PlanContext = {};
  if (b.context !== undefined) {
    if (
      typeof b.context !== "object" || b.context === null ||
      Array.isArray(b.context)
    ) {
      return { ok: false, error: "context must be an object." };
    }
    const c = b.context as Record<string, unknown>;
    if (c.message !== undefined) {
      if (typeof c.message !== "string") {
        return { ok: false, error: "context.message must be a string." };
      }
      context.message = c.message;
    }
    if (c.destination !== undefined) {
      if (typeof c.destination !== "string") {
        return { ok: false, error: "context.destination must be a string." };
      }
      context.destination = c.destination;
    }
    if (c.selectedPlaceIds !== undefined) {
      if (
        !Array.isArray(c.selectedPlaceIds) ||
        !c.selectedPlaceIds.every((x) => typeof x === "string")
      ) {
        return {
          ok: false,
          error: "context.selectedPlaceIds must be an array of strings.",
        };
      }
      context.selectedPlaceIds = c.selectedPlaceIds as string[];
    }
    if (c.dates !== undefined) {
      if (
        typeof c.dates !== "object" || c.dates === null ||
        Array.isArray(c.dates)
      ) {
        return { ok: false, error: "context.dates must be an object." };
      }
      const d = c.dates as Record<string, unknown>;
      const dates: DatesInput = {};
      if (d.start !== undefined) {
        if (typeof d.start !== "string" || !ISO_DATE_RE.test(d.start)) {
          return {
            ok: false,
            error: "context.dates.start must be an ISO date (YYYY-MM-DD).",
          };
        }
        dates.start = d.start;
      }
      if (d.end !== undefined) {
        if (typeof d.end !== "string" || !ISO_DATE_RE.test(d.end)) {
          return {
            ok: false,
            error: "context.dates.end must be an ISO date (YYYY-MM-DD).",
          };
        }
        dates.end = d.end;
      }
      context.dates = dates;
    }
    if (c.itinerary !== undefined) {
      if (
        typeof c.itinerary !== "object" || c.itinerary === null ||
        Array.isArray(c.itinerary)
      ) {
        return { ok: false, error: "context.itinerary must be an object." };
      }
      context.itinerary = c.itinerary;
    }
  }

  let lockedItemIds: string[] = [];
  if (b.lockedItemIds !== undefined) {
    if (
      !Array.isArray(b.lockedItemIds) ||
      !b.lockedItemIds.every((x) => typeof x === "string")
    ) {
      return { ok: false, error: "lockedItemIds must be an array of strings." };
    }
    lockedItemIds = b.lockedItemIds as string[];
  }

  return {
    ok: true,
    value: {
      operation,
      tripId: b.tripId as string | undefined,
      clientRequestId: b.clientRequestId as string | undefined,
      context,
      lockedItemIds,
    },
  };
}

// ---------------------------------------------------------------------------
// Mock provider (deterministic).
// ---------------------------------------------------------------------------
function stableHash(input: string): number {
  let h = 0;
  for (let i = 0; i < input.length; i++) {
    h = (h * 31 + input.charCodeAt(i)) >>> 0;
  }
  return h;
}

function pickDestination(request: PlanRequest): MockDestination {
  const named = request.context.destination?.trim();
  if (named) {
    const found = MOCK_CATALOGUE.find((d) =>
      d.name.toLowerCase() === named.toLowerCase()
    );
    if (found) return found;
  }
  const msg = (request.context.message ?? "").toLowerCase();
  const byMessage = MOCK_CATALOGUE.find((d) =>
    msg.includes(d.name.toLowerCase())
  );
  if (byMessage) return byMessage;
  const seed = stableHash(
    `${request.operation}|${request.clientRequestId ?? ""}|${msg}`,
  );
  return MOCK_CATALOGUE[seed % MOCK_CATALOGUE.length];
}

function placesFor(
  dest: MockDestination,
  request: PlanRequest,
): MockPlaceDef[] {
  const selected = request.context.selectedPlaceIds ?? [];
  if (selected.length > 0) {
    const wanted = selected
      .map((id) => dest.places.find((p) => p.poiId === id))
      .filter((p): p is MockPlaceDef => Boolean(p));
    if (wanted.length > 0) return wanted;
  }
  return [...dest.places];
}

function datesFrom(
  request: PlanRequest,
): { start: string | null; end: string | null } {
  const d = request.context.dates;
  return { start: d?.start ?? null, end: d?.end ?? null };
}

function dayCountFor(request: PlanRequest): number {
  const { start, end } = request.context.dates ?? {};
  if (start && end) {
    const s = new Date(start);
    const e = new Date(end);
    if (!Number.isNaN(s.getTime()) && !Number.isNaN(e.getTime())) {
      const diff = Math.round((e.getTime() - s.getTime()) / 86_400_000) + 1;
      if (diff >= 1 && diff <= 7) return diff;
    }
  }
  return 3;
}

function emptyDraft(
  request: PlanRequest,
  destName: string,
  provider: ProviderName,
  now: string,
): PlanDraftV1 {
  return {
    schemaVersion: "PlanDraftV1",
    operation: request.operation,
    destination: destName,
    dates: datesFrom(request),
    places: [],
    days: [],
    lockedItemIds: request.lockedItemIds ?? [],
    source: { provider, generatedAt: now, catalogue: "mock-catalogue-v1" },
  };
}

function buildDraft(
  request: PlanRequest,
  dest: MockDestination,
  locked: string[],
): PlanDraftV1 {
  const places = placesFor(dest, request);
  const dayCount = dayCountFor(request);
  const days: PlanDayV1[] = [];
  for (let d = 1; d <= dayCount; d++) {
    const dayPlaces = places.slice((d - 1) * 3, (d - 1) * 3 + 3);
    const items: PlanItemV1[] = dayPlaces.map((p, i) => ({
      poiId: p.poiId,
      title: p.title,
      category: p.category,
      timeSlot: SLOT_POOL[i % SLOT_POOL.length],
      locked: locked.includes(p.poiId),
    }));
    days.push({ dayIndex: d, title: `Giorno ${d} · ${dest.name}`, items });
  }
  return {
    schemaVersion: "PlanDraftV1",
    operation: request.operation,
    destination: dest.name,
    dates: datesFrom(request),
    places: places.map((p) => ({
      poiId: p.poiId,
      title: p.title,
      category: p.category,
    })),
    days,
    lockedItemIds: locked,
    source: {
      provider: "mock",
      generatedAt: new Date().toISOString(),
      catalogue: "mock-catalogue-v1",
    },
  };
}

function isPlanDraft(value: unknown): value is PlanDraftV1 {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return v.schemaVersion === "PlanDraftV1" &&
    typeof v.destination === "string" && Array.isArray(v.days);
}

function reviseDraft(
  request: PlanRequest,
): { draft: PlanDraftV1; patch: PatchV1 | null } {
  const locked = new Set(request.lockedItemIds ?? []);
  const existing = request.context.itinerary;
  const draft = isPlanDraft(existing) ? structuredClone(existing) : buildDraft(
    request,
    pickDestination(request),
    request.lockedItemIds ?? [],
  );
  draft.operation = "revise_itinerary";
  draft.lockedItemIds = [...locked];

  let patch: PatchV1 | null = null;
  outer: for (let d = 0; d < draft.days.length; d++) {
    const items = draft.days[d].items;
    for (let i = 0; i + 1 < items.length; i++) {
      const a = items[i];
      const b = items[i + 1];
      if (a.locked || b.locked) continue;
      const before = a.timeSlot;
      a.timeSlot = b.timeSlot;
      b.timeSlot = before;
      patch = {
        kind: "move_item",
        itemId: a.poiId,
        from: { dayIndex: d + 1, timeSlot: before },
        to: { dayIndex: d + 1, timeSlot: a.timeSlot },
        reason:
          "Modifica locale: ho scambiato due momenti non bloccati per ritmi più comodi.",
      };
      break outer;
    }
  }
  return { draft, patch };
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function mockRun(request: PlanRequest, sse: Sse): Promise<void> {
  const trace = request.clientRequestId;
  switch (request.operation) {
    case "suggest_destination": {
      sse.send("stage", {
        type: "stage",
        operation: request.operation,
        message: "Cerco una meta adatta ai tuoi desideri.",
        clientRequestId: trace,
      });
      await delay(120);
      const dest = pickDestination(request);
      sse.send("proposal", {
        type: "proposal",
        operation: request.operation,
        kind: "destination",
        destination: { name: dest.name, country: dest.country, why: dest.why },
        clientRequestId: trace,
      });
      const draft = emptyDraft(
        request,
        dest.name,
        "mock",
        new Date().toISOString(),
      );
      sse.send("complete", {
        type: "complete",
        operation: request.operation,
        clientRequestId: trace,
        draft,
      });
      return;
    }
    case "curate_places": {
      sse.send("stage", {
        type: "stage",
        operation: request.operation,
        message: "Seleziono i luoghi più coerenti con i tuoi gusti.",
        clientRequestId: trace,
      });
      await delay(120);
      const dest = pickDestination(request);
      const places = placesFor(dest, request).map((p) => ({
        poiId: p.poiId,
        title: p.title,
        category: p.category,
      }));
      sse.send("proposal", {
        type: "proposal",
        operation: request.operation,
        kind: "places",
        places,
        clientRequestId: trace,
      });
      const draft = emptyDraft(
        request,
        dest.name,
        "mock",
        new Date().toISOString(),
      );
      draft.places = places;
      sse.send("complete", {
        type: "complete",
        operation: request.operation,
        clientRequestId: trace,
        draft,
      });
      return;
    }
    case "compose_itinerary": {
      sse.send("stage", {
        type: "stage",
        operation: request.operation,
        message: "Compongo la bozza di itinerario.",
        clientRequestId: trace,
      });
      await delay(150);
      const dest = pickDestination(request);
      const draft = buildDraft(request, dest, request.lockedItemIds ?? []);
      sse.send("complete", {
        type: "complete",
        operation: request.operation,
        clientRequestId: trace,
        draft,
      });
      return;
    }
    case "revise_itinerary": {
      sse.send("stage", {
        type: "stage",
        operation: request.operation,
        message:
          "Applico una modifica locale che non tocca i momenti bloccati.",
        clientRequestId: trace,
      });
      await delay(150);
      const { draft, patch } = reviseDraft(request);
      if (patch) {
        sse.send("patch", {
          type: "patch",
          operation: request.operation,
          ...patch,
          clientRequestId: trace,
        });
      }
      sse.send("complete", {
        type: "complete",
        operation: request.operation,
        clientRequestId: trace,
        draft,
      });
      return;
    }
    default:
      throw new Error(`Unhandled operation: ${request.operation}`);
  }
}

// ---------------------------------------------------------------------------
// HTTP plumbing.
// ---------------------------------------------------------------------------
function jsonError(status: number, code: string, message: string): Response {
  return new Response(JSON.stringify({ error: { code, message } }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError(405, "method_not_allowed", "Use POST.");
  }

  const authHeader = req.headers.get("authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonError(401, "unauthorized", "Missing Bearer token.");
  }
  const token = authHeader.slice("Bearer ".length).trim();
  if (!token) {
    return jsonError(401, "unauthorized", "Empty Bearer token.");
  }

  const contentType = req.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) {
    return jsonError(
      415,
      "unsupported_media_type",
      "Content-Type must be application/json.",
    );
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonError(400, "invalid_request", "Body must be valid JSON.");
  }

  const parsed = validateRequest(body);
  if (!parsed.ok) {
    return jsonError(400, "invalid_request", parsed.error);
  }
  const request = parsed.value;

  let client: SupabaseClient;
  try {
    client = createUserClient(authHeader);
  } catch {
    return jsonError(
      500,
      "server_config_error",
      "Auth is not configured on the server.",
    );
  }

  // Reject invalid/expired JWTs before consuming quota.
  const { data: userData, error: userError } = await client.auth.getUser();
  if (userError || !userData.user) {
    return jsonError(401, "unauthorized", "Invalid or expired token.");
  }

  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(
      controller: ReadableStreamDefaultController<Uint8Array>,
    ): Promise<void> {
      const sse = new Sse(controller, encoder);
      try {
        const quota = await consumeCredit(client);
        if (quota === "quota-exceeded") {
          sse.send("error", {
            type: "error",
            operation: request.operation,
            code: "ai_quota_exceeded",
            message:
              "Hai raggiunto il limite giornaliero di generazioni AI. Riprova domani.",
            clientRequestId: request.clientRequestId,
          });
          return;
        }
        if (quota === "unavailable") {
          sse.send("warning", {
            type: "warning",
            operation: request.operation,
            code: "quota_unavailable",
            message:
              "Controllo quota non disponibile in questo ambiente: procedo in modalità demo.",
            clientRequestId: request.clientRequestId,
          });
        }

        if (resolveProvider() === "gemini") {
          sse.send("warning", {
            type: "warning",
            operation: request.operation,
            code: "provider_not_implemented",
            message:
              "Provider gemini non ancora implementato: uso il provider mock deterministico.",
            clientRequestId: request.clientRequestId,
          });
        }

        await mockRun(request, sse);
      } catch (err) {
        console.error("plan internal error", err);
        sse.send("error", {
          type: "error",
          operation: request.operation,
          code: "internal_error",
          message: "Errore interno durante la pianificazione. Riprova.",
          clientRequestId: request.clientRequestId,
        });
      } finally {
        controller.close();
      }
    },
  });

  return new Response(stream, {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
      "X-Accel-Buffering": "no",
    },
  });
});
