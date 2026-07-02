-- Server-side UGC submission RPCs for SOhS.
-- Browser forms still do client-side validation for UX, but these functions are
-- the database-side guardrail: they require auth.uid(), validate basic shape,
-- force moderation defaults, and insert only allowed columns.

-- Remove direct browser insert policies for UGC tables. The RPC functions below
-- are SECURITY DEFINER and perform explicit auth.uid() checks before inserting.
-- Users can still read their own submissions through the existing select
-- policies, and moderators/admins can still manage records through existing
-- moderation policies.
drop policy if exists "opinions_insert_own_pending" on public.opinions;
drop policy if exists "human_question_answers_insert_own_pending" on public.human_question_answers;
drop policy if exists "dilemma_votes_insert_own_pending" on public.dilemma_votes;
drop policy if exists "topic_requests_insert_own_pending" on public.topic_requests;
drop policy if exists "topic_requests_insert_own_new" on public.topic_requests;
drop policy if exists "opinion_reports_insert_own_pending" on public.opinion_reports;
drop policy if exists "opinion_reports_insert_own_open" on public.opinion_reports;
create or replace function public.sohs_count_links(value text)
returns integer
language sql
immutable
as $$
	select count(*)::integer
	from regexp_matches(coalesce(value, ''), '(https?://|www\.)', 'gi');
$$;
create or replace function public.sohs_require_text(
	value text,
	field_name text,
	min_length integer,
	max_length integer,
	max_links integer
)
returns text
language plpgsql
immutable
as $$
declare
	v_value text := btrim(coalesce(value, ''));
begin
	if v_value = '' then
		raise exception '% cannot be empty.', field_name;
	end if;

	if char_length(v_value) < min_length then
		raise exception '% must be at least % characters.', field_name, min_length;
	end if;

	if char_length(v_value) > max_length then
		raise exception '% must be % characters or fewer.', field_name, max_length;
	end if;

	if public.sohs_count_links(v_value) > max_links then
		raise exception '% can include at most % link(s).', field_name, max_links;
	end if;

	return v_value;
end;
$$;
create or replace function public.submit_opinion(
	article_id uuid,
	body text,
	opinion_type text default 'experience'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_body text;
	v_opinion_type text := lower(btrim(coalesce(opinion_type, 'experience')));
begin
	if v_user_id is null then
		raise exception 'Authentication is required to submit an opinion.';
	end if;

	if v_opinion_type not in ('agree', 'disagree', 'evidence', 'question', 'experience', 'correction') then
		raise exception 'Invalid opinion type.';
	end if;

	if not exists (
		select 1
		from public.articles as a
		where a.id = submit_opinion.article_id and a.status = 'published'
	) then
		raise exception 'Published article not found.';
	end if;

	v_body := public.sohs_require_text(body, 'Opinion', 40, 1200, 2);

	insert into public.opinions (
		article_id,
		user_id,
		body,
		structured_position,
		status
	)
	values (
		submit_opinion.article_id,
		v_user_id,
		v_body,
		v_opinion_type,
		'pending'
	);

	return jsonb_build_object('ok', true);
end;
$$;
create or replace function public.submit_human_question_answer(
	question_id uuid,
	vote text,
	explanation text,
	generation text default 'Prefer not to say'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_vote text := lower(btrim(coalesce(vote, '')));
	v_generation text := nullif(btrim(coalesce(generation, 'Prefer not to say')), '');
	v_explanation text;
begin
	if v_user_id is null then
		raise exception 'Authentication is required to answer this question.';
	end if;

	if v_vote not in ('yes', 'no', 'depends') then
		raise exception 'Choose Yes, No, or Depends.';
	end if;

	if v_generation not in ('Gen X', 'Millennial', 'Gen Z', 'Prefer not to say') then
		raise exception 'Invalid generation value.';
	end if;

	if not exists (
		select 1
		from public.human_questions as hq
		where hq.id = submit_human_question_answer.question_id and hq.status = 'published'
	) then
		raise exception 'Published question not found.';
	end if;

	v_explanation := public.sohs_require_text(explanation, 'Explanation', 20, 800, 1);

	insert into public.human_question_answers (
		question_id,
		user_id,
		vote,
		explanation,
		generation,
		status
	)
	values (
		submit_human_question_answer.question_id,
		v_user_id,
		v_vote,
		v_explanation,
		v_generation,
		'pending'
	);

	return jsonb_build_object('ok', true);
end;
$$;
create or replace function public.submit_dilemma_vote(
	dilemma_id uuid,
	option_id uuid,
	reason text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_reason text;
begin
	if v_user_id is null then
		raise exception 'Authentication is required to vote on this dilemma.';
	end if;

	if not exists (
		select 1
		from public.moral_dilemmas as md
		where md.id = submit_dilemma_vote.dilemma_id and md.status = 'published'
	) then
		raise exception 'Published dilemma not found.';
	end if;

	if not exists (
		select 1
		from public.dilemma_options as opt
		where opt.id = submit_dilemma_vote.option_id
			and opt.dilemma_id = submit_dilemma_vote.dilemma_id
	) then
		raise exception 'Dilemma option not found.';
	end if;

	v_reason := public.sohs_require_text(reason, 'Reason', 20, 900, 1);

	insert into public.dilemma_votes (
		dilemma_id,
		option_id,
		user_id,
		reason,
		status
	)
	values (
		submit_dilemma_vote.dilemma_id,
		submit_dilemma_vote.option_id,
		v_user_id,
		v_reason,
		'pending'
	);

	return jsonb_build_object('ok', true);
end;
$$;
create or replace function public.submit_topic_request(
	topic_type text,
	title text,
	context text,
	sources text[] default '{}'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_topic_type text := lower(btrim(coalesce(topic_type, '')));
	v_title text;
	v_context text;
	v_sources text[] := coalesce(sources, '{}');
	v_source text;
	v_clean_sources text[] := '{}';
begin
	if v_user_id is null then
		raise exception 'Authentication is required to submit a topic request.';
	end if;

	if v_topic_type not in ('article', 'human_question', 'moral_dilemma', 'correction', 'other') then
		raise exception 'Invalid topic type.';
	end if;

	if array_length(v_sources, 1) > 5 then
		raise exception 'Sources can include at most 5 entries.';
	end if;

	foreach v_source in array v_sources loop
		v_source := btrim(coalesce(v_source, ''));
		if v_source <> '' then
			if char_length(v_source) > 300 then
				raise exception 'Each source must be 300 characters or fewer.';
			end if;
			v_clean_sources := array_append(v_clean_sources, v_source);
		end if;
	end loop;

	if public.sohs_count_links(array_to_string(v_clean_sources, ' ')) > 5 then
		raise exception 'Sources can include at most 5 links.';
	end if;

	v_title := public.sohs_require_text(title, 'Title', 8, 160, 0);
	v_context := public.sohs_require_text(context, 'Context', 30, 1200, 3);

	insert into public.topic_requests (
		user_id,
		topic_type,
		title,
		context,
		sources,
		status
	)
	values (
		v_user_id,
		v_topic_type,
		v_title,
		v_context,
		v_clean_sources,
		'new'
	);

	return jsonb_build_object('ok', true);
end;
$$;
create or replace function public.report_opinion(
	opinion_id uuid,
	reason text,
	details text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_reason text;
	v_details text := nullif(btrim(coalesce(details, '')), '');
begin
	if v_user_id is null then
		raise exception 'Authentication is required to report an opinion.';
	end if;

	if not exists (
		select 1
		from public.opinions as o
		where o.id = report_opinion.opinion_id and o.status = 'approved'
	) then
		raise exception 'Approved opinion not found.';
	end if;

	v_reason := public.sohs_require_text(reason, 'Report reason', 3, 120, 0);

	if v_details is not null then
		v_details := public.sohs_require_text(v_details, 'Report details', 10, 700, 1);
	else
		if char_length(v_reason) < 10 then
			raise exception 'Report must be at least 10 characters.';
		end if;
	end if;

	insert into public.opinion_reports (
		opinion_id,
		reporter_id,
		reason,
		details,
		status
	)
	values (
		report_opinion.opinion_id,
		v_user_id,
		v_reason,
		v_details,
		'open'
	);

	return jsonb_build_object('ok', true);
end;
$$;
comment on function public.submit_opinion(uuid, text, text) is
	'Validated authenticated article opinion submission. Forces pending status.';
comment on function public.submit_human_question_answer(uuid, text, text, text) is
	'Validated authenticated human question answer submission. Forces pending status.';
comment on function public.submit_dilemma_vote(uuid, uuid, text) is
	'Validated authenticated moral dilemma vote submission. Forces pending status.';
comment on function public.submit_topic_request(text, text, text, text[]) is
	'Validated authenticated topic request submission. Forces new status.';
comment on function public.report_opinion(uuid, text, text) is
	'Validated authenticated opinion report submission. Forces open status.';
revoke all on function public.sohs_count_links(text) from public;
revoke all on function public.sohs_require_text(text, text, integer, integer, integer) from public;
revoke all on function public.submit_opinion(uuid, text, text) from public;
revoke all on function public.submit_human_question_answer(uuid, text, text, text) from public;
revoke all on function public.submit_dilemma_vote(uuid, uuid, text) from public;
revoke all on function public.submit_topic_request(text, text, text, text[]) from public;
revoke all on function public.report_opinion(uuid, text, text) from public;
grant execute on function public.submit_opinion(uuid, text, text) to authenticated;
grant execute on function public.submit_human_question_answer(uuid, text, text, text) to authenticated;
grant execute on function public.submit_dilemma_vote(uuid, uuid, text) to authenticated;
grant execute on function public.submit_topic_request(text, text, text, text[]) to authenticated;
grant execute on function public.report_opinion(uuid, text, text) to authenticated;
