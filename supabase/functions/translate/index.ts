import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // ── Auth: only authenticated users may call this function ───────────────
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

    // ── Parse request ────────────────────────────────────────────────────────
    const { text, source_lang, target_lang } = await req.json()

    if (!text?.trim() || !target_lang) {
      return new Response(
        JSON.stringify({ error: 'text and target_lang are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Call DeepL ───────────────────────────────────────────────────────────
    const deeplKey = Deno.env.get('DEEPL_API_KEY')
    if (!deeplKey) {
      return new Response(JSON.stringify({ error: 'DEEPL_API_KEY secret not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const params = new URLSearchParams({
      text: text.trim(),
      target_lang: target_lang.toUpperCase(),
    })
    if (source_lang) params.set('source_lang', source_lang.toUpperCase())

    const deeplRes = await fetch('https://api-free.deepl.com/v2/translate', {
      method: 'POST',
      headers: {
        Authorization: `DeepL-Auth-Key ${deeplKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    })

    if (!deeplRes.ok) {
      const status = deeplRes.status
      let message = `DeepL error (${status})`
      if (status === 403) message = 'Invalid DeepL API key'
      if (status === 429 || status === 456) message = 'DeepL translation quota exceeded'
      return new Response(JSON.stringify({ error: message }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const deeplData = await deeplRes.json()
    const translation: string | undefined = deeplData.translations?.[0]?.text

    if (!translation) {
      return new Response(JSON.stringify({ error: 'Empty translation received from DeepL' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ translation }), {
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
