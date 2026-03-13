// WordDeck Design System — Figma Plugin
// Generates all screens, color styles, and text styles

// ── Color palette (RGB 0-1) ────────────────────────────────────────────────
const C = {
  bg:          { r: 0.051, g: 0.051, b: 0.051 },
  cardBlack:   { r: 0.075, g: 0.075, b: 0.075 },
  surface:     { r: 0.118, g: 0.118, b: 0.118 },
  surface2:    { r: 0.165, g: 0.165, b: 0.165 },
  surface3:    { r: 0.200, g: 0.200, b: 0.200 },
  accent:      { r: 0.910, g: 0.659, b: 0.220 },
  accentDim:   { r: 0.910, g: 0.659, b: 0.220 },
  indigo:      { r: 0.388, g: 0.400, b: 0.945 },
  indigoDim:   { r: 0.388, g: 0.400, b: 0.945 },
  green:       { r: 0.290, g: 0.871, b: 0.502 },
  greenDim:    { r: 0.290, g: 0.871, b: 0.502 },
  red:         { r: 0.973, g: 0.443, b: 0.443 },
  redDim:      { r: 0.973, g: 0.443, b: 0.443 },
  text:        { r: 0.941, g: 0.925, b: 0.894 },
  textMuted:   { r: 0.620, g: 0.604, b: 0.573 },
  textDim:     { r: 0.420, g: 0.404, b: 0.376 },
  ratingAgain: { r: 0.973, g: 0.443, b: 0.443 },
  ratingHard:  { r: 0.984, g: 0.749, b: 0.141 },
  ratingGood:  { r: 0.290, g: 0.871, b: 0.502 },
  ratingEasy:  { r: 0.376, g: 0.647, b: 0.980 },
  white:       { r: 1.000, g: 1.000, b: 1.000 },
  black:       { r: 0.000, g: 0.000, b: 0.000 },
};

function fill(color, opacity = 1) {
  return [{ type: 'SOLID', color: { r: color.r, g: color.g, b: color.b }, opacity }];
}

// ── Font loading ───────────────────────────────────────────────────────────
async function loadFonts() {
  const fonts = [
    { family: 'DM Sans', style: 'Regular' },
    { family: 'DM Sans', style: 'Medium' },
    { family: 'DM Sans', style: 'SemiBold' },
    { family: 'DM Sans', style: 'Bold' },
    { family: 'Inter',   style: 'Regular' },
  ];
  for (const f of fonts) {
    try { await figma.loadFontAsync(f); } catch (e) {}
  }
  // JetBrains Mono fallback
  try {
    await figma.loadFontAsync({ family: 'JetBrains Mono', style: 'Regular' });
    await figma.loadFontAsync({ family: 'JetBrains Mono', style: 'SemiBold' });
  } catch (e) {
    // fallback — use DM Sans if JetBrains Mono not available
  }
}

// ── Primitive builders ─────────────────────────────────────────────────────
function makeFrame(name, w, h, bg = C.bg) {
  const f = figma.createFrame();
  f.name = name;
  f.resize(w, h);
  f.fills = fill(bg);
  f.clipsContent = true;
  return f;
}

function rect(parent, name, x, y, w, h, color, opacity = 1, radius = 0) {
  const r = figma.createRectangle();
  r.name = name;
  r.resize(w, h);
  r.fills = fill(color, opacity);
  if (radius > 0) r.cornerRadius = radius;
  r.x = x; r.y = y;
  parent.appendChild(r);
  return r;
}

function text(parent, content, x, y, size, weight, color, opacity = 1, mono = false) {
  const t = figma.createText();
  t.characters = content;
  t.fontSize = size;
  try {
    t.fontName = mono
      ? { family: 'JetBrains Mono', style: weight }
      : { family: 'DM Sans', style: weight };
  } catch (e) {
    t.fontName = { family: 'DM Sans', style: weight };
  }
  t.fills = fill(color, opacity);
  t.x = x; t.y = y;
  parent.appendChild(t);
  return t;
}

function label(parent, content, x, y) {
  return text(parent, content, x, y, 11, 'SemiBold', C.textDim);
}

function divider(parent, x, y, w) {
  return rect(parent, 'divider', x, y, w, 1, C.surface3);
}

// ── Color Styles ───────────────────────────────────────────────────────────
function createColorStyles() {
  const defs = [
    ['Backgrounds/bg',        C.bg,       1],
    ['Backgrounds/cardBlack', C.cardBlack,1],
    ['Backgrounds/surface',   C.surface,  1],
    ['Backgrounds/surface2',  C.surface2, 1],
    ['Backgrounds/surface3',  C.surface3, 1],
    ['Brand/accent',          C.accent,   1],
    ['Brand/accentDim',       C.accent,   0.15],
    ['Functional/indigo',     C.indigo,   1],
    ['Functional/indigoDim',  C.indigo,   0.15],
    ['Functional/green',      C.green,    1],
    ['Functional/greenDim',   C.green,    0.12],
    ['Functional/red',        C.red,      1],
    ['Functional/redDim',     C.red,      0.15],
    ['Text/text',             C.text,     1],
    ['Text/textMuted',        C.textMuted,1],
    ['Text/textDim',          C.textDim,  1],
    ['Rating/again',          C.ratingAgain, 1],
    ['Rating/hard',           C.ratingHard,  1],
    ['Rating/good',           C.ratingGood,  1],
    ['Rating/easy',           C.ratingEasy,  1],
  ];
  for (const [name, color, opacity] of defs) {
    const s = figma.createPaintStyle();
    s.name = `WordDeck/${name}`;
    s.paints = [{ type: 'SOLID', color, opacity }];
  }
}

// ── Text Styles ────────────────────────────────────────────────────────────
async function createTextStyles() {
  const defs = [
    ['headlineLarge',   'DM Sans', 'Bold',     32, C.text,      1.2, 0],
    ['headlineMedium',  'DM Sans', 'SemiBold', 22, C.text,      1.3, 0],
    ['titleLarge',      'DM Sans', 'SemiBold', 20, C.text,      1.4, 0],
    ['titleMedium',     'DM Sans', 'SemiBold', 16, C.text,      1.4, 0],
    ['titleSmall',      'DM Sans', 'SemiBold', 14, C.text,      1.4, 0],
    ['bodyLarge',       'DM Sans', 'Regular',  16, C.text,      1.5, 0],
    ['bodyMedium',      'DM Sans', 'Regular',  14, C.text,      1.5, 0],
    ['bodySmall',       'DM Sans', 'Regular',  12, C.textMuted, 1.4, 0],
    ['labelLarge',      'DM Sans', 'SemiBold', 14, C.text,      1.4, 0],
    ['labelMedium',     'DM Sans', 'Medium',   13, C.textMuted, 1.4, 0],
    ['labelSmall',      'DM Sans', 'SemiBold', 11, C.textMuted, 1.4, 0.8],
    ['slideWordHero',   'DM Sans', 'Bold',     36, C.white,     1.2, 0],
    ['slideTranslation','DM Sans', 'Regular',  18, C.white,     1.3, 0],
    ['slideTypeLabel',  'DM Sans', 'SemiBold', 10, C.white,     1.4, 1.0],
  ];
  for (const [name, family, style, size, color, lh, ls] of defs) {
    try {
      const ts = figma.createTextStyle();
      ts.name = `WordDeck/${name}`;
      ts.fontName = { family, style };
      ts.fontSize = size;
      ts.fills = [{ type: 'SOLID', color }];
      ts.lineHeight = { unit: 'PERCENT', value: lh * 100 };
      if (ls !== 0) ts.letterSpacing = { unit: 'PIXELS', value: ls };
    } catch (e) {}
  }
}

// ── Floating Nav bar ───────────────────────────────────────────────────────
function buildFloatingNav(screen, activeTab) {
  const safeBottom = 34;
  const navH = 56;
  const navY = 844 - safeBottom - 12 - navH;

  // Fade gradient overlay
  const fade = figma.createRectangle();
  fade.name = 'nav-fade';
  fade.resize(390, 110);
  fade.x = 0; fade.y = 844 - 110;
  fade.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[0, 1, 0], [-1, 0, 1]],
    gradientStops: [
      { position: 0, color: { r: 0.051, g: 0.051, b: 0.051, a: 0 } },
      { position: 1, color: { r: 0.051, g: 0.051, b: 0.051, a: 1 } },
    ],
  }];
  screen.appendChild(fade);

  // Nav pill background
  const navBg = rect(screen, 'floating-nav', 24, navY, 342, navH, C.surface, 1, 999);
  navBg.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.5 }];
  navBg.strokeWeight = 0.5;

  const tabs = ['Translate', 'Vocabulary', 'Review'];
  const tabW = 342 / 3;

  tabs.forEach((tab, i) => {
    const isActive = i + 1 === activeTab;
    const tabX = 24 + i * tabW;
    const centerX = tabX + tabW / 2;

    if (isActive) {
      const activeBg = rect(screen, `${tab}-active`, centerX - 28, navY + 10, 56, 30, C.accent, 0.15, 15);
    }

    const icons = ['◎', '☰', '↻'];
    const iconT = text(screen, icons[i], centerX - 6, navY + 14, 16, 'Regular', isActive ? C.accent : C.textMuted);
    const labelT = text(screen, tab, centerX - tab.length * 3, navY + 34, 9, 'Medium', isActive ? C.accent : C.textMuted);
  });
}

// ── SCREEN 1: Translate — Idle ─────────────────────────────────────────────
function buildTranslateIdle(x) {
  const screen = makeFrame('01 · Translate — Idle', 390, 844);
  screen.x = x;

  // Card shell
  const cardH = Math.round(844 * 0.73); // 617px
  const card = rect(screen, 'card-shell', 0, 0, 390, cardH, C.cardBlack);
  card.bottomLeftRadius = 20;
  card.bottomRightRadius = 20;

  // Stat pills row
  const statY = 58;
  const statWordsBg = rect(screen, 'stat/words-bg', 20, statY, 80, 28, C.green, 0.12, 14);
  text(screen, '12 words', 30, statY + 7, 11, 'SemiBold', C.green);

  const statDueBg = rect(screen, 'stat/due-bg', 108, statY, 60, 28, C.surface2, 1, 14);
  text(screen, '3 due', 118, statY + 7, 11, 'SemiBold', C.textMuted);

  const statStreakBg = rect(screen, 'stat/streak-bg', 176, statY, 64, 28, C.accent, 0.15, 14);
  text(screen, '5 day 🔥', 184, statY + 7, 11, 'SemiBold', C.accent);

  // Settings icon (top right)
  text(screen, '⚙', 348, statY + 3, 20, 'Regular', C.textMuted);

  // Large input hint
  text(screen, 'Word or phrase...', 20, 176, 28, 'Medium', C.textDim, 0.6);

  // Collection selector (bottom of card)
  const collY = cardH - 116;
  rect(screen, 'collection-selector/bg', 20, collY, 136, 34, C.surface2, 1, 17);
  text(screen, '+ Collection', 32, collY + 9, 13, 'Medium', C.textMuted);

  // Submit arrow button
  const arrowX = 390 - 20 - 44;
  const arrowY = cardH - 72;
  rect(screen, 'submit-btn', arrowX, arrowY, 44, 44, C.accent, 1, 22);
  text(screen, '↑', arrowX + 14, arrowY + 9, 22, 'Bold', C.black);

  // Language selector (below card)
  const langY = cardH + 20;

  // Learn language
  text(screen, 'English', 20, langY, 15, 'Medium', C.text);
  text(screen, 'Learn', 20, langY + 20, 11, 'Regular', C.textDim);

  // Swap button
  rect(screen, 'swap-btn', 390 / 2 - 19, langY + 2, 38, 38, C.surface2, 1, 19);
  text(screen, '⇄', 390 / 2 - 8, langY + 12, 16, 'Regular', C.textMuted);

  // Native language (right-aligned)
  text(screen, 'Ukrainian', 280, langY, 15, 'Medium', C.text);
  text(screen, 'Fluent', 298, langY + 20, 11, 'Regular', C.textDim);

  // Recent strip
  const recentY = cardH + 80;
  text(screen, 'Recent', 20, recentY, 13, 'SemiBold', C.textMuted);

  const recentWords = [
    { word: 'verlegen', trans: 'embarrassed' },
    { word: 'gezellig', trans: 'cozy' },
    { word: 'uitstekend', trans: 'excellent' },
    { word: 'schildpad', trans: 'turtle' },
  ];
  recentWords.forEach((w, i) => {
    const rx = 20 + i * 90;
    const rb = rect(screen, `recent/${w.word}`, rx, recentY + 20, 80, 64, C.surface2, 1, 10);
    rb.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.5 }];
    rb.strokeWeight = 0.5;
    text(screen, w.word, rx + 8, recentY + 30, 12, 'SemiBold', C.text);
    text(screen, w.trans, rx + 8, recentY + 46, 10, 'Regular', C.textMuted);
  });

  buildFloatingNav(screen, 1);
  return screen;
}

// ── SCREEN 2: Translate — Typing ──────────────────────────────────────────
function buildTranslateTyping(x) {
  const screen = makeFrame('02 · Translate — Typing', 390, 844);
  screen.x = x;

  // Card shrinks to leave room for keyboard
  const keyboardH = 336;
  const cardH = 844 - keyboardH;
  const card = rect(screen, 'card-shell', 0, 0, 390, cardH, C.cardBlack);
  card.bottomLeftRadius = 20;
  card.bottomRightRadius = 20;

  // Typed text (larger, typing state)
  text(screen, 'verlegen', 20, 60, 32, 'Bold', C.text);

  // Cursor line
  rect(screen, 'cursor', 20 + 32 * 5, 60, 2, 36, C.accent);

  // Submit button
  rect(screen, 'submit-btn', 390 - 20 - 44, cardH - 72, 44, 44, C.accent, 1, 22);
  text(screen, '↑', 390 - 20 - 44 + 14, cardH - 72 + 9, 22, 'Bold', C.black);

  // Keyboard placeholder
  rect(screen, 'keyboard', 0, 844 - keyboardH, 390, keyboardH, C.surface2);
  text(screen, 'System Keyboard', 390 / 2 - 60, 844 - keyboardH + keyboardH / 2 - 10, 14, 'Regular', C.textDim);

  return screen;
}

// ── SCREEN 3: Translate — Loading (shimmer) ───────────────────────────────
function buildTranslateLoading(x) {
  const screen = makeFrame('03 · Translate — Loading', 390, 844);
  screen.x = x;

  const card = rect(screen, 'card-shell', 0, 0, 390, 844, C.cardBlack);
  card.bottomLeftRadius = 20;
  card.bottomRightRadius = 20;

  // Shimmer blocks
  const shimmerColor = C.surface2;
  text(screen, 'verlegen', 24, 70, 32, 'Bold', C.text);

  rect(screen, 'shimmer/transcription', 24, 115, 140, 18, shimmerColor, 1, 9);
  rect(screen, 'shimmer/translation-box', 24, 148, 342, 64, shimmerColor, 1, 16);
  rect(screen, 'shimmer/synonyms-label', 24, 232, 60, 12, shimmerColor, 1, 6);
  rect(screen, 'shimmer/chip-1', 24, 252, 100, 28, shimmerColor, 1, 14);
  rect(screen, 'shimmer/chip-2', 132, 252, 90, 28, shimmerColor, 1, 14);
  rect(screen, 'shimmer/chip-3', 230, 252, 80, 28, shimmerColor, 1, 14);
  rect(screen, 'shimmer/example-label', 24, 300, 60, 12, shimmerColor, 1, 6);
  rect(screen, 'shimmer/example', 24, 320, 300, 16, shimmerColor, 1, 8);
  rect(screen, 'shimmer/usage-label', 24, 356, 50, 12, shimmerColor, 1, 6);
  rect(screen, 'shimmer/usage-1', 24, 376, 342, 14, shimmerColor, 1, 7);
  rect(screen, 'shimmer/usage-2', 24, 398, 260, 14, shimmerColor, 1, 7);

  // Loading indicator
  text(screen, 'Enriching with AI...', 24, 450, 13, 'Regular', C.textDim);

  buildFloatingNav(screen, 1);
  return screen;
}

// ── SCREEN 4: Translate — Result ──────────────────────────────────────────
function buildTranslateResult(x) {
  const screen = makeFrame('04 · Translate — Result', 390, 844);
  screen.x = x;

  const card = rect(screen, 'card-shell', 0, 0, 390, 844, C.cardBlack);
  card.bottomLeftRadius = 20;
  card.bottomRightRadius = 20;

  // Word
  text(screen, 'verlegen', 24, 70, 32, 'Bold', C.text);
  text(screen, '/fɛrˈleːɣən/', 24, 115, 14, 'Regular', C.textMuted, 1, true);

  // Translation box (amber gradient)
  const transBox = rect(screen, 'translation-box', 24, 148, 342, 64, C.accent, 1, 16);
  text(screen, 'embarrassed', 40, 167, 20, 'SemiBold', C.black);

  // Eye / spoiler icon
  text(screen, '👁', 332, 162, 18, 'Regular', C.black, 0.6);

  // LangToggle + CollectionSelector row
  const rowY = 225;
  rect(screen, 'lang-toggle/bg', 24, rowY, 80, 30, C.surface2, 1, 15);
  text(screen, 'NL → EN', 32, rowY + 8, 12, 'Medium', C.textMuted);

  rect(screen, 'collection-selector/bg', 116, rowY, 130, 30, C.surface2, 1, 15);
  text(screen, '📂 My Words', 124, rowY + 8, 12, 'Medium', C.textMuted);

  // Synonyms
  label(screen, 'SYNONYMS', 24, 270);
  const synWords = ['beschaamd', 'schaapachtig', 'bedremmeld'];
  let synX = 24;
  synWords.forEach(s => {
    const cw = s.length * 7.5 + 20;
    const chip = rect(screen, `chip/${s}`, synX, 288, cw, 30, C.surface2, 1, 15);
    chip.strokes = [{ type: 'SOLID', color: C.accent, opacity: 0.3 }];
    chip.strokeWeight = 0.5;
    text(screen, s, synX + 10, 295, 13, 'Medium', C.accent);
    synX += cw + 6;
  });

  // Example sentence
  label(screen, 'EXAMPLE', 24, 336);
  text(screen, 'Hij werd verlegen toen hij haar zag.', 24, 354, 14, 'Regular', C.text);

  // Usage notes
  label(screen, 'USAGE NOTES', 24, 388);
  text(screen, 'Used for social embarrassment. Register:', 24, 406, 13, 'Regular', C.textMuted);
  text(screen, 'informal. Softer than "beschaamd".', 24, 424, 13, 'Regular', C.textMuted);

  // Did you know
  label(screen, 'ETYMOLOGY', 24, 460);
  text(screen, 'From Middle Dutch "verlegen" — to', 24, 478, 13, 'Regular', C.textMuted);
  text(screen, 'lay aside, to be at a loss.', 24, 496, 13, 'Regular', C.textMuted);

  divider(screen, 24, 526, 342);

  // Save button
  rect(screen, 'save-btn', 24, 546, 342, 52, C.accent, 1, 16);
  text(screen, 'Save to Vocabulary', 110, 559, 14, 'SemiBold', C.black);

  buildFloatingNav(screen, 1);
  return screen;
}

// ── SCREEN 5: Translate — Saved ───────────────────────────────────────────
function buildTranslateSaved(x) {
  const screen = makeFrame('05 · Translate — Saved ✓', 390, 844);
  screen.x = x;

  const card = rect(screen, 'card-shell', 0, 0, 390, 844, C.cardBlack);
  card.bottomLeftRadius = 20;
  card.bottomRightRadius = 20;

  text(screen, 'verlegen', 24, 70, 32, 'Bold', C.text);
  text(screen, '/fɛrˈleːɣən/', 24, 115, 14, 'Regular', C.textMuted, 1, true);

  rect(screen, 'translation-box', 24, 148, 342, 64, C.accent, 1, 16);
  text(screen, 'embarrassed', 40, 167, 20, 'SemiBold', C.black);

  // Green "Saved" bubble
  const savedBg = rect(screen, 'saved-bubble', 24, 226, 342, 48, C.green, 0.12, 16);
  savedBg.strokes = [{ type: 'SOLID', color: C.green, opacity: 0.3 }];
  savedBg.strokeWeight = 0.5;
  text(screen, '✓  Saved to your vocabulary', 80, 239, 14, 'SemiBold', C.green);

  // Synonyms
  label(screen, 'SYNONYMS', 24, 292);
  const synWords = ['beschaamd', 'schaapachtig', 'bedremmeld'];
  let synX = 24;
  synWords.forEach(s => {
    const cw = s.length * 7.5 + 20;
    rect(screen, `chip/${s}`, synX, 310, cw, 30, C.surface2, 1, 15);
    text(screen, s, synX + 10, 317, 13, 'Medium', C.accent);
    synX += cw + 6;
  });

  label(screen, 'EXAMPLE', 24, 358);
  text(screen, 'Hij werd verlegen toen hij haar zag.', 24, 376, 14, 'Regular', C.text);

  buildFloatingNav(screen, 1);
  return screen;
}

// ── SCREEN 6: Vocabulary / Deck ───────────────────────────────────────────
function buildDeck(x) {
  const screen = makeFrame('06 · Vocabulary', 390, 844);
  screen.x = x;

  // AppBar
  rect(screen, 'word-count-badge', 20, 54, 80, 32, C.indigo, 0.15, 16);
  text(screen, '☰ 12 words', 30, 62, 12, 'SemiBold', C.indigo);
  text(screen, '⚙', 350, 56, 20, 'Regular', C.textMuted);

  // Search
  rect(screen, 'search-bar', 20, 98, 350, 44, C.surface, 1, 16);
  text(screen, '🔍  Search words...', 36, 111, 14, 'Regular', C.textDim);

  // Filter chips
  const filters = ['All', 'Learning', 'Mastered', 'New'];
  let fx = 20;
  filters.forEach((f, i) => {
    const fw = f.length * 8 + 20;
    const isActive = i === 0;
    rect(screen, `filter/${f}`, fx, 154, fw, 28, isActive ? C.accent : C.surface2, isActive ? 1 : 1, 14);
    text(screen, f, fx + 8, 161, 12, isActive ? 'SemiBold' : 'Regular', isActive ? C.black : C.textMuted);
    fx += fw + 6;
  });

  // Word cards
  const cards = [
    { word: 'verlegen',    trans: 'embarrassed',    status: 'learning', next: '2d' },
    { word: 'gezellig',    trans: 'cozy, convivial', status: 'mastered', next: '21d' },
    { word: 'uitstekend',  trans: 'excellent',       status: 'learning', next: '5d' },
    { word: 'bevatten',    trans: 'to contain',      status: 'pending',  next: 'new' },
    { word: 'schildpad',   trans: 'turtle',          status: 'mastered', next: '30d' },
    { word: 'geweldig',    trans: 'amazing, great',  status: 'learning', next: '3d' },
    { word: 'begrijpen',   trans: 'to understand',   status: 'pending',  next: 'new' },
    { word: 'herinneren',  trans: 'to remember',     status: 'learning', next: '8d' },
  ];

  const statusColor = { learning: C.accent, mastered: C.green, pending: C.textMuted };

  cards.forEach((c, i) => {
    const cy = 196 + i * 70;
    if (cy > 780) return;
    const cardBg = rect(screen, `card/${c.word}`, 20, cy, 350, 60, C.surface, 1, 12);
    cardBg.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.4 }];
    cardBg.strokeWeight = 0.5;
    text(screen, c.word, 36, cy + 10, 15, 'SemiBold', C.text);
    text(screen, c.trans, 36, cy + 32, 13, 'Regular', C.textMuted);
    const sc = statusColor[c.status];
    rect(screen, 'status-dot', 345, cy + 16, 6, 6, sc, 1, 3);
    text(screen, c.next, 320, cy + 30, 11, 'Regular', C.textDim, 1, true);
    // layers icon (saved indicator)
    text(screen, '◫', 350, cy + 10, 14, 'Regular', C.indigo, 0.7);
  });

  buildFloatingNav(screen, 2);
  return screen;
}

// ── SCREEN 7: Review — Card Front ─────────────────────────────────────────
function buildReviewFront(x) {
  const screen = makeFrame('07 · Review — Card Front', 390, 844);
  screen.x = x;

  // Progress bar
  rect(screen, 'progress-bg', 20, 56, 300, 4, C.surface2, 1, 2);
  rect(screen, 'progress-fill', 20, 56, 125, 4, C.accent, 1, 2);
  text(screen, '5 / 12', 334, 50, 11, 'Regular', C.textMuted, 1, true);

  // Flashcard
  const cY = 80;
  const cardBg = rect(screen, 'flashcard', 20, cY, 350, 380, C.cardBlack, 1, 20);
  cardBg.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.5 }];
  cardBg.strokeWeight = 0.5;

  text(screen, 'verlegen', 390 / 2 - 64, cY + 120, 34, 'Bold', C.text);
  text(screen, '/fɛrˈleːɣən/', 390 / 2 - 58, cY + 165, 14, 'Regular', C.textMuted, 1, true);

  // Synonym chips
  label(screen, 'SYNONYMS', 36, cY + 220);
  const chips = ['beschaamd', 'schaapachtig'];
  let cx = 36;
  chips.forEach(s => {
    const cw = s.length * 7 + 18;
    rect(screen, `chip/${s}`, cx, cY + 238, cw, 28, C.surface2, 1, 14);
    text(screen, s, cx + 8, cY + 244, 12, 'Medium', C.accent);
    cx += cw + 6;
  });

  text(screen, 'Tap to reveal', 390 / 2 - 44, cY + 330, 13, 'Regular', C.textDim);

  // Rating buttons (grayed — card not flipped yet)
  const ratings = [
    { label: 'Again', color: C.ratingAgain },
    { label: 'Hard',  color: C.ratingHard  },
    { label: 'Good',  color: C.ratingGood  },
    { label: 'Easy',  color: C.ratingEasy  },
  ];
  const btnW = 80; const gap = 6;
  const totalW = ratings.length * btnW + (ratings.length - 1) * gap;
  const startX = (390 - totalW) / 2;
  ratings.forEach((r, i) => {
    const bx = startX + i * (btnW + gap);
    rect(screen, `btn/${r.label}`, bx, 496, btnW, 52, r.color, 0.08, 14);
    text(screen, r.label, bx + btnW / 2 - r.label.length * 3.5, 517, 13, 'SemiBold', r.color, 0.4);
  });

  buildFloatingNav(screen, 3);
  return screen;
}

// ── SCREEN 8: Review — Card Back (revealed) ───────────────────────────────
function buildReviewBack(x) {
  const screen = makeFrame('08 · Review — Card Back', 390, 844);
  screen.x = x;

  rect(screen, 'progress-bg', 20, 56, 300, 4, C.surface2, 1, 2);
  rect(screen, 'progress-fill', 20, 56, 125, 4, C.accent, 1, 2);
  text(screen, '5 / 12', 334, 50, 11, 'Regular', C.textMuted, 1, true);

  const cY = 80;
  const cardBg = rect(screen, 'flashcard', 20, cY, 350, 380, C.cardBlack, 1, 20);
  cardBg.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.5 }];
  cardBg.strokeWeight = 0.5;

  text(screen, 'verlegen', 390 / 2 - 64, cY + 40, 34, 'Bold', C.text);
  text(screen, '/fɛrˈleːɣən/', 390 / 2 - 58, cY + 85, 14, 'Regular', C.textMuted, 1, true);

  // Revealed translation box
  rect(screen, 'translation-box', 36, cY + 114, 318, 56, C.accent, 1, 14);
  text(screen, 'embarrassed', 84, cY + 130, 20, 'SemiBold', C.black);

  label(screen, 'EXAMPLE', 36, cY + 186);
  text(screen, 'Hij werd verlegen toen hij haar zag.', 36, cY + 204, 13, 'Regular', C.text);

  label(screen, 'USAGE', 36, cY + 240);
  text(screen, 'Social embarrassment. Softer than "beschaamd".', 36, cY + 258, 12, 'Regular', C.textMuted);

  // Rating buttons (active)
  const ratings = [
    { label: 'Again', color: C.ratingAgain },
    { label: 'Hard',  color: C.ratingHard  },
    { label: 'Good',  color: C.ratingGood  },
    { label: 'Easy',  color: C.ratingEasy  },
  ];
  const btnW = 80; const gap = 6;
  const totalW = ratings.length * btnW + (ratings.length - 1) * gap;
  const startX = (390 - totalW) / 2;
  ratings.forEach((r, i) => {
    const bx = startX + i * (btnW + gap);
    rect(screen, `btn/${r.label}`, bx, 496, btnW, 52, r.color, 0.15, 14);
    text(screen, r.label, bx + btnW / 2 - r.label.length * 3.5, 517, 13, 'SemiBold', r.color);
  });

  buildFloatingNav(screen, 3);
  return screen;
}

// ── SCREEN 9: Word Detail ──────────────────────────────────────────────────
function buildWordDetail(x) {
  const screen = makeFrame('09 · Word Detail', 390, 844);
  screen.x = x;

  // Drag handle
  rect(screen, 'handle', 175, 12, 40, 4, C.surface3, 1, 2);

  // Back / close
  text(screen, '←', 20, 34, 20, 'Regular', C.textMuted);

  text(screen, 'verlegen', 24, 56, 28, 'Bold', C.text);
  text(screen, 'From "gezellig"', 24, 94, 12, 'Regular', C.indigo); // breadcrumb
  text(screen, '/fɛrˈleːɣən/', 24, 112, 14, 'Regular', C.textMuted, 1, true);

  // Translation box
  rect(screen, 'translation-box', 24, 142, 342, 60, C.accent, 1, 16);
  text(screen, 'embarrassed', 40, 159, 20, 'SemiBold', C.black);
  text(screen, '👁', 332, 156, 18, 'Regular', C.black, 0.5);

  // LangToggle + CollectionSelector
  rect(screen, 'lang-toggle/bg', 24, 214, 76, 28, C.surface2, 1, 14);
  text(screen, 'NL→EN', 32, 221, 11, 'Medium', C.textMuted);
  rect(screen, 'collection/bg', 108, 214, 110, 28, C.surface2, 1, 14);
  text(screen, '📂 My Words', 116, 221, 11, 'Medium', C.textMuted);

  let sy = 258;

  // Synonyms
  label(screen, 'SYNONYMS', 24, sy); sy += 22;
  const synWords = ['beschaamd', 'schaapachtig', 'bedremmeld'];
  let scx = 24;
  synWords.forEach(s => {
    const cw = s.length * 7.5 + 20;
    const chip = rect(screen, `chip/${s}`, scx, sy, cw, 30, C.surface2, 1, 15);
    chip.strokes = [{ type: 'SOLID', color: C.accent, opacity: 0.3 }];
    chip.strokeWeight = 0.5;
    text(screen, s, scx + 10, sy + 7, 13, 'Medium', C.accent);
    scx += cw + 6;
  });
  sy += 44;

  // Example
  label(screen, 'EXAMPLE SENTENCE', 24, sy); sy += 20;
  text(screen, 'Hij werd verlegen toen hij haar zag.', 24, sy, 14, 'Regular', C.text);
  sy += 40;
  text(screen, 'He became embarrassed when he saw her.', 24, sy, 13, 'Regular', C.textMuted);
  sy += 40;

  // Usage notes
  label(screen, 'USAGE NOTES', 24, sy); sy += 20;
  text(screen, 'Used for social embarrassment. Register:', 24, sy, 13, 'Regular', C.text);
  sy += 20;
  text(screen, 'informal. Softer than "beschaamd".', 24, sy, 13, 'Regular', C.textMuted);
  sy += 36;

  // SM-2 info
  const smBg = rect(screen, 'sm2-info', 24, sy, 342, 56, C.surface, 1, 12);
  smBg.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.4 }];
  smBg.strokeWeight = 0.5;
  text(screen, 'Next review: 2 days  ·  Learning  ·  3×', 36, sy + 11, 13, 'Regular', C.textMuted);
  text(screen, 'Ease: 2.5  ·  Interval: 2d', 36, sy + 30, 12, 'Regular', C.textDim);

  return screen;
}

// ── SCREEN 10: Stats ───────────────────────────────────────────────────────
function buildStats(x) {
  const screen = makeFrame('10 · Stats', 390, 844);
  screen.x = x;

  text(screen, '← Stats', 20, 56, 20, 'SemiBold', C.text);

  // 2×2 stat cards
  const statCards = [
    { label: 'Total Words',    value: '12',  color: C.green,  dim: C.green  },
    { label: 'Reviews Today',  value: '8',   color: C.indigo, dim: C.indigo },
    { label: 'Current Streak', value: '5d',  color: C.accent, dim: C.accent },
    { label: 'Daily Goal',     value: '20',  color: C.textMuted, dim: C.textMuted },
  ];
  statCards.forEach((sc, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const cw = 168; const ch = 96;
    const cx = 20 + col * (cw + 10);
    const cy = 100 + row * (ch + 10);
    rect(screen, `stat/${sc.label}`, cx, cy, cw, ch, sc.dim, 0.1, 16);
    text(screen, sc.value, cx + 16, cy + 16, 32, 'Bold', sc.color, 1, true);
    text(screen, sc.label, cx + 16, cy + 66, 12, 'Medium', C.textMuted);
  });

  // Mastery breakdown
  const bY = 336;
  label(screen, 'MASTERY BREAKDOWN', 20, bY);

  const breakdown = [
    { label: 'Mastered', count: 3,  color: C.green,    pct: 0.25 },
    { label: 'Learning', count: 7,  color: C.accent,   pct: 0.58 },
    { label: 'New',      count: 2,  color: C.textMuted, pct: 0.17 },
  ];
  breakdown.forEach((b, i) => {
    const by = bY + 28 + i * 56;
    rect(screen, 'dot', 20, by + 5, 8, 8, b.color, 1, 4);
    text(screen, b.label, 36, by, 14, 'Regular', C.text);
    text(screen, String(b.count), 358, by, 14, 'SemiBold', b.color, 1, true);
    rect(screen, 'bar-bg', 36, by + 22, 300, 4, C.surface2, 1, 2);
    rect(screen, 'bar-fill', 36, by + 22, Math.round(300 * b.pct), 4, b.color, 1, 2);
  });

  // Recent activity
  const aY = 520;
  label(screen, 'RECENT ACTIVITY', 20, aY);
  const activity = ['verlegen', 'gezellig', 'uitstekend', 'schildpad', 'geweldig'];
  activity.forEach((w, i) => {
    const ay = aY + 24 + i * 44;
    rect(screen, `activity/${w}`, 20, ay, 350, 36, C.surface, 1, 10);
    text(screen, w, 36, ay + 10, 14, 'SemiBold', C.text);
    text(screen, 'reviewed · just now', 240, ay + 11, 11, 'Regular', C.textDim);
  });

  return screen;
}

// ── SCREEN 11: Settings ────────────────────────────────────────────────────
function buildSettings(x) {
  const screen = makeFrame('11 · Settings', 390, 844);
  screen.x = x;

  text(screen, '← Settings', 20, 56, 20, 'SemiBold', C.text);

  const sections = [
    {
      header: 'LANGUAGE',
      items: [
        { label: 'Learning language', value: 'English (EN)' },
        { label: 'Native language', value: 'Ukrainian (UK)' },
      ],
    },
    {
      header: 'NOTIFICATIONS',
      items: [
        { label: 'Enable notifications', value: 'On' },
        { label: 'Reminder window', value: '9am – 9pm' },
        { label: 'Frequency', value: 'Every 3h' },
        { label: 'Daily goal', value: '20 cards' },
      ],
    },
    {
      header: 'ACCOUNT',
      items: [
        { label: 'Signed in as', value: 'lev@gmail.com' },
        { label: 'Sign out', value: '' },
      ],
    },
  ];

  let cy = 100;
  sections.forEach(section => {
    label(screen, section.header, 20, cy);
    cy += 22;

    section.items.forEach(item => {
      const isDestructive = item.label === 'Sign out';
      const rowBg = rect(screen, `row/${item.label}`, 20, cy, 350, 52, C.surface, 1, 12);
      rowBg.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.3 }];
      rowBg.strokeWeight = 0.5;
      text(screen, item.label, 36, cy + 16, 15, 'Regular', isDestructive ? C.red : C.text);
      if (item.value) {
        text(screen, item.value, 370 - item.value.length * 7.5, cy + 16, 14, 'Regular', C.textMuted);
      }
      cy += 58;
    });
    cy += 20;
  });

  return screen;
}

// ── SCREEN 12: Recent ──────────────────────────────────────────────────────
function buildRecent(x) {
  const screen = makeFrame('12 · Recent History', 390, 844);
  screen.x = x;

  text(screen, '← Recent', 20, 56, 20, 'SemiBold', C.text);

  const items = [
    { word: 'verlegen',   trans: 'embarrassed',    saved: true  },
    { word: 'gezellig',   trans: 'cozy, convivial', saved: true  },
    { word: 'uitstekend', trans: 'excellent',       saved: false },
    { word: 'schildpad',  trans: 'turtle',          saved: true  },
    { word: 'geweldig',   trans: 'amazing',         saved: false },
    { word: 'begrijpen',  trans: 'to understand',   saved: true  },
    { word: 'herinneren', trans: 'to remember',     saved: false },
    { word: 'bevatten',   trans: 'to contain',      saved: true  },
    { word: 'kleurrijk',  trans: 'colorful',        saved: false },
  ];

  let iy = 100;
  items.forEach(item => {
    const rowBg = rect(screen, `item/${item.word}`, 20, iy, 350, 60, C.surface, 1, 12);
    rowBg.strokes = [{ type: 'SOLID', color: C.surface3, opacity: 0.4 }];
    rowBg.strokeWeight = 0.5;
    text(screen, item.word, 36, iy + 10, 15, 'SemiBold', C.text);
    text(screen, item.trans, 36, iy + 32, 13, 'Regular', C.textMuted);
    const iconColor = item.saved ? C.indigo : C.textDim;
    text(screen, item.saved ? '◫' : '○', 348, iy + 18, 18, 'Regular', iconColor);
    iy += 68;
  });

  // Clear all button
  text(screen, 'Clear all', 390 / 2 - 28, iy + 16, 14, 'Medium', C.red, 0.7);

  return screen;
}

// ── SCREEN 13: Review — Empty state ───────────────────────────────────────
function buildReviewEmpty(x) {
  const screen = makeFrame('13 · Review — All Done', 390, 844);
  screen.x = x;

  rect(screen, 'progress-bg', 20, 56, 300, 4, C.green, 0.3, 2);
  rect(screen, 'progress-fill', 20, 56, 300, 4, C.green, 1, 2);
  text(screen, '12 / 12', 330, 50, 11, 'Regular', C.green, 1, true);

  // Empty state
  text(screen, '🎉', 390 / 2 - 20, 280, 48, 'Regular', C.text);
  text(screen, "You're all caught up!", 390 / 2 - 88, 348, 20, 'SemiBold', C.text);
  text(screen, 'All cards reviewed for today.', 390 / 2 - 96, 380, 14, 'Regular', C.textMuted);
  text(screen, 'Come back tomorrow for more.', 390 / 2 - 96, 400, 14, 'Regular', C.textMuted);

  // Stat summary
  rect(screen, 'summary-card', 40, 444, 310, 100, C.surface, 1, 16);
  text(screen, '12 reviewed today', 80, 466, 15, 'SemiBold', C.text);
  const sumStats = ['Again: 2', 'Hard: 3', 'Good: 5', 'Easy: 2'];
  sumStats.forEach((s, i) => {
    const sc = [C.ratingAgain, C.ratingHard, C.ratingGood, C.ratingEasy][i];
    text(screen, s, 56 + i * 72, 496, 12, 'Medium', sc);
  });

  buildFloatingNav(screen, 3);
  return screen;
}

// ── Main ───────────────────────────────────────────────────────────────────
figma.showUI(__html__, { width: 320, height: 190 });

figma.ui.onmessage = async (msg) => {
  if (msg.type !== 'generate') return;

  try {
    figma.ui.postMessage({ type: 'progress', text: 'Loading fonts...' });
    await loadFonts();

    figma.ui.postMessage({ type: 'progress', text: 'Creating color styles...' });
    createColorStyles();

    figma.ui.postMessage({ type: 'progress', text: 'Creating text styles...' });
    await createTextStyles();

    figma.ui.postMessage({ type: 'progress', text: 'Building 13 screens...' });

    const GAP = 48;
    const W = 390;

    const screens = [
      buildTranslateIdle(0),
      buildTranslateTyping((W + GAP) * 1),
      buildTranslateLoading((W + GAP) * 2),
      buildTranslateResult((W + GAP) * 3),
      buildTranslateSaved((W + GAP) * 4),
      buildDeck((W + GAP) * 5),
      buildReviewFront((W + GAP) * 6),
      buildReviewBack((W + GAP) * 7),
      buildReviewEmpty((W + GAP) * 8),
      buildWordDetail((W + GAP) * 9),
      buildStats((W + GAP) * 10),
      buildSettings((W + GAP) * 11),
      buildRecent((W + GAP) * 12),
    ];

    figma.currentPage.selection = screens;
    figma.viewport.scrollAndZoomIntoView(screens);

    figma.ui.postMessage({ type: 'done', count: screens.length });
  } catch (err) {
    figma.ui.postMessage({ type: 'error', text: String(err) });
  }
};
