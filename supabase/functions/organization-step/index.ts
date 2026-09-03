import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, accept, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface OrganizationStepRequest {
  tripId: string;
  phase: string;
  rawDesire?: string;
  intent?: {
    candidateDestinations?: string[];
    origin?: string;
    travelers?: { adults: number; children: number };
  };
  confirmedFlight?: Record<string, unknown>;
  confirmedStay?: Record<string, unknown>;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: OrganizationStepRequest = await req.json();
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    const model = Deno.env.get("GEMINI_MODEL") || "gemini-1.5-flash";

    const hasLiveKey = Boolean(apiKey && apiKey.trim().length > 0);

    if (hasLiveKey) {
      try {
        const prompt = `Sei l'assistente di pianificazione viaggi Iter.
Desiderio utente: "${body.rawDesire ?? ""}"
Fase attuale: ${body.phase}
Destinazioni candidate: ${JSON.stringify(body.intent?.candidateDestinations ?? [])}

Rispondi SOLO in formato JSON valido con questa struttura:
{
  "reasoning": "Breve sintesi logica del prossimo passo",
  "suggestedQuestion": "Domanda mirata da porre all'utente se mancano info chiave (oppure null)",
  "questionOptions": ["opzione 1", "opzione 2", "opzione 3"],
  "proposedDestinations": ["Destinazione 1"]
}`;

        const geminiRes = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey?.trim()}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ role: "user", parts: [{ text: prompt }] }],
              generationConfig: {
                temperature: 0.2,
                responseMimeType: "application/json",
              },
            }),
          }
        );

        if (geminiRes.ok) {
          const geminiData = await geminiRes.json();
          const rawText =
            geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (rawText) {
            const parsed = JSON.parse(rawText);
            return new Response(
              JSON.stringify({
                isLive: true,
                source: "gemini",
                reasoning: parsed.reasoning || "Analisi completata con Gemini",
                suggestedQuestion: parsed.suggestedQuestion,
                questionOptions: parsed.questionOptions || [],
                proposedDestinations: parsed.proposedDestinations || [],
              }),
              {
                headers: { ...corsHeaders, "Content-Type": "application/json" },
                status: 200,
              }
            );
          }
        }
      } catch (geminiError) {
        console.warn("Gemini call failed, falling back to truthful local heuristic:", geminiError);
      }
    }

    // Truthful fallback: nessuna chiave configurata o chiamata fallita
    const rawDesire = (body.rawDesire || "").toLowerCase();
    let proposedDest = "Lisbona";
    if (rawDesire.includes("porto")) proposedDest = "Porto";
    else if (rawDesire.includes("giappone") || rawDesire.includes("tokyo")) proposedDest = "Tokyo";
    else if (rawDesire.includes("parigi")) proposedDest = "Parigi";

    return new Response(
      JSON.stringify({
        isLive: false,
        source: hasLiveKey ? "fallback_heuristic" : "unconfigured_heuristic",
        reasoning: hasLiveKey
          ? "Chiamata a Gemini non riuscita, applicata euristica deterministica locale."
          : "Nessun GEMINI_API_KEY configurato in Supabase secrets. Modalità trasparente locale attiva.",
        suggestedQuestion: "Quanti giorni vorresti dedicare a questo viaggio?",
        questionOptions: ["Weekend lungo (3-4 giorni)", "Una settimana intera", "Più di una settimana"],
        proposedDestinations: [proposedDest],
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
