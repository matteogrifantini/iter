# Product

## Register

product

## Platform

android

## Users

Italian-speaking travellers who are planning a short trip from their phone. They may have only a feeling, a few free days or an unfinished idea — not a technical brief. They want help turning that into a trip while still being able to inspect and edit every choice.

## Product Purpose

Iter is a native Android travel-planning app. It starts before the destination is known: it understands the kind of break a person needs, proposes a coherent journey, helps them collect places that genuinely fit, choose where to stay and shape a usable day-by-day itinerary.

Success is not a completed questionnaire. Success is a traveller who can open Iter, understand their next meaningful choice, and see a credible, editable trip steadily take form.

## Positioning

The travel planner that grows a trip with you. AI is a guide and an editor inside the product, never an opaque chatbot that takes over the decision.

## Brand Personality

Calm, curious and decisive. Iter feels like a well-prepared travel companion: it asks one human question at a time, remembers context, explains a suggestion briefly, and leaves space for the traveller's taste.

## Core Experience

### Home

- Start a new trip from one clear primary action.
- Resume one unfinished trip without having to recreate context; the full archive lives in **Viaggi**.
- Open **Scopri** for a video-led selection of complete routes, not a wall of cities or generic metrics.
- Optionally record availability or work shifts. This is a lightweight availability signal in the MVP; there is no document upload or automatic calendar import.

### Discover a journey

Discovery is its own flow, before itinerary construction. Iter asks five human questions, one at a time: desired feeling, available time, rhythm, company and openness to improvisation. A conversational field remains available at every step for answers that do not fit a preset choice. No destination appears before enough context exists.

The result is a short set of complete journey ideas, which may connect cities, towns and landscapes. Each proposal explains its duration, travel mode, stops and personal fit. Choosing a journey starts curation; it does not silently finalize a plan.

### Curate places

Once a journey is chosen, Iter presents museums, streets, piazzas, events and local places along all its stops. A portrait reel makes the decision quick, while visible side controls always offer the equivalent choices: skip, save, or essential. Each recommendation says why it may suit the traveller, based on explicit choices and previous accepted trips. The prototype stops after four meaningful signals so the complete flow can be tested quickly.

### Choose how to arrive

Iter compares flight, train, bus and car on one compact screen for reaching the first stop. The choice is a planning preference, not a ticket. Mock prices and duration ranges are visibly labelled as estimates, external search remains optional, and no selection books or purchases anything.

### Choose where to stay

Iter places the chosen POIs on a demo map and colours the possible bases so the spatial trade-off is visible before reading details. Booking is an optional outbound link only. Iter does not show availability, prices, affiliate results or checkout in the MVP.

### Shape the itinerary

The itinerary is always visible as a real, editable product surface: days, stops, timing, route context and warnings. A conversational composer is attached to this surface rather than replacing it. When a traveller asks for a slower afternoon or removes a stop, Iter shows the proposed local change in the itinerary; the traveller can undo, reject, lock or accept it.

### Profile and personalization

The profile exposes the preferences Iter has learned from accepted choices, not inferred sensitive traits. The traveller can correct them and choose light or dark appearance. Light is the first-launch default and the preference persists locally.

## AI Behaviour and Trust

- AI proposes drafts and local itinerary patches; it does not silently persist, book, pay for, or change locked stops.
- The app exposes meaningful planning events and the resulting change, never hidden prompts or raw model reasoning.
- Every accepted draft becomes an itinerary version. Manual edits and AI suggestions remain distinguishable and reversible.
- A failed source, stale estimate or unavailable route is stated in plain Italian next to the affected choice.
- The client never holds a Gemini or routing-provider secret. Planning requests pass through an authenticated Supabase Edge Function.

## MVP Boundaries

- Launch language: Italian.
- Initial discovery demo: three single-city ideas plus three wider routes, backed by a curated POI catalogue for Roma, Parigi, Barcellona, Lisbona, Porto, Amsterdam, Berlino e Praga.
- Bundled portrait travel clips play as short local sequences and keep source attribution; no live video feed or remote media service is required.
- Mock planning is the default developer and automated-test mode; a free-tier Gemini model is reserved for deliberate manual demos.
- No live public-transit data, live opening hours, prices, reviews, GPS tracking, offline mode, social features, collaborative editing, payments or in-app booking.
- Flight, train, bus and car options in the mock backend are indicative planning shapes, not live fares, schedules or availability.
- No photos, documents, PNRs, payment data, private addresses or work-shift files are sent to an AI provider.

## Accessibility & Inclusion

Italian is the launch language, with strings written so they can be localized. The app follows the device text scale, safe areas, screen-reader labels, keyboard and Android system-back behaviour. Swipe curation has labelled tap alternatives; maps or route visuals always have a timeline/list equivalent. Touch targets are at least 48 dp. Reduced-motion users receive an immediate state change or a crossfade.
