IT-Ace update bundle
====================
Extract this zip INTO your project folder (cse_it_prep_app). Say "yes" to replace files.
Folders inside the zip already match your project (lib/, web/, pubspec.yaml).

DELETE these files from your project:
  lib/views/ai_assistant/ai_config.dart
  lib/views/media_viewers/pdf_viewer_stub.dart
  lib/views/media_viewers/pdf_viewer_web.dart

Do NOT put these in the app: supabase/ folder is only for Supabase (see steps below).

Steps
1. Supabase SQL Editor: run supabase/ai_chats.sql (skip if you already ran it).
2. Supabase Dashboard -> Edge Functions -> Secrets: add
     GEMINI_API_KEYS = your NEW Gemini key(s), separated by commas
   (revoke the old keys in Google AI Studio first, they were public).
3. Supabase Dashboard -> Edge Functions -> Deploy a new function (via editor), name it exactly:  ai-chat
   Paste all of supabase/functions/ai-chat/index.ts. Turn "Verify JWT" OFF (the code checks login itself).
4. In your project: flutter pub get
5. flutter build web --release --no-web-resources-cdn   then deploy build/web to Vercel.
6. After the new site works: delete your local .env file.
