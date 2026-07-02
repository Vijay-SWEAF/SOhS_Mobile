-- Promote accepted topic requests into editorial content records.
-- Accepting a topic request means it passed intake review. Promotion is a
-- separate admin/moderator action that creates the editable content draft.

alter table public.topic_requests
	add column if not exists promoted_table text check (
		promoted_table is null
		or promoted_table in ('articles', 'human_questions', 'moral_dilemmas')
	),
	add column if not exists promoted_id uuid,
	add column if not exists promoted_at timestamptz;
comment on column public.topic_requests.promoted_table is
	'Content table created from this accepted topic request, when promoted by an admin/moderator.';
comment on column public.topic_requests.promoted_id is
	'Content record id created from this accepted topic request. Polymorphic; see promoted_table.';
comment on column public.topic_requests.promoted_at is
	'Time this accepted topic request was promoted into an editorial content record.';
alter table public.moderation_actions
	drop constraint if exists moderation_actions_action_check;
alter table public.moderation_actions
	add constraint moderation_actions_action_check
	check (
		action in (
			'approve',
			'reject',
			'flag',
			'hide',
			'restore',
			'archive',
			'note',
			'pending',
			'approved',
			'rejected',
			'flagged',
			'hidden',
			'open',
			'reviewed',
			'dismissed',
			'action_taken',
			'new',
			'reviewing',
			'accepted',
			'promoted'
		)
	);
create or replace function public.sohs_slugify(value text)
returns text
language sql
immutable
as $$
	select trim(both '-' from regexp_replace(regexp_replace(lower(coalesce(value, '')), '[^a-z0-9]+', '-', 'g'), '-+', '-', 'g'));
$$;
create or replace function public.promote_topic_request(
	topic_request_id uuid,
	publish_now boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_moderator_id uuid := auth.uid();
	v_request public.topic_requests%rowtype;
	v_base_slug text;
	v_slug text;
	v_category_id uuid;
	v_content_id uuid;
	v_target_table text;
	v_status text := 'draft';
	v_published_at timestamptz := null;
	v_context text;
	v_summary text;
	v_source text;
	v_sort_order integer := 1;
begin
	if v_moderator_id is null then
		raise exception 'Authentication is required to promote topic requests.';
	end if;

	if not public.is_moderator_or_admin() then
		raise exception 'Only admins and moderators can promote topic requests.';
	end if;

	select *
	into v_request
	from public.topic_requests
	where id = promote_topic_request.topic_request_id
	for update;

	if not found then
		raise exception 'Topic request not found.';
	end if;

	if v_request.status <> 'accepted' then
		raise exception 'Only accepted topic requests can be promoted.';
	end if;

	if v_request.promoted_id is not null and v_request.promoted_table is not null then
		return jsonb_build_object(
			'ok', true,
			'already_promoted', true,
			'target_table', v_request.promoted_table,
			'target_id', v_request.promoted_id
		);
	end if;

	if v_request.topic_type not in ('article', 'human_question', 'moral_dilemma') then
		raise exception 'This topic request type cannot be promoted into public content.';
	end if;

	v_context := btrim(coalesce(v_request.context, ''));
	v_summary := left(coalesce(nullif(v_context, ''), v_request.title), 280);
	v_base_slug := public.sohs_slugify(v_request.title);

	if v_base_slug = '' then
		v_base_slug := 'topic';
	end if;

	if v_request.topic_type = 'article' then
		v_target_table := 'articles';
		v_slug := v_base_slug;

		if exists (select 1 from public.articles where slug = v_slug) then
			v_slug := left(v_base_slug, 52) || '-' || left(v_request.id::text, 8);
		end if;

		select id
		into v_category_id
		from public.categories
		where slug = 'human-ethics'
		order by sort_order
		limit 1;

		if v_category_id is null then
			select id
			into v_category_id
			from public.categories
			where is_active = true
			order by sort_order
			limit 1;
		end if;

		insert into public.articles (
			category_id,
			author_id,
			title,
			slug,
			subtitle,
			summary,
			content_md,
			what_is_happening,
			ethical_question,
			action_step,
			status,
			published_at
		)
		values (
			v_category_id,
			v_moderator_id,
			v_request.title,
			v_slug,
			'Draft created from an accepted SOhS topic request.',
			v_summary,
			'# ' || v_request.title || E'\n\n' || coalesce(nullif(v_context, ''), 'Editorial draft created from an accepted topic request.'),
			coalesce(nullif(v_context, ''), 'Editorial draft created from an accepted topic request.'),
			'What is the human responsibility behind this topic?',
			'Review sources, edit the article, then publish when ready.',
			'draft',
			null
		)
		returning id into v_content_id;

		foreach v_source in array coalesce(v_request.sources, '{}') loop
			v_source := btrim(coalesce(v_source, ''));
			if v_source <> '' then
				insert into public.article_sources (
					article_id,
					label,
					url,
					source_type,
					notes,
					sort_order
				)
				values (
					v_content_id,
					left(v_source, 180),
					case when v_source ~* '^https?://' then v_source else null end,
					'reference',
					'Source suggested in the original topic request.',
					v_sort_order
				);
				v_sort_order := v_sort_order + 1;
			end if;
		end loop;

	elsif v_request.topic_type = 'human_question' then
		v_target_table := 'human_questions';
		v_slug := v_base_slug;

		if exists (select 1 from public.human_questions where slug = v_slug) then
			v_slug := left(v_base_slug, 52) || '-' || left(v_request.id::text, 8);
		end if;

		if publish_now then
			v_status := 'published';
			v_published_at := now();
		end if;

		insert into public.human_questions (
			title,
			slug,
			summary,
			status,
			featured_status,
			published_at
		)
		values (
			v_request.title,
			v_slug,
			v_summary,
			v_status,
			'open',
			v_published_at
		)
		returning id into v_content_id;

	elsif v_request.topic_type = 'moral_dilemma' then
		v_target_table := 'moral_dilemmas';
		v_slug := v_base_slug;

		if exists (select 1 from public.moral_dilemmas where slug = v_slug) then
			v_slug := left(v_base_slug, 52) || '-' || left(v_request.id::text, 8);
		end if;

		insert into public.moral_dilemmas (
			title,
			slug,
			scenario,
			reflection_prompt,
			status,
			published_at
		)
		values (
			v_request.title,
			v_slug,
			coalesce(nullif(v_context, ''), 'Draft dilemma scenario created from an accepted topic request.'),
			'What should a person do, and why?',
			'draft',
			null
		)
		returning id into v_content_id;
	end if;

	update public.topic_requests
	set
		promoted_table = v_target_table,
		promoted_id = v_content_id,
		promoted_at = now()
	where id = v_request.id;

	insert into public.moderation_actions (
		moderator_id,
		target_table,
		target_id,
		action,
		reason
	)
	values (
		v_moderator_id,
		'topic_requests',
		v_request.id,
		'promoted',
		'Promoted accepted topic request into ' || v_target_table || '.'
	);

	return jsonb_build_object(
		'ok', true,
		'already_promoted', false,
		'target_table', v_target_table,
		'target_id', v_content_id,
		'slug', v_slug,
		'status', v_status
	);
end;
$$;
comment on function public.promote_topic_request(uuid, boolean) is
	'Admin/moderator RPC that promotes an accepted topic request into an editorial content record and records the audit action.';
create or replace function public.admin_health_check()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_required_tables text[] := array[
		'profiles',
		'categories',
		'articles',
		'article_sources',
		'opinions',
		'opinion_reports',
		'human_questions',
		'human_question_answers',
		'moral_dilemmas',
		'dilemma_options',
		'dilemma_votes',
		'topic_requests',
		'donations',
		'moderation_actions',
		'visitor_events'
	];
	v_required_views text[] := array[
		'visitor_stats_view'
	];
	v_required_functions text[] := array[
		'moderate_item',
		'promote_topic_request',
		'submit_opinion',
		'submit_human_question_answer',
		'submit_dilemma_vote',
		'submit_topic_request',
		'report_opinion',
		'admin_health_check'
	];
	v_missing_tables text[];
	v_missing_views text[];
	v_missing_functions text[];
begin
	if auth.uid() is null then
		raise exception 'Authentication is required to run admin health checks.';
	end if;

	if not public.is_moderator_or_admin() then
		raise exception 'Only admins and moderators can run admin health checks.';
	end if;

	select coalesce(array_agg(required_name order by required_name), '{}')
	into v_missing_tables
	from unnest(v_required_tables) as required_name
	where not exists (
		select 1
		from information_schema.tables
		where table_schema = 'public'
			and table_type = 'BASE TABLE'
			and table_name = required_name
	);

	select coalesce(array_agg(required_name order by required_name), '{}')
	into v_missing_views
	from unnest(v_required_views) as required_name
	where not exists (
		select 1
		from information_schema.views
		where table_schema = 'public'
			and table_name = required_name
	);

	select coalesce(array_agg(required_name order by required_name), '{}')
	into v_missing_functions
	from unnest(v_required_functions) as required_name
	where not exists (
		select 1
		from pg_proc p
		join pg_namespace n on n.oid = p.pronamespace
		where n.nspname = 'public'
			and p.proname = required_name
	);

	return jsonb_build_object(
		'ok',
		cardinality(v_missing_tables) = 0
			and cardinality(v_missing_views) = 0
			and cardinality(v_missing_functions) = 0,
		'missing_tables',
		v_missing_tables,
		'missing_views',
		v_missing_views,
		'missing_functions',
		v_missing_functions
	);
end;
$$;
revoke all on function public.sohs_slugify(text) from public;
revoke all on function public.promote_topic_request(uuid, boolean) from public;
grant execute on function public.promote_topic_request(uuid, boolean) to authenticated;
