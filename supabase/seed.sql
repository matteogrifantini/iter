-- Iter — seed dati demo (8 città + 3 percorsi + POI)
-- Applicare dopo schema.sql

-- ---- CITTA' ----

insert into public.destinations
  (type, name, country, slug, description, emoji, poster_asset, video_assets,
   stops, travel_mode, season, duration_label, match_score, why_it_fits,
   destination_ids, tags)
values
  ('city', 'Roma', 'Italia', 'roma',
   'Quattro giorni tra Fori e Trastevere, al ritmo che vuoi tu.',
   '🏛️', 'assets/images/travel/roma.jpg', '{"assets/videos/vertical/roma.mp4"}',
   '{}', 'treno', 'primavera', '4 giorni', 0,
   'Storia a portata di passeggiata e una sera di quartiere facile.',
   '{}', '{"città","cultura","cibo"}'),

  ('city', 'Parigi', 'Francia', 'parigi',
   'Musei, lungosenna e colazioni lente in una settimana leggera.',
   '🗼', 'assets/images/travel/parigi.jpg', '{"assets/videos/vertical/parigi.mp4"}',
   '{}', 'treno', 'autunno', '5 giorni', 0,
   'La città che ripaga chi si ferma, quartiere per quartiere.',
   '{}', '{"città","cultura","gastronomia"}'),

  ('city', 'Barcellona', 'Spagna', 'barcellona',
   'Modernismo, mercati e un mare che non guasta.',
   '🌊', 'assets/images/travel/barcellona.jpg', '{"assets/videos/vertical/barcellona.mp4"}',
   '{}', 'aereo', 'primavera', '4 giorni', 0,
   'Un equilibrio raro tra architettura, cibo e mare.',
   '{}', '{"città","architettura","mare"}'),

  ('city', 'Lisbona', 'Portogallo', 'lisbona',
   'Colline, tram e fado: una capitale a misura di passeggiata.',
   '🚋', 'assets/images/travel/lisbona.jpg', '{"assets/videos/vertical/lisbona.mp4"}',
   '{}', 'aereo', 'autunno', '4 giorni', 0,
   'Costi contenuti e luce bellissima anche fuori stagione.',
   '{}', '{"città","scalinate","tram"}'),

  ('city', 'Porto', 'Portogallo', 'porto',
   'Il Douro a piedi, il vino e un centro da cartolina.',
   '🍷', 'assets/images/travel/porto.jpg', '{"assets/videos/vertical/porto.mp4"}',
   '{}', 'aereo', 'primavera', '3 giorni', 0,
   'Piccola, camminabile e sorprendentemente viva.',
   '{}', '{"città","fiume","vino"}'),

  ('city', 'Amsterdam', 'Olanda', 'amsterdam',
   'Canali, bici e musei senza fretta.',
   '🚲', 'assets/images/travel/amsterdam.jpg', '{"assets/videos/vertical/amsterdam.mp4"}',
   '{}', 'treno', 'primavera', '4 giorni', 0,
   'Una città che si vive su due ruote, con l''acqua ovunque.',
   '{}', '{"città","bici","canali"}'),

  ('city', 'Berlino', 'Germania', 'berlino',
   'Storia, arte e una scena notturna senza pari.',
   '🎨', 'assets/images/travel/berlino.jpg', '{"assets/videos/vertical/berlino.mp4"}',
   '{}', 'aereo', 'autunno', '4 giorni', 0,
   'Per chi cerca un viaggio denso, tra memoria e creatività.',
   '{}', '{"città","arte","storia"}'),

  ('city', 'Praga', 'Rep. Ceca', 'praga',
   'Una capitale da fiaba, perfetta per un ponte lungo.',
   '🕰️', 'assets/images/travel/praga.jpg', '{"assets/videos/vertical/praga.mp4"}',
   '{}', 'treno', 'autunno', '3 giorni', 0,
   'Economica, fotografabile e piena di storie da scoprire.',
   '{}', '{"città","castello","birra"}')

on conflict (slug) do update set
  name = excluded.name,
  country = excluded.country,
  description = excluded.description,
  emoji = excluded.emoji,
  poster_asset = excluded.poster_asset,
  video_assets = excluded.video_assets,
  travel_mode = excluded.travel_mode,
  season = excluded.season,
  duration_label = excluded.duration_label,
  why_it_fits = excluded.why_it_fits,
  tags = excluded.tags;

-- ---- PERCORSI ----

insert into public.destinations
  (type, name, country, slug, description, emoji, poster_asset, video_assets,
   stops, travel_mode, season, duration_label, match_score, why_it_fits,
   destination_ids, tags)
values
  ('route', 'Costa atlantica in treno', 'Portogallo', 'atlantic-rail',
   'Da Porto a Lisbona lungo l''oceano, senza stress.',
   '🚆', 'assets/images/travel/rail_coast.jpg', '{"assets/videos/vertical/rail_coast.mp4"}',
   '{"Porto","Aveiro","Lisbona"}', 'treno', 'primavera', '6 giorni', 0,
   'Un itinerario lineare che mescola città e paesaggio.',
   '{"porto","lisbona"}', '{"percorso","treno","costa"}'),

  ('route', 'Toscana lenta', 'Italia', 'toscana-lenta',
   'Borghi, colline e cibo tra Firenze e Siena.',
   '🌻', 'assets/images/travel/toscana.jpg', '{"assets/videos/vertical/toscana.mp4"}',
   '{"Firenze","Chianti","Siena"}', 'auto', 'primavera', '5 giorni', 0,
   'Per chi vuole rallentare davvero, tra un piatto e una collina.',
   '{}', '{"percorso","borghi","cibo"}'),

  ('route', 'Baltico su due ruote', 'Estonia/Lettvia', 'baltic-bike',
   'Da Tallinn a Riga tra foreste, spiagge e città medievali.',
   '🚴', 'assets/images/travel/baltic.jpg', '{"assets/videos/vertical/baltic.mp4"}',
   '{"Tallinn","Pärnu","Riga"}', 'auto', 'estate', '7 giorni', 0,
   'Un percorso fuori dal tour di massa, fresco e fotogenico.',
   '{}', '{"percorso","natura","bici"}')

on conflict (slug) do update set
  name = excluded.name,
  country = excluded.country,
  description = excluded.description,
  emoji = excluded.emoji,
  poster_asset = excluded.poster_asset,
  video_assets = excluded.video_assets,
  stops = excluded.stops,
  travel_mode = excluded.travel_mode,
  season = excluded.season,
  duration_label = excluded.duration_label,
  why_it_fits = excluded.why_it_fits,
  destination_ids = excluded.destination_ids,
  tags = excluded.tags;

-- ---- POI (esempio per Roma e Porto; estendere per le altre città) ----

insert into public.pois
  (destination_id, name, category, emoji, duration_min, best_moment, why_fits)
select d.id, p.name, p.category, p.emoji, p.duration_min, p.best_moment, p.why_fits
from public.destinations d
join (values
  ('roma', 'Foro Romano', 'archeologia', '🏛️', 120, 'mattina', 'Il cuore della Roma antica, da girare lentamente.'),
  ('roma', 'Trastevere', 'quartiere', '🍝', 180, 'sera', 'Passeggiata serale tra vicoli, tavole e vita vera.'),
  ('roma', 'Galleria Borghese', 'museo', '🖼️', 120, 'pomeriggio', 'Capolavori in un parco, da prenotare con calma.'),
  ('porto', 'Cais da Ribeira', 'quartiere', '🌊', 90, 'tramonto', 'Il lungofiume colorato, perfetto per una passeggiata.'),
  ('porto', 'Cantinas del Douro', 'esperienza', '🍷', 90, 'pomeriggio', 'Una degustazione con vista sul fiume.')
) as p(slug, name, category, emoji, duration_min, best_moment, why_fits)
on d.slug = p.slug
on conflict do nothing;
