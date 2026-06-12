// loop.config.js — public configuration for the Decision–Blocker Signal Loop
// The anon key is public by design; its safety is the completeness of RLS.
// See docs/SECRETS.md. Do not put service role keys here.
//
// LOOP_SUPABASE_URL and LOOP_SUPABASE_ANON_KEY are also set as
// GitHub Actions vars for the loop-sync workflow.

window.LOOP_CONFIG = {
  supabaseUrl:  "https://dgcoffcanzwsuwgpocbt.supabase.co",
  supabaseAnon: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRnY29mZmNhbnp3c3V3Z3BvY2J0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyMjE5MzYsImV4cCI6MjA5Njc5NzkzNn0.UYmAI7RrvC_5-ZD6TQKLzfShL06QsiPMszhq-YzbwLY",
  ledgerFallback: "milestones/index.json",
};
