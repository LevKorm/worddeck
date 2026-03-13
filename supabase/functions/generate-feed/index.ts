import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

// ── Prompt ────────────────────────────────────────────────────────────────────

function buildPrompt(
  word: string,
  translation: string,
  target_lang: string,
  native_lang: string,
): string {
  return `You are a language learning content creator. Generate engaging carousel slides for a vocabulary word.

Word: "${word}"
Translation: "${translation}"
Learning language: "${target_lang}"
Native language of learner: "${native_lang}"

Generate 2-7 slides. Pick ONLY the types that are relevant and interesting for this specific word. Not every word needs every type. A simple concrete noun might get 3 slides. A verb with irregular conjugation might get 6.

Available slide types:

- hero: ALWAYS include as slide 1. Word, translation, IPA, part of speech, short definition.
- sentences: 2-3 example sentences showing different meanings/contexts. Each with learning_lang and native_lang versions.
- synonymCloud: Center word + 4-8 related words with distance (1=close, 2=medium, 3=far).
- wordFamily: Root + noun/verb/adjective/adverb forms.
- collocations: 3-4 phrases that naturally go with this word, with meaning and usage note.
- idioms: 2-4 idioms/expressions using this word, with native translation and explanation.
- etymology: Origin story of the word. Era and root language.
- commonMistakes: 1-3 mistakes learners make with this word (especially false friends for ${native_lang} speakers).
- formalityScale: 3-4 words on a casual→formal spectrum including this word.
- miniStory: A 3-4 sentence micro-narrative using the word naturally. Include a takeaway.
- funFact: An interesting fact or cultural note tied to this word.
- grammar: Only if the word has tricky grammar (irregular forms, unusual prepositions, etc.).

IMPORTANT: Always populate the "extra" field using the exact schema shown below for each type.

Respond ONLY with a JSON array. No markdown, no backticks, no explanation. Each slide:
{
  "type": "hero|sentences|synonymCloud|...",
  "order": 1,
  "content_learning": { ... type-specific content in learning language ... },
  "content_native": { ... same content translated to native language ... },
  "extra": { ... see schemas below ... }
}

Extra field schemas — use these exactly:

hero: { "word": "...", "translation": "...", "ipa": "...", "partOfSpeech": "...", "shortDef": "..." }

sentences: { "title": "In Context", "sentences": [{ "learning": "...", "native": "..." }, ...] }

synonymCloud: { "title": "Word Galaxy", "center": "...", "words": [{ "word": "...", "distance": 1 }, ...] }
(distance 1=very close, 2=related, 3=loosely related)

etymology: { "title": "Word Origin", "era": "...", "rootLanguage": "...", "rootWord": "...", "meaning": "..." }

funFact: { "title": "Did You Know?", "fact": "..." }

miniStory: { "title": "...", "story": "...", "takeaway": "..." }

wordFamily: { "title": "Word Family", "root": "...", "forms": [{ "partOfSpeech": "noun|verb|adjective|adverb", "word": "..." }, ...] }

collocations: { "title": "Goes Well With", "phrases": [{ "phrase": "...", "meaning": "...", "usage": "..." }, ...] }

grammar: { "title": "Grammar Note", "rule": "...", "forms": [{ "label": "...", "example": "..." }, ...] }

commonMistakes: { "title": "Watch Out!", "mistakes": [{ "wrong": "...", "right": "...", "explanation": "..." }, ...] }

formalityScale: { "title": "Register Scale", "words": [{ "word": "...", "level": 1, "label": "..." }, ...] }
(level 1=very casual, 3=neutral, 5=very formal)

idioms: { "title": "Idioms & Expressions", "idioms": [{ "idiom": "...", "meaning": "...", "native": "...", "example": "..." }, ...] }

NOTE: Never generate "compareHero", "compareGrid", "themeHero", or "video" slide types here.

Make all content engaging, not textbook-dry. Use casual, interesting language. Prioritize content that would be surprising, useful, or memorable.`
}

// ── Handler ───────────────────────────────────────────────────────────────────

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
      card_id,
      word,
      translation,
      ipa,
      source_lang,
      target_lang: bodyTargetLang,
      native_lang: bodyNativeLang,
      space_id,
    } = await req.json()

    if (!word?.trim() || !translation) {
      return new Response(
        JSON.stringify({ error: 'word and translation are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

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
    let target_lang: string = bodyTargetLang || ''
    let native_lang: string = bodyNativeLang || ''
    if (!target_lang || !native_lang) {
      const { data: settings } = await supabase
        .from('user_settings')
        .select('learning_language, native_language')
        .eq('user_id', user_id)
        .single()
      target_lang = target_lang || (settings?.learning_language as string) || 'EN'
      native_lang = native_lang || (settings?.native_language as string) || 'UK'
    }

    // ── Call Gemini ───────────────────────────────────────────────────────────
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY secret not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const model  = 'gemini-2.5-flash'
    const prompt = buildPrompt(word.trim(), translation, target_lang, native_lang)

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
            temperature: 0.7,
            maxOutputTokens: 2048,
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
    let slides: unknown[]
    try {
      slides = JSON.parse(raw)
      if (!Array.isArray(slides)) throw new Error('Expected a JSON array')
    } catch {
      return new Response(
        JSON.stringify({ error: 'Could not parse Gemini response as JSON array' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Write ready row ───────────────────────────────────────────────────────
    const { data, error: dbError } = await supabase
      .from('card_feed_content')
      .insert({
        card_id:      card_id ?? null,
        user_id,
        space_id:     space_id ?? null,
        post_type:    'word',
        word:         word.trim(),
        translation,
        ipa:          ipa ?? null,
        slides,
        status:       'ready',
        generated_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (dbError) {
      return new Response(JSON.stringify({ error: dbError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ post: data }), {
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
