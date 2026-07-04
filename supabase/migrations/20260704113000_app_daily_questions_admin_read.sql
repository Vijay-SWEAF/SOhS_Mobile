-- ─────────────────────────────────────────────────────────────
-- SOhS mobile app — admin schedule visibility
--
-- ADDITIVE ONLY. Lets authenticated admins read future mobile
-- schedule rows for the website admin promotion UI. Anonymous
-- mobile clients still only see questions up to today through the
-- original public read policy.
-- ─────────────────────────────────────────────────────────────

create policy "app_daily_questions: admin read full schedule"
  on public.app_daily_questions
  for select
  to authenticated
  using (public.is_admin());
