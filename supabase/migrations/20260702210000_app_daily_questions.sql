-- ─────────────────────────────────────────────────────────────
-- SOhS mobile app — Phase 3, migration 1 of 2
--
-- ADDITIVE ONLY. Creates four new tables and one function for the
-- mobile app's daily-question flow. No existing table, column,
-- policy, or function is altered, dropped, or renamed. The website's
-- open-text answer + moderation pipeline is untouched.
-- ─────────────────────────────────────────────────────────────

-- 1 ▸ The app's daily schedule. A companion table, NOT part of the
--     website's human_questions editorial flow — the site never reads
--     it, so seeded app questions are invisible to the website by
--     construction. question_id optionally links a day's question to
--     the matching website discussion for a future deep link.
create table public.app_daily_questions (
  id            uuid primary key default gen_random_uuid(),
  question_id   uuid references public.human_questions(id) on delete set null,
  active_date   date not null unique,
  day_number    int  not null unique check (day_number > 0),
  kind          text not null default 'HUMAN QUESTION',
  question_text text not null,
  context       text,
  options       jsonb not null check (
    jsonb_typeof(options) = 'array' and jsonb_array_length(options) = 2
  ),
  think         jsonb not null check (jsonb_typeof(think) = 'object'),
  twist         text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.app_daily_questions is
  'Mobile app daily questions (one per UTC date). Companion to human_questions; not read by the website.';

-- 2 ▸ Raw votes. One row per device per question. Clients can never
--     read or write this table directly — RLS is enabled with zero
--     policies, and the only write path is cast_vote() below.
create table public.app_votes (
  id           uuid primary key default gen_random_uuid(),
  question_id  uuid not null references public.app_daily_questions(id) on delete cascade,
  device_id    uuid not null,
  option_index smallint not null check (option_index in (0, 1)),
  country_code text check (country_code ~ '^[A-Z]{2}$'),
  created_at   timestamptz not null default now(),
  unique (question_id, device_id)
);

comment on table public.app_votes is
  'Raw mobile votes, keyed by anonymous device UUID. Not client-readable; written only via cast_vote().';

-- 3 ▸ Aggregates the app reads. Maintained atomically inside
--     cast_vote(); clients get counts, never raw votes.
create table public.app_vote_counts (
  question_id   uuid primary key references public.app_daily_questions(id) on delete cascade,
  option0_count bigint not null default 0,
  option1_count bigint not null default 0,
  updated_at    timestamptz not null default now()
);

create table public.app_vote_country_counts (
  question_id   uuid not null references public.app_daily_questions(id) on delete cascade,
  country_code  text not null check (country_code ~ '^[A-Z]{2}$'),
  option0_count bigint not null default 0,
  option1_count bigint not null default 0,
  primary key (question_id, country_code)
);

comment on table public.app_vote_counts is
  'Global per-question tallies for the mobile app reveal.';
comment on table public.app_vote_country_counts is
  'Per-country tallies for the mobile app country chips.';

-- 4 ▸ Row-level security. New tables only.
alter table public.app_daily_questions      enable row level security;
alter table public.app_votes                enable row level security;
alter table public.app_vote_counts          enable row level security;
alter table public.app_vote_country_counts  enable row level security;

-- Questions: readable once their UTC day has arrived. Tomorrow's
-- question is invisible even to a client that asks for it.
create policy "app_daily_questions: read up to today (UTC)"
  on public.app_daily_questions
  for select
  to anon, authenticated
  using (active_date <= (now() at time zone 'utc')::date);

-- Counts: world-readable.
create policy "app_vote_counts: read"
  on public.app_vote_counts
  for select
  to anon, authenticated
  using (true);

create policy "app_vote_country_counts: read"
  on public.app_vote_country_counts
  for select
  to anon, authenticated
  using (true);

-- app_votes intentionally has NO policies: with RLS enabled this
-- denies all client access. cast_vote() (security definer) and the
-- service role are the only actors that can touch it.

-- 5 ▸ cast_vote — the app's single write path.
--     Idempotent per (question, device): a repeat vote changes
--     nothing and reports already_voted = true.
create function public.cast_vote(
  p_question_id  uuid,
  p_device_id    uuid,
  p_option_index smallint,
  p_country_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_active_date date;
  v_country     text;
  v_inserted    boolean := false;
  v_c0          bigint  := 0;
  v_c1          bigint  := 0;
begin
  if p_question_id is null or p_device_id is null then
    raise exception 'question_id and device_id are required';
  end if;
  if p_option_index is null or p_option_index not in (0, 1) then
    raise exception 'option_index must be 0 or 1';
  end if;

  select active_date into v_active_date
  from app_daily_questions
  where id = p_question_id;

  if not found then
    raise exception 'unknown question';
  end if;
  if v_active_date > (now() at time zone 'utc')::date then
    raise exception 'question is not open yet';
  end if;

  -- normalize country to ISO alpha-2 or null
  v_country := upper(nullif(trim(coalesce(p_country_code, '')), ''));
  if v_country is null or v_country !~ '^[A-Z]{2}$' then
    v_country := null;
  end if;

  insert into app_votes (question_id, device_id, option_index, country_code)
  values (p_question_id, p_device_id, p_option_index, v_country)
  on conflict (question_id, device_id) do nothing;
  v_inserted := found;

  if v_inserted then
    insert into app_vote_counts as c (question_id, option0_count, option1_count)
    values (
      p_question_id,
      case when p_option_index = 0 then 1 else 0 end,
      case when p_option_index = 1 then 1 else 0 end
    )
    on conflict (question_id) do update
      set option0_count = c.option0_count + excluded.option0_count,
          option1_count = c.option1_count + excluded.option1_count,
          updated_at    = now();

    if v_country is not null then
      insert into app_vote_country_counts as cc
        (question_id, country_code, option0_count, option1_count)
      values (
        p_question_id,
        v_country,
        case when p_option_index = 0 then 1 else 0 end,
        case when p_option_index = 1 then 1 else 0 end
      )
      on conflict (question_id, country_code) do update
        set option0_count = cc.option0_count + excluded.option0_count,
            option1_count = cc.option1_count + excluded.option1_count;
    end if;
  end if;

  select option0_count, option1_count into v_c0, v_c1
  from app_vote_counts
  where question_id = p_question_id;
  if not found then
    v_c0 := 0;
    v_c1 := 0;
  end if;

  return jsonb_build_object(
    'option0_count', v_c0,
    'option1_count', v_c1,
    'already_voted', not v_inserted
  );
end;
$$;

comment on function public.cast_vote(uuid, uuid, smallint, text) is
  'Mobile app vote submission. Idempotent per (question, device); maintains global and per-country tallies atomically.';

revoke all on function public.cast_vote(uuid, uuid, smallint, text) from public;
grant execute on function public.cast_vote(uuid, uuid, smallint, text) to anon, authenticated;
