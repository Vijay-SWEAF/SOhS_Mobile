-- SOhS mobile app — Phase 7 discussion bridge
--
-- ADDITIVE ONLY against the mobile companion table. This does not
-- touch website vote, answer, moderation, or editorial tables.
-- discussion_path lets a mobile daily question open either a website
-- human question or moral dilemma without mixing vote systems.

alter table public.app_daily_questions
  add column if not exists discussion_path text;

alter table public.app_daily_questions
  drop constraint if exists app_daily_questions_discussion_path_check;

alter table public.app_daily_questions
  add constraint app_daily_questions_discussion_path_check
  check (
    discussion_path is null
    or discussion_path ~ '^/(questions|dilemmas)/[a-z0-9-]+/$'
  );

comment on column public.app_daily_questions.discussion_path is
  'Optional website path for the matching SOhS discussion, e.g. /questions/.../ or /dilemmas/.../.';

update public.app_daily_questions
set discussion_path = case day_number
  when 1 then '/questions/is-being-legally-right-always-morally-right/'
  when 2 then '/dilemmas/the-lost-wallet/'
  else discussion_path
end
where day_number in (1, 2)
  and discussion_path is distinct from case day_number
    when 1 then '/questions/is-being-legally-right-always-morally-right/'
    when 2 then '/dilemmas/the-lost-wallet/'
    else discussion_path
  end;
