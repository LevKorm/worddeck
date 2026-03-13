const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'https://worddeck.vercel.app';
const OUT_DIR = path.join(__dirname);
const VIEWPORT = { width: 390, height: 844, deviceScaleFactor: 2 };

// All screens and states to capture
const SCREENS = [
  // ── Auth ──
  { name: '00_auth_login', url: '/', waitFor: '.login', loggedOut: true },

  // ── Translate ──
  { name: '01_translate_idle',   url: '/',       wait: 1500 },
  { name: '02_translate_typing', url: '/',       wait: 500, action: 'type' },
  { name: '03_translate_result', url: '/',       wait: 8000, action: 'translate' },

  // ── Vocabulary ──
  { name: '04_deck_list',        url: '/deck',   wait: 2000 },

  // ── Review ──
  { name: '05_review_idle',      url: '/review', wait: 2000 },
  { name: '06_review_card_front',url: '/review', wait: 2000, action: 'review_front' },
  { name: '07_review_card_back', url: '/review', wait: 2500, action: 'review_back' },

  // ── Word Detail ──
  { name: '08_word_detail',      url: '/deck',   wait: 3000, action: 'open_word' },

  // ── Stats ──
  { name: '09_stats',            url: '/stats',  wait: 1500 },

  // ── Settings ──
  { name: '10_settings',         url: '/settings', wait: 1500 },

  // ── Recent ──
  { name: '11_recent',           url: '/recent', wait: 1500 },
];

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function capture(page, name) {
  const file = path.join(OUT_DIR, `${name}.png`);
  await page.screenshot({ path: file, fullPage: false });
  console.log(`  ✓ ${name}.png`);
}

(async () => {
  console.log('Launching Chrome with your existing session...');

  const chromeUserDataDir = path.join(process.env.HOME, 'Library/Application Support/Google/Chrome');

  const browser = await puppeteer.launch({
    headless: false,
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    userDataDir: chromeUserDataDir,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--window-size=430,900',
      '--password-store=basic',
    ],
    defaultViewport: null,
  });

  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);
  // Emulate mobile device
  await page.emulate({
    name: 'iPhone 14',
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
    viewport: VIEWPORT,
  });

  // Navigate to app and check auth state
  console.log('\nChecking auth state...');
  await page.goto(BASE_URL, { waitUntil: 'networkidle2', timeout: 30000 });
  await sleep(2000);

  const currentUrl = page.url();
  console.log('Current URL:', currentUrl);

  const isLoggedIn = !currentUrl.includes('login') && !currentUrl.includes('auth');
  console.log('Logged in:', isLoggedIn);

  if (!isLoggedIn) {
    await capture(page, '00_auth_login');
    console.log('\n⚠️  Not logged in. A Chrome window is open.');
    console.log('   → Sign in with Google in the browser window');
    console.log('   → Once you reach the app, come back here and press ENTER');
    await new Promise(resolve => {
      process.stdin.resume();
      process.stdin.once('data', resolve);
    });
    process.stdin.pause();
    await sleep(2000);
    const urlAfter = page.url();
    console.log('URL after login:', urlAfter);
    if (urlAfter.includes('login') || urlAfter.includes('auth')) {
      console.log('Still not logged in. Exiting.');
      await browser.close();
      return;
    }
    console.log('Logged in! Continuing capture...\n');
  }

  console.log('\nCapturing screens...\n');

  // ── 01 Translate idle ──
  await page.goto(`${BASE_URL}/`, { waitUntil: 'networkidle2' });
  await sleep(2000);
  await capture(page, '01_translate_idle');

  // ── 02 Translate typing ──
  await page.goto(`${BASE_URL}/`, { waitUntil: 'networkidle2' });
  await sleep(1000);
  // Click the text field
  await page.click('body');
  await sleep(300);
  // Try to find and focus the input
  try {
    const inputs = await page.$$('input[type="text"], textarea, [contenteditable]');
    if (inputs.length > 0) {
      await inputs[0].click();
      await sleep(300);
      await inputs[0].type('verlegen', { delay: 80 });
      await sleep(500);
    }
  } catch (e) {}
  await capture(page, '02_translate_typing');

  // ── 03 Translate result ──
  // Press Enter to submit
  try {
    await page.keyboard.press('Enter');
    await sleep(6000); // wait for translation + enrichment
  } catch (e) {}
  await capture(page, '03_translate_result');

  // ── 04 Deck / Vocabulary ──
  await page.goto(`${BASE_URL}/deck`, { waitUntil: 'networkidle2' });
  await sleep(2000);
  await capture(page, '04_deck_list');

  // ── 05 Review idle ──
  await page.goto(`${BASE_URL}/review`, { waitUntil: 'networkidle2' });
  await sleep(2000);
  await capture(page, '05_review_idle');

  // ── 06 Review card front (first card) ──
  try {
    // Check if there are cards, tap first one
    await sleep(500);
    await capture(page, '06_review_card_front');
  } catch (e) {}

  // ── 07 Review card back (tap to flip) ──
  try {
    await page.click('body');
    await sleep(800);
    await capture(page, '07_review_card_back');
  } catch (e) {}

  // ── 08 Word detail (tap first card in deck) ──
  await page.goto(`${BASE_URL}/deck`, { waitUntil: 'networkidle2' });
  await sleep(2000);
  try {
    // Click the first word card
    const cards = await page.$$('[class*="word"], [class*="card"], li, [role="listitem"]');
    if (cards.length > 0) {
      await cards[0].click();
      await sleep(1500);
    }
  } catch (e) {}
  await capture(page, '08_word_detail');

  // ── 09 Stats ──
  await page.goto(`${BASE_URL}/stats`, { waitUntil: 'networkidle2' });
  await sleep(1500);
  await capture(page, '09_stats');

  // ── 10 Settings ──
  await page.goto(`${BASE_URL}/settings`, { waitUntil: 'networkidle2' });
  await sleep(1500);
  await capture(page, '10_settings');

  // ── 11 Recent ──
  await page.goto(`${BASE_URL}/recent`, { waitUntil: 'networkidle2' });
  await sleep(1500);
  await capture(page, '11_recent');

  await browser.close();

  console.log('\n✅ Done! Screenshots saved to:');
  console.log(`   ${OUT_DIR}`);
  const files = fs.readdirSync(OUT_DIR).filter(f => f.endsWith('.png'));
  console.log(`   ${files.length} files captured`);
})();
