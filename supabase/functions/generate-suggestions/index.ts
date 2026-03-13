import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

// ── How many suggestions to generate ─────────────────────────────────────────

function suggestionCount(cardCount: number): number {
  if (cardCount <= 3) return 6
  if (cardCount <= 10) return 4
  return 2
}

// ── Prompt ────────────────────────────────────────────────────────────────────

function buildPrompt(
  count: number,
  learningLang: string,
  nativeLang: string,
  existingWords: string[],
): string {
  const knownWordsLine =
    existingWords.length > 0
      ? `Words they already know (DO NOT suggest these): ${existingWords.join(', ')}`
      : 'They are a complete beginner with no saved words yet.'

  return `You are a language learning content creator. Generate ${count} vocabulary suggestions for a learner.

Learning language: "${learningLang}"
Native language of learner: "${nativeLang}"
${knownWordsLine}

Distribute the ${count} suggestions across these reason types:
- wordOfDay: { "type": "wordOfDay", "label": "Word of the Day", "icon": "✨" }
  Pick one interesting, memorable word. Not too basic, not too obscure.
- essential: { "type": "essential", "label": "Top 500 word", "icon": "🎯" }
  A very commonly used word the learner hasn't saved yet. Practical, high-frequency.
- related: { "type": "related", "label": "Related to [one of their words]", "icon": "🔗" }
  A word semantically close to one of their existing words. If they have no words yet, skip this type.
- completeSet: { "type": "completeSet", "label": "Complete: [theme name]", "icon": "📦" }
  If the learner has 3+ words in a recognizable category (kitchen, emotions, travel, etc.), suggest one more. Otherwise skip.
- commonlyConfused: { "type": "commonlyConfused", "label": "Often confused", "icon": "⚠️" }
  A word that is a false friend or commonly confused by ${nativeLang} native speakers learning ${learningLang}.

For each suggestion, also generate 2–5 engaging carousel slides. Available slide types:
- hero: ALWAYS include as slide 1. Word, translation, IPA, part of speech, short definition.
- sentences: 2–3 example sentences with learning_lang + native_lang versions.
- synonymCloud: center word + 4–8 related words, each with distance (1=close, 2=medium, 3=far).
- wordFamily: Root + noun/verb/adjective/adverb forms.
- collocations: 3–4 phrases that naturally go with this word.
- idioms: 2–4 idioms/expressions using this word with native translation.
- etymology: Origin story with era and root language.
- commonMistakes: 1–3 mistakes ${nativeLang} learners make with this word.
- formalityScale: 3–4 words on a casual→formal spectrum including this word.
- miniStory: A 3–4 sentence micro-narrative using the word naturally.
- funFact: An interesting or cultural fact tied to this word.
- grammar: Only if the word has tricky grammar (irregular forms, unusual prepositions, etc.).

Pick only relevant slide types for each word. Not every word needs every slide type.

Respond ONLY with a JSON array. No markdown, no backticks, no explanation. Structure:
[
  {
    "word": "...",
    "translation": "...",
    "ipa": "...",
    "suggest_reason": { "type": "...", "label": "...", "icon": "..." },
    "slides": [
      {
        "type": "hero|sentences|synonymCloud|...",
        "order": 1,
        "content_learning": { ... type-specific content in learning language ... },
        "content_native": { ... same content in native language ... },
        "extra": { ... structured data like sentences array, synonym list, etc. ... }
      }
    ]
  }
]

For the "hero" slide, extra should contain:
{ "word": "...", "translation": "...", "ipa": "...", "partOfSpeech": "...", "shortDef": "..." }

For "sentences", extra should contain:
{ "title": "In Context", "sentences": [{ "learning": "...", "native": "..." }, ...] }

For "synonymCloud", extra should contain:
{ "title": "Word Galaxy", "center": "word", "words": [{ "word": "...", "distance": 1 }, ...] }

Make all content engaging, not textbook-dry. Prioritise content that would be surprising, useful, or memorable.`
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // ── Auth ─────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    // Supabase verifies the JWT signature at the gateway; we just decode the sub claim.
    let user_id: string
    try {
      const payload = JSON.parse(atob(authHeader.slice(7).split('.')[1]))
      if (!payload.sub) throw new Error()
      user_id = payload.sub
    } catch {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── Parse request ─────────────────────────────────────────────────────────
    const {
      native_lang: bodyNativeLang,
      learning_lang: bodyLearningLang,
      existing_words,
      card_count,
      space_id,
    } = await req.json()

    const words: string[] = Array.isArray(existing_words) ? existing_words : []
    const count = suggestionCount(typeof card_count === 'number' ? card_count : 0)

    // ── Supabase client (service role — bypasses RLS for writes) ──────────────
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    if (!supabaseUrl || !serviceKey) {
      return new Response(
        JSON.stringify({ error: 'Supabase env vars not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }
    const supabase = createClient(supabaseUrl, serviceKey)

    // ── Resolve languages — prefer request body, fall back to user_settings ───
    let native_lang: string = bodyNativeLang || ''
    let learning_lang: string = bodyLearningLang || ''
    if (!native_lang || !learning_lang) {
      const { data: settings } = await supabase
        .from('user_settings')
        .select('learning_language, native_language')
        .eq('user_id', user_id)
        .single()
      native_lang   = native_lang   || (settings?.native_language   as string) || 'UK'
      learning_lang = learning_lang || (settings?.learning_language as string) || 'EN'
    }

    // ── Call Gemini ───────────────────────────────────────────────────────────
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY secret not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const prompt = buildPrompt(count, learning_lang, native_lang, words)

    const geminiRes = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      {
        method: 'POST',
        headers: {
          'x-goog-api-key': geminiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.8,
            maxOutputTokens: 1024,
            responseMimeType: 'application/json',
            thinkingConfig: { thinkingBudget: 0 },
          },
        }),
      },
    )

    if (!geminiRes.ok) {
      const status = geminiRes.status
      let message = `Gemini error (${status})`
      if (status === 400) message = 'Invalid request to Gemini'
      if (status === 403) message = 'Invalid Gemini API key'
      if (status === 429) message = 'Gemini quota exceeded'
      return new Response(JSON.stringify({ error: message }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const geminiData = await geminiRes.json()
    const raw: string | undefined =
      geminiData.candidates?.[0]?.content?.parts?.[0]?.text

    if (!raw) {
      return new Response(JSON.stringify({ error: 'Empty response from Gemini' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── Parse Gemini JSON ─────────────────────────────────────────────────────
    let suggestions: Array<{
      word: string
      translation: string
      ipa?: string
      suggest_reason: { type: string; label: string; icon: string }
      slides: unknown[]
    }>

    try {
      suggestions = JSON.parse(raw)
      if (!Array.isArray(suggestions)) throw new Error('Expected a JSON array')
    } catch {
      return new Response(
        JSON.stringify({ error: 'Could not parse Gemini response as JSON array' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Write suggested posts to DB ───────────────────────────────────────────
    const rows = suggestions
      .filter((s) => s.word?.trim() && s.slides?.length > 0)
      .map((s) => ({
        user_id,
        space_id:       space_id ?? null,
        post_type:      'word',
        word:           s.word.trim(),
        translation:    s.translation ?? null,
        ipa:            s.ipa ?? null,
        slides:         s.slides,
        status:         'ready',
        suggested:      true,
        suggest_reason: s.suggest_reason,
        generated_at:   new Date().toISOString(),
      }))

    if (rows.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid suggestions generated' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data, error: dbError } = await supabase
      .from('card_feed_content')
      .insert(rows)
      .select()

    if (dbError) {
      return new Response(JSON.stringify({ error: dbError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ posts: data, count: rows.length }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error'
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
