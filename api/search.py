#!/usr/bin/env python3
import json
import re
import traceback
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

IMPORT_ERROR = None
try:
    from primp import Client
    from fast_flights import FlightQuery, Passengers, create_query
    from fast_flights.parser import parse
except Exception as e:
    IMPORT_ERROR = traceback.format_exc()


CITY_TO_IATA = {
    'budapest': 'BUD',
    'porto': 'OPO',
    'roma': 'ROM',
    'rome': 'ROM',
    'fiumicino': 'FCO',
    'ciampino': 'CIA',
    'milano': 'MIL',
    'milan': 'MIL',
    'bergamo': 'BGY',
    'malpensa': 'MXP',
    'linate': 'LIN',
    'napoli': 'NAP',
    'bologna': 'BLQ',
    'venezia': 'VCE',
    'torino': 'TRN',
    'palermo': 'PMO',
    'catania': 'CTA',
    'messina': 'CTA',
    'taormina': 'CTA',
    'siracusa': 'CTA',
    'trapani': 'TPS',
    'bari': 'BRI',
    'brindisi': 'BDS',
    'cagliari': 'CAG',
    'olbia': 'OLB',
    'alghero': 'AHO',
    'lisbona': 'LIS',
    'barcellona': 'BCN',
    'madrid': 'MAD',
    'siviglia': 'SVQ',
    'valencia': 'VLC',
    'parigi': 'PAR',
    'berlino': 'BER',
    'monaco': 'MUC',
    'monaco di baviera': 'MUC',
    'munich': 'MUC',
    'stoccarda': 'STR',
    'stuttgart': 'STR',
    'amsterdam': 'AMS',
    'praga': 'PRG',
    'vienna': 'VIE',
    'londra': 'LON',
}

def resolve_iata(name, fallback='ROM'):
    if not name:
        return fallback
    clean = name.strip().lower()
    if len(clean) == 3 and clean.isalpha():
        return clean.upper()
    for k, v in CITY_TO_IATA.items():
        if k in clean:
            return v
    return fallback

def _query_google(flights_query, is_round_trip):
    query = create_query(
        flights=flights_query,
        trip="round-trip" if is_round_trip else "one-way",
        seat="economy",
        passengers=Passengers(adults=1)
    )
    params = query.params()
    params['hl'] = 'it'
    params['curr'] = 'EUR'

    cookies = {"SOCS": "CAESEwgDEgk2MTQ1NzQ4OTUaAmVuIAEaBgiAo_CuBg"}
    client = Client(impersonate="chrome_145", impersonate_os="macos", referer=True, cookie_store=True)
    res = client.get("https://www.google.com/travel/flights", params=params, cookies=cookies)
    parsed = parse(res.text)
    tfs = params.get('tfs', '')
    return parsed, tfs

def _map_offers(parsed, orig_iata, dest_iata, dep_date, ret_date, google_url, direct_only=False):
    has_direct = any(len(f.flights) == 1 for f in parsed)

    offers = []
    for idx, f in enumerate(parsed):
        airlines = ", ".join(f.airlines) if f.airlines else "Compagnia aerea"
        stops_count = len(f.flights) - 1
        is_direct = stops_count == 0

        if (direct_only or has_direct) and not is_direct:
            continue

        first_leg = f.flights[0]
        last_leg = f.flights[-1]

        dep_time = f"{first_leg.departure.time[0]:02d}:{first_leg.departure.time[1]:02d}"
        arr_time = f"{last_leg.arrival.time[0]:02d}:{last_leg.arrival.time[1]:02d}"
        total_duration = sum(leg.duration for leg in f.flights)

        offers.append({
            "id": f"flight-{idx}",
            "airline": airlines,
            "price": f.price,
            "currency": "EUR",
            "isDirect": is_direct,
            "stops": stops_count,
            "departureTime": dep_time,
            "arrivalTime": arr_time,
            "durationMinutes": total_duration,
            "origin": orig_iata,
            "destination": dest_iata,
            "departureDate": dep_date,
            "returnDate": ret_date,
            "bookingUrl": google_url,
        })
    offers.sort(key=lambda x: (not x["isDirect"], x["price"]))
    offers = offers[:4]
    if offers:
        offers[0]["badge"] = "Miglior prezzo"
        fastest = min(offers, key=lambda x: x["durationMinutes"])
        if fastest != offers[0] and fastest["durationMinutes"] <= offers[0]["durationMinutes"] - 15:
            fastest["badge"] = "Più rapido"
    return offers

def search_real_flights(origin_city, dest_city, dep_date, ret_date=None, direct_only=False):
    orig_iata = resolve_iata(origin_city, fallback='ROM')
    dest_iata = resolve_iata(dest_city, fallback='BUD')

    # 1. Round trip query
    flights_round = [
        FlightQuery(date=dep_date, from_airport=orig_iata, to_airport=dest_iata)
    ]
    if ret_date:
        flights_round.append(
            FlightQuery(date=ret_date, from_airport=dest_iata, to_airport=orig_iata)
        )
    parsed_round, tfs_round = _query_google(flights_round, is_round_trip=bool(ret_date))
    google_url = f"https://www.google.com/travel/flights/search?tfs={tfs_round}&hl=it&curr=EUR" if tfs_round else f"https://www.google.com/travel/flights?q=Flights%20to%20{dest_iata}%20from%20{orig_iata}&hl=it&curr=EUR"

    combined_offers = _map_offers(parsed_round, orig_iata, dest_iata, dep_date, ret_date, google_url, direct_only=direct_only)

    # 2. Outbound legs
    parsed_out, tfs_out = _query_google([FlightQuery(date=dep_date, from_airport=orig_iata, to_airport=dest_iata)], is_round_trip=False)
    outbound_offers = _map_offers(parsed_out, orig_iata, dest_iata, dep_date, None, google_url, direct_only=direct_only)

    # 3. Return legs (if round trip)
    return_offers = []
    if ret_date:
        parsed_ret, tfs_ret = _query_google([FlightQuery(date=ret_date, from_airport=dest_iata, to_airport=orig_iata)], is_round_trip=False)
        return_offers = _map_offers(parsed_ret, dest_iata, orig_iata, ret_date, None, google_url, direct_only=direct_only)

    min_out = outbound_offers[0]["price"] if outbound_offers else 0
    min_ret = return_offers[0]["price"] if return_offers else 0
    combo_sum = (min_out + min_ret) if (min_out > 0 and min_ret > 0) else 0
    min_round = combined_offers[0]["price"] if combined_offers else 0

    if min_round > 0 and (combo_sum == 0 or min_round <= combo_sum):
        min_p = min_round
        if combo_sum > 0 and combo_sum != min_round:
            detail_str = f"da {min_round}€ a/r (pacchetto) o {combo_sum}€ a/r (tratte separate)"
        else:
            detail_str = f"{min_round}€ a/r"
    elif combo_sum > 0:
        min_p = combo_sum
        detail_str = f"{combo_sum}€ a/r ({min_out}€ andata + {min_ret}€ ritorno)"
    else:
        min_p = 0
        detail_str = ""

    IATA_NAMES = {
        'CTA': 'Catania / Sicilia (CTA)',
        'PMO': 'Palermo Falcone Borsellino (PMO)',
        'ROM': 'Roma',
        'FCO': 'Roma Fiumicino (FCO)',
        'CIA': 'Roma Ciampino (CIA)',
        'MIL': 'Milano',
        'MXP': 'Milano Malpensa (MXP)',
        'BGY': 'Milano Bergamo (BGY)',
        'LIN': 'Milano Linate (LIN)',
        'NAP': 'Napoli Capodichino (NAP)',
        'BLQ': 'Bologna (BLQ)',
        'VCE': 'Venezia (VCE)',
        'BCN': 'Barcellona (BCN)',
        'MAD': 'Madrid Barajas (MAD)',
        'LIS': 'Lisbona (LIS)',
        'BUD': 'Budapest (BUD)',
        'OPO': 'Porto (OPO)',
        'SVQ': 'Siviglia (SVQ)',
        'VLC': 'Valencia (VLC)',
        'CDG': 'Parigi (CDG)',
        'PAR': 'Parigi',
        'BER': 'Berlino (BER)',
        'MUC': 'Monaco di Baviera (MUC)',
        'STR': 'Stoccarda (STR)',
        'AMS': 'Amsterdam (AMS)',
        'PRG': 'Praga (PRG)',
        'VIE': 'Vienna (VIE)',
        'LHR': 'Londra (LHR)',
    }
    dest_display = IATA_NAMES.get(dest_iata, dest_city or dest_iata)

    if min_p > 0:
        if min_p <= 130:
            price_eval = "economico"
            price_adv = f"Prezzo conveniente: {detail_str} è un'ottima tariffa per {dest_display}."
        elif min_p <= 200:
            price_eval = "nella media"
            price_adv = f"Prezzo nella media: {detail_str} è in linea con le tariffe standard per {dest_display}."
        else:
            price_eval = "alto"
            price_adv = f"Prezzo più alto del solito: {detail_str}. Valuta orari diversi o date flessibili per risparmiare per {dest_display}."
    else:
        price_eval = "nella media"
        price_adv = "Tariffe monitorate in tempo reale su Google Flights."

    return {
        "success": True,
        "origin": orig_iata,
        "destination": dest_iata,
        "depDate": dep_date,
        "retDate": ret_date,
        "directOnly": direct_only,
        "searchUrl": google_url,
        "offers": combined_offers,
        "outboundOffers": outbound_offers,
        "returnOffers": return_offers,
        "priceEvaluation": price_eval,
        "priceAdvice": price_adv,
    }

class handler(BaseHTTPRequestHandler):
    def _send_cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors()
        self.end_headers()

    def do_GET(self):
        if IMPORT_ERROR:
            self.send_response(500)
            self._send_cors()
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(f"Vercel Python Import Error:\n{IMPORT_ERROR}".encode('utf-8'))
            return

        parsed_url = urlparse(self.path)
        if 'health' in parsed_url.path:

            payload = b'{"status":"ok"}'
            self.send_response(200)
            self._send_cors()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(payload)
            return

        qs = parse_qs(parsed_url.query)
        origin = qs.get('origin', ['Roma'])[0]
        dest = qs.get('destination', ['Budapest'])[0]
        dep = qs.get('departureDate', ['2026-12-05'])[0]
        ret = qs.get('returnDate', [None])[0]
        if ret in ('null', '', 'None', 'undefined'):
            ret = None
        direct_only = qs.get('directOnly', ['false'])[0].lower() in ('true', '1', 'yes')

        try:
            result = search_real_flights(origin, dest, dep, ret, direct_only=direct_only)
            payload = json.dumps(result).encode('utf-8')
            self.send_response(200)
            self._send_cors()
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        except Exception as e:
            err_payload = json.dumps({"success": False, "error": str(e)}).encode('utf-8')
            self.send_response(500)
            self._send_cors()
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(err_payload)

if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', 5050), handler)
    print("Fast-flights Vercel Handler listening on http://127.0.0.1:5050")
    server.serve_forever()
