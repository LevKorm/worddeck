import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

// Exact prompt from the Flutter GeminiEnrichmentService._buildPrompt()
function buildPrompt(
  word: string,
  language: string,
  translation?: string,
  targetLang?: string,
): string {
  const translationLine =
    translation
      ? `Translation: "${translation}"\nTarget language: ${targetLang ?? ''}`
      : ''

  return `You are a linguistics expert. Given a word and its translation, return a JSON object with exactly these fields:
- "transcription": IPA phonetic transcription of the source word
- "example_sentence": a natural, everyday example sentence using the word (not overly complex)
- "synonyms": array of 3–5 synonyms of the source word (in the source language)
- "usage_notes": 1–2 sentence note covering when/how to use the word, common collocations, register (formal/informal), or easily confused similar words
- "did_you_mean": if the source word appears to have a typo or spelling error, provide the likely intended correct word as a string; otherwise null

Source language: ${language}
Word: "${word}"
${translationLine}

Respond with ONLY valid JSON. No markdown, no code fences, no explanation.`
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // ── Auth ─────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
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
            temperature: 0.3,
            responseMimeType: 'application/json',
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
