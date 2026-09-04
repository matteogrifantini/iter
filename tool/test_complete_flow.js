const { chromium } = require('playwright-core');
const path = require('path');

const SCREENSHOT_DIR = '/Users/matteo/.gemini/antigravity/brain/f3aa63b5-4e13-4980-b36c-5bac8e3dbc71/.tempmediaStorage';
const TARGET_URL = 'https://iter-pi-fawn.vercel.app';

async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('=== AVVIO E2E COMPLETO ITER ===');
  const browser = await chromium.launch({ 
    headless: true, 
    channel: 'chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  });

  const page = await context.newPage();
  const logs = [];
  page.on('console', msg => logs.push(`[${msg.type()}] ${msg.text()}`));
  page.on('pageerror', err => console.error('PAGE ERROR:', err));

  try {
    // 1. CARICAMENTO HOME
    console.log('[1/8] Caricamento Home...');
    await page.goto(TARGET_URL, { waitUntil: 'networkidle', timeout: 30000 });
    await delay(3000);

    // Bypassa overlay video disabilitando pointer events sulle video view
    await page.evaluate(() => {
      document.querySelectorAll('video, flt-platform-view').forEach(el => {
        el.style.pointerEvents = 'none';
      });
    });

    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_01_home.png') });
    console.log('✓ Salvato flow_01_home.png');

    // 2. TAP SU ORGANIZZA NUOVO VIAGGIO
    console.log('[2/8] Tap su "Organizza un nuovo viaggio"...');
    await page.touchscreen.tap(195, 190);
    await delay(3000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_02_chat_welcome.png') });
    console.log('✓ Salvato flow_02_chat_welcome.png');

    // 3. INVIO DESTINAZIONE: TENERIFE
    console.log('[3/8] Invio richiesta Tenerife...');
    // Clic sul composer in fondo (campo input a y=960 circa o cerca l'input)
    const typedInInput = await page.evaluate(() => {
      const inputs = Array.from(document.querySelectorAll('input, textarea'));
      if (inputs.length > 0) {
        const inp = inputs[inputs.length - 1];
        inp.focus();
        inp.value = 'Voglio andare a Tenerife per 4 giorni a Maggio in coppia';
        inp.dispatchEvent(new Event('input', { bubbles: true }));
        return true;
      }
      return false;
    });

    if (!typedInInput) {
      console.log('Tapping input bar coordinate...');
      await page.touchscreen.tap(180, 810);
      await delay(500);
      await page.keyboard.type('Voglio andare a Tenerife per 4 giorni a Maggio in coppia', { delay: 30 });
    }
    await page.keyboard.press('Enter');

    console.log('Attesa risposta Gemini per Tenerife (12s)...');
    await delay(12000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_03_tenerife_hero.png') });
    console.log('✓ Salvato flow_03_tenerife_hero.png');

    // 4. VERIFICA PRESENZA ELEMENTI TENERIFE
    const hasTenerife = await page.evaluate(() => {
      return document.body.innerText.includes('Tenerife') || document.body.innerHTML.includes('Tenerife');
    });
    console.log('Tenerife presente nel body:', hasTenerife);

    // 5. RISPOSTA ALLE PREFERENZE VOLO
    console.log('[5/8] Risposta a preferenze volo...');
    const typedFlight = await page.evaluate(() => {
      const inputs = Array.from(document.querySelectorAll('input, textarea'));
      if (inputs.length > 0) {
        const inp = inputs[inputs.length - 1];
        inp.focus();
        inp.value = 'Volo diretto da Roma mattina presto, budget medio';
        inp.dispatchEvent(new Event('input', { bubbles: true }));
        return true;
      }
      return false;
    });
    if (!typedFlight) {
      await page.touchscreen.tap(180, 810);
      await delay(500);
      await page.keyboard.type('Volo diretto da Roma mattina presto, budget medio', { delay: 30 });
    }
    await page.keyboard.press('Enter');
    await delay(12000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_04_flights_stage.png') });
    console.log('✓ Salvato flow_04_flights_stage.png');

    // 6. SCROLL VERSO IL BASSO DELLA CHAT
    console.log('[6/8] Scroll chat verso il basso...');
    await page.mouse.wheel(0, 600);
    await delay(2000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_05_chat_scrolled.png') });
    console.log('✓ Salvato flow_05_chat_scrolled.png');

    // 7. AVANZAMENTO AD ATTRAZIONI E ITINERARIO
    console.log('[7/8] Richiesta attrazioni e programma...');
    const typedAttractions = await page.evaluate(() => {
      const inputs = Array.from(document.querySelectorAll('input, textarea'));
      if (inputs.length > 0) {
        const inp = inputs[inputs.length - 1];
        inp.focus();
        inp.value = 'Mi piacciono la natura e le spiagge, crea itinerario';
        inp.dispatchEvent(new Event('input', { bubbles: true }));
        return true;
      }
      return false;
    });
    if (!typedAttractions) {
      await page.touchscreen.tap(180, 810);
      await delay(500);
      await page.keyboard.type('Mi piacciono la natura e le spiagge, crea itinerario', { delay: 30 });
    }
    await page.keyboard.press('Enter');
    await delay(14000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_06_attractions_itinerary.png') });
    console.log('✓ Salvato flow_06_attractions_itinerary.png');

    // 8. SCROLL FINALE E ITINERARIO
    console.log('[8/8] Scroll finale per vedere card itinerario...');
    await page.mouse.wheel(0, 800);
    await delay(2000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_07_final_state.png') });
    console.log('✓ Salvato flow_07_final_state.png');

  } catch (e) {
    console.error('ERRORE NEL TEST:', e);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'flow_error.png') });
  } finally {
    await browser.close();
    console.log('=== TEST E2E TERMINATO ===');
  }
})();
