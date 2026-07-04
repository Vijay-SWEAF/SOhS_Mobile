-- ─────────────────────────────────────────────────────────────
-- SOhS mobile app — Phase 11 mobile scheduler/importer
--
-- ADDITIVE ONLY. Adds an explicit admin-only RPC that promotes one
-- reviewed website question/dilemma into app_daily_questions.
-- No triggers. No automatic bulk import. No website table changes.
-- ─────────────────────────────────────────────────────────────

create or replace function public.promote_to_app_daily_question(
  p_source_table text,
  p_source_id uuid,
  p_option0_label text default null,
  p_option1_label text default null,
  p_fact text default null,
  p_opinion text default null,
  p_watch text default null,
  p_twist text default null,
  p_context text default null,
  p_kind text default null,
  p_active_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_source_table text := lower(trim(coalesce(p_source_table, '')));
  v_title text;
  v_slug text;
  v_status text;
  v_default_context text;
  v_discussion_path text;
  v_question_id uuid;
  v_kind text;
  v_option0 text;
  v_option1 text;
  v_fact text;
  v_opinion text;
  v_watch text;
  v_twist text;
  v_context text;
  v_day_number int;
  v_active_date date;
  v_existing public.app_daily_questions%rowtype;
  v_inserted public.app_daily_questions%rowtype;
begin
  if not public.is_admin() then
    raise exception 'admin privileges required';
  end if;

  if p_source_id is null then
    raise exception 'source_id is required';
  end if;

  if v_source_table not in ('human_questions', 'moral_dilemmas') then
    raise exception 'source_table must be human_questions or moral_dilemmas';
  end if;

  -- Serialize schedule assignment so concurrent admin promotions cannot
  -- choose the same next day_number/active_date.
  perform pg_advisory_xact_lock(hashtext('sohs_app_daily_question_importer'));

  if v_source_table = 'human_questions' then
    select title, slug, summary, status
      into v_title, v_slug, v_default_context, v_status
    from public.human_questions
    where id = p_source_id;

    if not found then
      raise exception 'human question not found';
    end if;
    if v_status <> 'published' then
      raise exception 'only published human questions can be promoted';
    end if;

    v_question_id := p_source_id;
    v_discussion_path := '/questions/' || v_slug || '/';
    v_kind := coalesce(nullif(trim(p_kind), ''), 'HUMAN QUESTION');
    v_option0 := coalesce(nullif(trim(p_option0_label), ''), 'Yes');
    v_option1 := coalesce(nullif(trim(p_option1_label), ''), 'No');
  else
    select title, slug, scenario, status
      into v_title, v_slug, v_default_context, v_status
    from public.moral_dilemmas
    where id = p_source_id;

    if not found then
      raise exception 'moral dilemma not found';
    end if;
    if v_status <> 'published' then
      raise exception 'only published moral dilemmas can be promoted';
    end if;

    v_question_id := null;
    v_discussion_path := '/dilemmas/' || v_slug || '/';
    v_kind := coalesce(nullif(trim(p_kind), ''), 'MORAL DILEMMA');

    select label
      into v_option0
    from public.dilemma_options
    where dilemma_id = p_source_id
    order by sort_order asc, created_at asc, id asc
    offset 0
    limit 1;

    select label
      into v_option1
    from public.dilemma_options
    where dilemma_id = p_source_id
    order by sort_order asc, created_at asc, id asc
    offset 1
    limit 1;

    v_option0 := coalesce(nullif(trim(p_option0_label), ''), nullif(trim(v_option0), ''));
    v_option1 := coalesce(nullif(trim(p_option1_label), ''), nullif(trim(v_option1), ''));
  end if;

  if nullif(trim(v_option0), '') is null or nullif(trim(v_option1), '') is null then
    raise exception 'two mobile option labels are required';
  end if;

  select *
    into v_existing
  from public.app_daily_questions
  where discussion_path = v_discussion_path
     or (v_question_id is not null and question_id = v_question_id)
  limit 1;

  if found then
    insert into public.app_vote_counts (question_id)
    values (v_existing.id)
    on conflict (question_id) do nothing;

    return jsonb_build_object(
      'already_exists', true,
      'id', v_existing.id,
      'day_number', v_existing.day_number,
      'active_date', v_existing.active_date,
      'discussion_path', v_existing.discussion_path
    );
  end if;

  v_context := coalesce(
    nullif(trim(p_context), ''),
    nullif(trim(v_default_context), ''),
    'A published SOhS discussion selected for the mobile daily question.'
  );
  v_fact := coalesce(
    nullif(trim(p_fact), ''),
    'This question is published on SOhS for public civic reflection.'
  );
  v_opinion := coalesce(
    nullif(trim(p_opinion), ''),
    'Reasonable people may weigh the values in this question differently.'
  );
  v_watch := coalesce(
    nullif(trim(p_watch), ''),
    'Notice which value you protect first, and which value you ask others to sacrifice.'
  );
  v_twist := coalesce(
    nullif(trim(p_twist), ''),
    'The hardest questions often reveal the value we defend before we explain it.'
  );

  select coalesce(max(day_number), 0) + 1,
         coalesce(max(active_date), (now() at time zone 'utc')::date - 1) + 1
    into v_day_number, v_active_date
  from public.app_daily_questions;

  v_active_date := coalesce(p_active_date, v_active_date);

  if exists (select 1 from public.app_daily_questions where active_date = v_active_date) then
    raise exception 'active_date % is already scheduled', v_active_date;
  end if;

  insert into public.app_daily_questions (
    question_id,
    active_date,
    day_number,
    kind,
    question_text,
    context,
    options,
    think,
    twist,
    discussion_path
  )
  values (
    v_question_id,
    v_active_date,
    v_day_number,
    v_kind,
    v_title,
    v_context,
    jsonb_build_array(
      jsonb_build_object('label', v_option0),
      jsonb_build_object('label', v_option1)
    ),
    jsonb_build_object(
      'fact', v_fact,
      'opinion', v_opinion,
      'watch', v_watch
    ),
    v_twist,
    v_discussion_path
  )
  returning * into v_inserted;

  insert into public.app_vote_counts (question_id)
  values (v_inserted.id)
  on conflict (question_id) do nothing;

  return jsonb_build_object(
    'already_exists', false,
    'id', v_inserted.id,
    'day_number', v_inserted.day_number,
    'active_date', v_inserted.active_date,
    'discussion_path', v_inserted.discussion_path
  );
end;
$$;

comment on function public.promote_to_app_daily_question(
  text, uuid, text, text, text, text, text, text, text, text, date
) is
  'Admin-only RPC that explicitly promotes one published website human question or moral dilemma into the mobile app daily schedule.';

revoke all on function public.promote_to_app_daily_question(
  text, uuid, text, text, text, text, text, text, text, text, date
) from public;

grant execute on function public.promote_to_app_daily_question(
  text, uuid, text, text, text, text, text, text, text, text, date
) to authenticated;
