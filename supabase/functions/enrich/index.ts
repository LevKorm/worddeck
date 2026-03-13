import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const langNames: Record<string, string> = {
  EN: 'English', UK: 'Ukrainian', RU: 'Russian', DE: 'German',
  FR: 'French',  ES: 'Spanish',  IT: 'Italian', PT: 'Portuguese',
  PL: 'Polish',  NL: 'Dutch',    JA: 'Japanese', ZH: 'Chinese',
  KO: 'Korean',  AR: 'Arabic',   TR: 'Turkish',  SV: 'Swedish',
  DA: 'Danish',  FI: 'Finnish',  NB: 'Norwegian', CS: 'Czech',
  SK: 'Slovak',  HU: 'Hungarian', RO: 'Romanian', BG: 'Bulgarian',
  EL: 'Greek',   LT: 'Lithuanian', LV: 'Latvian', ET: 'Estonian',
}

function langName(code: string): string {
  return langNames[code.toUpperCase()] ?? code.toUpperCase()
}

function buildPrompt(
  word: string,
  language: string,
  translation?: string,
  targetLang?: string,
): string {
  const hasTranslation = !!(translation && targetLang)

  const srcName = langName(language)
  const tgtName = hasTranslation ? langName(targetLang!) : ''

  const nativePlaceholder = hasTranslation
    ? `"example_sentence_native":"<translate example_sentence to ${tgtName}>","synonyms_native":["<equivalent word in ${tgtName}>"],"usage_notes_native":"<translate usage_notes to ${tgtName}>"`
    : `"example_sentence_native":null,"synonyms_native":null,"usage_notes_native":null`

  const context = hasTranslation
    ? `Word: "${word}" (${srcName} → ${tgtName}: "${translation}")`
    : `Word: "${word}" (${srcName})`

  return `${context}

Fill this JSON for the word above:
{"transcription":"<IPA>","example_sentence":"<short natural sentence in ${srcName}>","example_sentences":["<3 different short natural sentences in ${srcName} using the word>"],"synonyms":["<3-5 ${srcName} synonyms>"],"synonyms_enriched":[{"word":"<synonym>","level":"<A1|A2|B1|B2|C1|C2>"}],"usage_notes":"<1-2 sentences in ${srcName}: register, collocations, confusables>","usage_notes_list":["<2-3 distinct usage notes in ${srcName}: register, collocations, confusables, each 1 sentence>"],"grammar":{"type":"<grammatical category with gender/class, e.g. Feminine noun, Transitive verb>","pattern":"<key inflection patterns, pluralization, conjugation notes>","related":"<derived/related word forms with parts of speech>"},"did_you_mean":<null, or the correct ${srcName} spelling if the word has a typo>,"cefr_level":"<A1|A2|B1|B2|C1|C2>",${nativePlaceholder}}

Return only the filled JSON. No markdown.`
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
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

    // ── Parse request ─────────────────────────────────────────────────────────
    const { word, language, translation, target_lang } = await req.json()

    if (!word?.trim() || !language) {
      return new Response(
        JSON.stringify({ error: 'word and language are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Call Gemini ───────────────────────────────────────────────────────────
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiKey) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY secret not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const model = 'gemini-2.5-flash'
    const prompt = buildPrompt(word.trim(), language, translation, target_lang)

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'x-goog-api-key': geminiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.1,
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

    // Parse and validate the JSON that Gemini returned
    let enrichment: Record<string, unknown>
    try {
      enrichment = JSON.parse(raw)
    } catch {
      return new Response(JSON.stringify({ error: 'Could not parse Gemini response as JSON' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Sanitize cefr_level — only allow valid values
    const validCefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    if (enrichment.cefr_level && !validCefr.includes(enrichment.cefr_level as string)) {
      enrichment.cefr_level = null
    }

    return new Response(JSON.stringify(enrichment), {
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
