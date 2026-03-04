# WordDeck

AI-powered language learning with smart flashcards and spaced repetition.

## Setup

### 1. Flutter environment

```bash
flutter pub get
```

Copy `.env.example` to `.env` and fill in your Supabase project values:

```bash
cp .env.example .env
```

The `.env` file only needs two values — both are public by design:

```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 2. Deploy Supabase Edge Functions

All sensitive API keys (DeepL, Gemini) live as Supabase secrets and are
never shipped in the app binary.

**Install the Supabase CLI** (if you haven't already):

```bash
brew install supabase/tap/supabase
```

**Link your project:**

```bash
supabase login
supabase link --project-ref your-project-ref
```

**Set secrets** (run once — stored encrypted in Supabase, never committed):

```bash
supabase secrets set DEEPL_API_KEY=your_deepl_api_key
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
```

**Deploy the functions:**

```bash
supabase functions deploy translate
supabase functions deploy enrich
```

That's it. The Flutter app will call these functions automatically,
authenticated via the user's Supabase JWT.

### 3. Run

```bash
flutter run                     # default device
flutter run -d chrome           # web
flutter build apk               # Android release APK
```

## Architecture

- **Flutter** + Riverpod + GoRouter
- **Supabase** — auth, database (flashcards), edge functions
- **DeepL** — translation (proxied via edge function)
- **Gemini 2.5 Flash** — word enrichment (proxied via edge function)
- **SM-2** spaced repetition algorithm

## Security

- DeepL and Gemini API keys are **server-side only** (Supabase secrets)
- The Supabase anon key is intentionally public and protected by Row Level Security
- `.env` is gitignored; only `.env.example` is committed
- Edge functions verify the user's JWT before calling any external API
