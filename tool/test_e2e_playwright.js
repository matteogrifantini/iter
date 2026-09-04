const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');

const SCREENSHOT_DIR = '/Users/matteo/.gemini/antigravity/brain/f3aa63b5-4e13-4980-b36c-5bac8e3dbc71/.tempmediaStorage';
const TARGET_URL = 'https://iter-pi-fawn.vercel.app';

async function runE2ETest() {
  console.log('=== INIZIO TEST END-TO-END AUTONOMO (ITER WEB) ===');
  console.log('Target URL:', TARGET_URL);

  const browser = await chromium.launch({
    headless: true,
    channel: 'chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  });

  const page = await context.newPage();
  const consoleLogs = [];
  const pageErrors = [];

  page.on('console', msg => {
    consoleLogs.push(`[${msg.type()}] ${msg.text()}`);
  });
  page.on('pageerror', err => {
    pageErrors.push(err.toString());
    console.error('PAGE ERROR:', err);
  });

  try {
    // 1. CARICAMENTO HOME PAGE
    console.log('\n[1/8] Caricamento Home Page...');
    await page.goto(TARGET_URL, { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(3000); // attendi render Flutter Web Canvas/DOM

    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_01_home.png') });
    console.log('✓ Screenshot Home salvato: e2e_01_home.png');

    // 2. APERTURA PIANIFICAZIONE
    console.log('\n[2/8] Apertura Organizza Nuovo Viaggio...');
    // In Flutter Web html renderer / canvaskit, cerca elementi accessibili o usa click coordinate/touch
    // Proviamo a cliccare il pulsante "Organizza un nuovo viaggio"
    const clickedPlan = await page.evaluate(() => {
      // Cerca nei nodi dom/semantics di flutter
      const elements = Array.from(document.querySelectorAll('flt-semantics, p, span, div, [role="button"]'));
      for (const el of elements) {
        if (el.textContent && el.textContent.includes('Organizza un nuovo viaggio')) {
          el.click();
          return true;
        }
      }
      return false;
    });

    if (!clickedPlan) {
      console.log('Click tramite coordinate centro banner...');
      await page.mouse.click(195, 235); // coordinate del tasto nel banner
    }
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_02_chat_opened.png') });
    console.log('✓ Screenshot Chat salvato: e2e_02_chat_opened.png');

    // 3. INSERIMENTO DESTINAZIONE TENERIFE
    console.log('\n[3/8] Invio messaggio per Tenerife...');
    const inputHandled = await page.evaluate(() => {
      const inputs = Array.from(document.querySelectorAll('input, textarea'));
      if (inputs.length > 0) {
        const input = inputs[inputs.length - 1];
        input.value = 'Voglio andare a Tenerife per 4 giorni';
        input.dispatchEvent(new Event('input', { bubbles: true }));
        return true;
      }
      return false;
    });

    if (inputHandled) {
      await page.keyboard.press('Enter');
    } else {
      // Clicca sul composer in basso
      await page.mouse.click(180, 805);
      await page.keyboard.type('Voglio andare a Tenerife per 4 giorni', { delay: 50 });
      await page.keyboard.press('Enter');
    }

    console.log('Attesa elaborazione AI (10s)...');
    await page.waitForTimeout(10000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_03_tenerife_response.png') });
    console.log('✓ Screenshot risposta Tenerife salvato: e2e_03_tenerife_response.png');

    // 4. VERIFICA PRESENZA ELEMENTI TENERIFE & HERO CARD
    console.log('\n[4/8] Analisi contenuto risposta...');
    const bodyText = await page.evaluate(() => document.body.innerText || '');
    const hasTenerife = bodyText.toLowerCase().includes('tenerife');
    console.log('Testo contiene "Tenerife":', hasTenerife);

    // Controlla se compare "Scopri di più su Tenerife"
    const hasDiscoverBtn = bodyText.includes('Scopri di più');
    console.log('Pulsante "Scopri di più" presente:', hasDiscoverBtn);

    // 5. TEST CHIP E FLIGHT CARD
    console.log('\n[5/8] Verifica Card Volo e Chip...');
    const hasFlightPill = bodyText.includes('Opzioni Volo') || bodyText.includes('Scegli volo') || bodyText.includes('Volo Selezionato');
    console.log('Card Volo presente:', hasFlightPill);

    // Se c'è "Scegli volo", cliccalo
    if (hasFlightPill && (bodyText.includes('Scegli volo') || bodyText.includes('Opzioni Volo'))) {
      console.log('Apertura FlightPickerSheet...');
      await page.evaluate(() => {
        const els = Array.from(document.querySelectorAll('*'));
        for (const el of els) {
          if (el.textContent === 'Scegli volo' || (el.textContent && el.textContent.includes('Opzioni Volo'))) {
            el.click();
            break;
          }
        }
      });
      await page.waitForTimeout(3000);
      await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_04_flight_sheet.png') });
      console.log('✓ Screenshot FlightPickerSheet salvato: e2e_04_flight_sheet.png');

      // Clicca conferma volo
      await page.evaluate(() => {
        const els = Array.from(document.querySelectorAll('*'));
        for (const el of els) {
          if (el.textContent && el.textContent.includes('Conferma questo volo')) {
            el.click();
            break;
          }
        }
      });
      await page.waitForTimeout(2000);
      await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_05_flight_confirmed.png') });
      console.log('✓ Screenshot volo confermato salvato: e2e_05_flight_confirmed.png');
    }

    // 6. AVANZAMENTO CON COMANDO CONTINUA
    console.log('\n[6/8] Invio "continua" per avanzare...');
    await page.mouse.click(180, 805);
    await page.keyboard.type('continua', { delay: 50 });
    await page.keyboard.press('Enter');
    await page.waitForTimeout(8000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_06_attractions_stage.png') });
    console.log('✓ Screenshot avanzamento salvato: e2e_06_attractions_stage.png');

    // 7. AVANZAMENTO AD ALLOGGI E ITINERARIO
    console.log('\n[7/8] Invio "ottimo, procediamo" per passare all\'itinerario...');
    await page.mouse.click(180, 805);
    await page.keyboard.type('mostrami itinerario giorno per giorno con mappa', { delay: 50 });
    await page.keyboard.press('Enter');
    await page.waitForTimeout(10000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_07_itinerary_ready.png') });
    console.log('✓ Screenshot itinerario pronto salvato: e2e_07_itinerary_ready.png');

    // 8. APERTURA ITINERARIO COMPLETO (TripDetailsScreen)
    console.log('\n[8/8] Clic su Apri Itinerario & Mappa...');
    const openedDetails = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('*'));
      for (const el of els) {
        if (el.textContent && el.textContent.includes('Apri Itinerario & Mappa')) {
          el.click();
          return true;
        }
      }
      return false;
    });

    if (!openedDetails) {
      console.log('Ricerca card arancione itinerario pronto per coordinate...');
      // Trova la card e clicca
      await page.mouse.click(195, 680);
    }

    await page.waitForTimeout(4000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_08_trip_details.png') });
    console.log('✓ Screenshot TripDetailsScreen salvato: e2e_08_trip_details.png');

    // Scroll verso il basso per verificare le tappe e la mappa
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_09_trip_details_scrolled.png') });
    console.log('✓ Screenshot TripDetailsScreen scrolled salvato: e2e_09_trip_details_scrolled.png');

    console.log('\n=== RIEPILOGO TEST E2E ===');
    console.log('Errori di pagina rilevati:', pageErrors.length);
    if (pageErrors.length > 0) {
      console.log('Errori:', pageErrors);
    }
    console.log('Console logs rilevanti:', consoleLogs.filter(l => l.includes('error') || l.includes('Error') || l.includes('exception')));

  } catch (err) {
    console.error('ERRORE DURANTE ESECUZIONE E2E:', err);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'e2e_error.png') });
  } finally {
    await browser.close();
    console.log('=== TEST END-TO-END COMPLETATO ===');
  }
}

runE2ETest();
