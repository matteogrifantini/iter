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

const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

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
    name: "Budapest",
    country: "Ungheria",
    why: "Terme calde, mercatini invernali e la maestosità del Danubio.",
    places: [
      { poiId: "bud-parlamento", title: "Parlamento di Budapest", category: "monumento" },
      { poiId: "bud-castello", title: "Castello di Buda e Bastione dei Pescatori", category: "panorama" },
      { poiId: "bud-szechenyi", title: "Terme Széchenyi", category: "esperienza" },
      { poiId: "bud-basilica", title: "Basilica di Santo Stefano", category: "cultura" },
      { poiId: "bud-mercato", title: "Mercato Centrale (Nagyvásárcsarnok)", category: "food" },
    ],
  },
  {
    name: "Porto",
    country: "Portogallo",
    why: "Mare, fiume Douro e una città a misura di passeggiata.",
    places: [
      { poiId: "porto-ribeira", title: "Ribeira", category: "quartiere" },
      { poiId: "porto-clerigos", title: "Torre dos Clérigos", category: "panorama" },
      { poiId: "porto-lello", title: "Livraria Lello", category: "cultura" },
      { poiId: "porto-douro", title: "Passeggiata sul Douro", category: "passeggiata" },
      { poiId: "porto-gaia", title: "Cantine a Vila Nova de Gaia", category: "food" },
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
      { poiId: "roma-vaticano", title: "Vaticano e San Pietro", category: "cultura" },
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
      { poiId: "lis-miradouro", title: "Miradouro da Senhora do Monte", category: "panorama" },
    ],
  },
  {
    name: "Barcellona",
    country: "Spagna",
    why: "Architettura, mare e tapas tra quartieri vivaci.",
    places: [
      { poiId: "bcn-sagrada", title: "Sagrada Família", category: "monumento" },
      { poiId: "bcn-gotic", title: "Barri Gòtic", category: "quartiere" },
      { poiId: "bcn-boqueria", title: "Mercat de la Boqueria", category: "food" },
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

function createSupabaseClient(authHeader?: string): SupabaseClient | null {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !anonKey) return null;
  return createClient(url, anonKey, {
    global: { headers: authHeader ? { Authorization: authHeader } : {} },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function parseGeminiJson<T = unknown>(rawText: string): T {
  let cleaned = rawText.trim();
  if (cleaned.startsWith("```json")) {
    cleaned = cleaned.slice(7);
  } else if (cleaned.startsWith("```")) {
    cleaned = cleaned.slice(3);
  }
  if (cleaned.endsWith("```")) {
    cleaned = cleaned.slice(0, -3);
  }
  return JSON.parse(cleaned.trim()) as T;
}

function validateRequest(body: unknown): { ok: true; value: PlanRequest } | { ok: false; error: string } {
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    return { ok: false, error: "Body must be a JSON object." };
  }
  const b = body as Record<string, unknown>;

  if (typeof b.operation !== "string" || !(OPERATIONS as readonly string[]).includes(b.operation)) {
    return { ok: false, error: "Unknown or missing operation." };
  }
  const operation = b.operation as Operation;
  const context: PlanContext = {};

  if (b.context && typeof b.context === "object" && !Array.isArray(b.context)) {
    const c = b.context as Record<string, unknown>;
    if (typeof c.message === "string") context.message = c.message;
    if (typeof c.destination === "string") context.destination = c.destination;
    if (Array.isArray(c.selectedPlaceIds)) {
      context.selectedPlaceIds = c.selectedPlaceIds.filter((x): x is string => typeof x === "string");
    }
    if (c.dates && typeof c.dates === "object" && !Array.isArray(c.dates)) {
      const d = c.dates as Record<string, unknown>;
      context.dates = {
        start: typeof d.start === "string" ? d.start : undefined,
        end: typeof d.end === "string" ? d.end : undefined,
      };
    }
    if (c.itinerary && typeof c.itinerary === "object") context.itinerary = c.itinerary;
  }

  return {
    ok: true,
    value: {
      operation,
      tripId: typeof b.tripId === "string" ? b.tripId : undefined,
      clientRequestId: typeof b.clientRequestId === "string" ? b.clientRequestId : undefined,
      context,
      lockedItemIds: Array.isArray(b.lockedItemIds) ? b.lockedItemIds.filter((x): x is string => typeof x === "string") : [],
    },
  };
}

function pickDestination(request: PlanRequest): MockDestination {
  const named = request.context.destination?.trim().toLowerCase();
  const msg = (request.context.message ?? "").toLowerCase();

  for (const d of MOCK_CATALOGUE) {
    if (named && d.name.toLowerCase().includes(named)) return d;
    if (msg.includes(d.name.toLowerCase())) return d;
  }
  return MOCK_CATALOGUE[0];
}

function datesFrom(request: PlanRequest): { start: string | null; end: string | null } {
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
      if (diff >= 1 && diff <= 10) return diff;
    }
  }
  return 3;
}

function buildDraft(request: PlanRequest, dest: MockDestination): PlanDraftV1 {
  const dayCount = dayCountFor(request);
  const days: PlanDayV1[] = [];
  for (let d = 1; d <= dayCount; d++) {
    const items: PlanItemV1[] = dest.places.slice((d - 1) * 2, (d - 1) * 2 + 3).map((p, i) => ({
      poiId: p.poiId,
      title: p.title,
      category: p.category,
      timeSlot: SLOT_POOL[i % SLOT_POOL.length],
      locked: false,
    }));
    days.push({ dayIndex: d, title: `Giorno ${d} · ${dest.name}`, items });
  }
  return {
    schemaVersion: "PlanDraftV1",
    operation: request.operation,
    destination: dest.name,
    dates: datesFrom(request),
    places: dest.places.map((p) => ({ poiId: p.poiId, title: p.title, category: p.category })),
    days,
    lockedItemIds: [],
    source: { provider: "mock", generatedAt: new Date().toISOString(), catalogue: "mock-catalogue-v1" },
  };
}

async function mockRun(request: PlanRequest, sse: Sse): Promise<void> {
  const trace = request.clientRequestId;
  const dest = pickDestination(request);

  if (request.operation === "suggest_destination") {
    sse.send("stage", { type: "stage", operation: request.operation, message: "Cerco una meta adatta ai tuoi desideri.", clientRequestId: trace });
    sse.send("proposal", {
      type: "proposal",
      operation: request.operation,
      kind: "destination",
      destination: { name: dest.name, country: dest.country, why: dest.why },
      clientRequestId: trace,
    });
    const draft = buildDraft(request, dest);
    sse.send("complete", { type: "complete", operation: request.operation, clientRequestId: trace, draft });
  } else {
    const draft = buildDraft(request, dest);
    sse.send("complete", { type: "complete", operation: request.operation, clientRequestId: trace, draft });
  }
}

async function geminiRun(
  request: PlanRequest,
  sse: Sse,
  apiKey: string,
  modelName = "gemini-1.5-flash",
): Promise<void> {
  const trace = request.clientRequestId;
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

  if (request.operation === "suggest_destination" || request.operation === "compose_itinerary") {
    sse.send("stage", {
      type: "stage",
      operation: request.operation,
      message: "Studio i tuoi desideri e compongo la rotta ideale.",
      clientRequestId: trace,
    });

    const userText = request.context.message ?? request.context.destination ?? "weekend rilassante";
    const prompt = `Sei l'assistente di viaggio di Iter ("Rotta Viva"). L'utente scrive: "${userText}".
1. Identifica la destinazione migliore (città o regione e paese).
2. Spiega in modo caldo ed empatico in italiano (2-3 frasi) perché questa meta e periodo sono perfetti.
3. Genera un itinerario di 3-5 giorni con 2-3 tappe imperdibili per giorno.
Rispondi con un JSON che abbia ESATTAMENTE questa struttura:
{
  "destination": "Nome Città (es. Budapest)",
  "country": "Nome Paese (es. Ungheria)",
  "why": "Descrizione accogliente ed evocativa del viaggio...",
  "durationLabel": "5 giorni",
  "dates": "5–10 dic",
  "days": [
    {
      "dayIndex": 1,
      "title": "Giorno 1 · Arrivo e prime scoperte",
      "items": [
        {
          "poiId": "id-univoco",
          "title": "Nome luogo o esperienza",
          "category": "cultura | monumento | food | panorama | passeggiata | relax",
          "timeSlot": "10:00–12:30"
        }
      ]
    }
  ]
}`;

    const res = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.4 },
      }),
    });

    if (!res.ok) {
      throw new Error(`Gemini API error: ${res.status} ${await res.text()}`);
    }

    const json = await res.json();
    const content = json.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
    const parsed = parseGeminiJson<{
      destination?: string;
      country?: string;
      why?: string;
      durationLabel?: string;
      dates?: string;
      days?: Array<{ dayIndex: number; title: string; items: PlanItemV1[] }>;
    }>(content);

    const destName = parsed.destination ?? "Budapest";
    const country = parsed.country ?? "";
    const why = parsed.why ?? "Una rotta su misura per i tuoi ritmi.";

    sse.send("proposal", {
      type: "proposal",
      operation: request.operation,
      kind: "destination",
      destination: { name: destName, country, why },
      clientRequestId: trace,
    });

    const days: PlanDayV1[] = (parsed.days ?? []).map((d, i) => ({
      dayIndex: d.dayIndex ?? i + 1,
      title: d.title ?? `Giorno ${i + 1} · ${destName}`,
      items: (d.items ?? []).map((it, j) => ({
        poiId: it.poiId ?? `item-${i + 1}-${j + 1}`,
        title: it.title ?? `Tappa ${j + 1}`,
        category: it.category ?? "cultura",
        timeSlot: it.timeSlot ?? SLOT_POOL[j % SLOT_POOL.length],
        locked: false,
      })),
    }));

    const draft: PlanDraftV1 = {
      schemaVersion: "PlanDraftV1",
      operation: request.operation,
      destination: destName,
      dates: datesFrom(request),
      places: [],
      days,
      lockedItemIds: [],
      source: { provider: "gemini", generatedAt: new Date().toISOString(), catalogue: "gemini-live" },
    };

    sse.send("complete", {
      type: "complete",
      operation: request.operation,
      clientRequestId: trace,
      draft,
    });
    return;
  }

  await mockRun(request, sse);
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Use POST" }), { status: 405, headers: corsHeaders });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400, headers: corsHeaders });
  }

  const parsed = validateRequest(body);
  if (!parsed.ok) {
    return new Response(JSON.stringify({ error: parsed.error }), { status: 400, headers: corsHeaders });
  }
  const request = parsed.value;

  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller: ReadableStreamDefaultController<Uint8Array>): Promise<void> {
      const sse = new Sse(controller, encoder);
      try {
        const apiKey = Deno.env.get("GEMINI_API_KEY");
        const model = Deno.env.get("GEMINI_MODEL") || "gemini-1.5-flash";

        if (apiKey && apiKey.trim().length > 0) {
          try {
            await geminiRun(request, sse, apiKey.trim(), model);
          } catch (geminiErr) {
            console.warn("Gemini run failed, falling back to mock:", geminiErr);
            await mockRun(request, sse);
          }
        } else {
          await mockRun(request, sse);
        }
      } catch (err) {
        console.error("Plan function error:", err);
        sse.send("error", { type: "error", message: "Internal error", clientRequestId: request.clientRequestId });
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
