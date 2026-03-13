import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

// ── Language name helper ───────────────────────────────────────────────────────

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

// ── Prompt ────────────────────────────────────────────────────────────────────

function buildPrompt(text: string, sourceLang: string, targetLang: string): string {
  return `Translate from ${langName(sourceLang)} to ${langName(targetLang)}: "${text}"

Return JSON: {"translation":"<best translation, same case as input>"}`
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

    // ── Parse request ─────────────────────────────────────────────────────────
    const { text, source_lang, target_lang } = await req.json()

    if (!text?.trim()) {
      return new Response(
        JSON.stringify({ error: 'text is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const sourceLang = (source_lang as string | undefined)?.toUpperCase() ?? 'EN'
    const targetLang = (target_lang as string | undefined)?.toUpperCase() ?? 'UK'

    // ── Call Gemini ───────────────────────────────────────────────────────────
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY secret not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const prompt = buildPrompt(text.trim(), sourceLang, targetLang)

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
            temperature: 0.1,
            maxOutputTokens: 200,
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

    let parsed: Record<string, unknown>
    try {
      parsed = JSON.parse(raw)
    } catch {
      return new Response(JSON.stringify({ error: 'Could not parse Gemini response as JSON' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const translation = parsed['translation'] as string | undefined

    if (!translation?.trim()) {
      return new Response(JSON.stringify({ error: 'Empty translation from Gemini' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ translation: translation.trim() }), {
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
