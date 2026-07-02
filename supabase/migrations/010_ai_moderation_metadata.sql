-- Optional AI moderation and country-level submission metadata.
--
-- These columns support server-side guarded UGC intake through Cloudflare
-- Pages Functions. They intentionally store country code only, never IP
-- address or precise location.

alter table public.opinions
	add column if not exists country_code text,
	add column if not exists ai_moderation_provider text,
	add column if not exists ai_moderation_model text,
	add column if not exists ai_moderation_risk_level text,
	add column if not exists ai_moderation_flags text[] not null default '{}',
	add column if not exists ai_moderation_status jsonb not null default '{}'::jsonb;
alter table public.opinion_reports
	add column if not exists country_code text,
	add column if not exists ai_moderation_provider text,
	add column if not exists ai_moderation_model text,
	add column if not exists ai_moderation_risk_level text,
	add column if not exists ai_moderation_flags text[] not null default '{}',
	add column if not exists ai_moderation_status jsonb not null default '{}'::jsonb;
alter table public.human_question_answers
	add column if not exists country_code text,
	add column if not exists ai_moderation_provider text,
	add column if not exists ai_moderation_model text,
	add column if not exists ai_moderation_risk_level text,
	add column if not exists ai_moderation_flags text[] not null default '{}',
	add column if not exists ai_moderation_status jsonb not null default '{}'::jsonb;
alter table public.dilemma_votes
	add column if not exists country_code text,
	add column if not exists ai_moderation_provider text,
	add column if not exists ai_moderation_model text,
	add column if not exists ai_moderation_risk_level text,
	add column if not exists ai_moderation_flags text[] not null default '{}',
	add column if not exists ai_moderation_status jsonb not null default '{}'::jsonb;
alter table public.topic_requests
	add column if not exists country_code text,
	add column if not exists ai_moderation_provider text,
	add column if not exists ai_moderation_model text,
	add column if not exists ai_moderation_risk_level text,
	add column if not exists ai_moderation_flags text[] not null default '{}',
	add column if not exists ai_moderation_status jsonb not null default '{}'::jsonb;
do $$
declare
	v_table text;
begin
	foreach v_table in array array[
		'opinions',
		'opinion_reports',
		'human_question_answers',
		'dilemma_votes',
		'topic_requests'
	] loop
		execute format(
			'alter table public.%I drop constraint if exists %I',
			v_table,
			v_table || '_country_code_check'
		);
		execute format(
			'alter table public.%I add constraint %I check (country_code is null or country_code ~ ''^[A-Z]{2}$'')',
			v_table,
			v_table || '_country_code_check'
		);

		execute format(
			'alter table public.%I drop constraint if exists %I',
			v_table,
			v_table || '_ai_moderation_risk_level_check'
		);
		execute format(
			'alter table public.%I add constraint %I check (
				ai_moderation_risk_level is null
				or ai_moderation_risk_level in (''low'', ''medium'', ''high'', ''blocked'', ''unavailable'')
			)',
			v_table,
			v_table || '_ai_moderation_risk_level_check'
		);
	end loop;
end;
$$;
create index if not exists opinions_country_code_idx on public.opinions (country_code);
create index if not exists opinions_ai_moderation_risk_idx on public.opinions (ai_moderation_risk_level);
create index if not exists opinion_reports_country_code_idx on public.opinion_reports (country_code);
create index if not exists opinion_reports_ai_moderation_risk_idx on public.opinion_reports (ai_moderation_risk_level);
create index if not exists human_question_answers_country_code_idx on public.human_question_answers (country_code);
create index if not exists human_question_answers_ai_moderation_risk_idx on public.human_question_answers (ai_moderation_risk_level);
create index if not exists dilemma_votes_country_code_idx on public.dilemma_votes (country_code);
create index if not exists dilemma_votes_ai_moderation_risk_idx on public.dilemma_votes (ai_moderation_risk_level);
create index if not exists topic_requests_country_code_idx on public.topic_requests (country_code);
create index if not exists topic_requests_ai_moderation_risk_idx on public.topic_requests (ai_moderation_risk_level);
comment on column public.opinions.country_code is 'Optional country-level submission origin from Cloudflare. IP address is not stored.';
comment on column public.opinion_reports.country_code is 'Optional country-level report origin from Cloudflare. IP address is not stored.';
comment on column public.human_question_answers.country_code is 'Optional country-level answer origin from Cloudflare. IP address is not stored.';
comment on column public.dilemma_votes.country_code is 'Optional country-level dilemma vote origin from Cloudflare. IP address is not stored.';
comment on column public.topic_requests.country_code is 'Optional country-level topic request origin from Cloudflare. IP address is not stored.';
comment on column public.opinions.ai_moderation_status is 'Best-effort server-side moderation metadata. Human review remains the source of truth.';
comment on column public.opinion_reports.ai_moderation_status is 'Best-effort server-side moderation metadata. Human review remains the source of truth.';
comment on column public.human_question_answers.ai_moderation_status is 'Best-effort server-side moderation metadata. Human review remains the source of truth.';
comment on column public.dilemma_votes.ai_moderation_status is 'Best-effort server-side moderation metadata. Human review remains the source of truth.';
comment on column public.topic_requests.ai_moderation_status is 'Best-effort server-side moderation metadata. Human review remains the source of truth.';
