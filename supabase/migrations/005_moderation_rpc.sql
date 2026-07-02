-- Atomic moderation RPC for SOhS admin/moderator actions.
-- This keeps the audit log insert and target status update in one database
-- transaction and avoids split browser-side writes.

alter table public.opinion_reports
	drop constraint if exists opinion_reports_status_check;
update public.opinion_reports
set status = 'action_taken'
where status = 'actioned';
alter table public.opinion_reports
	add constraint opinion_reports_status_check
	check (status in ('open', 'reviewed', 'dismissed', 'action_taken'));
comment on column public.opinion_reports.status is 'Moderation queue status; user reports default to open.';
alter table public.topic_requests
	drop constraint if exists topic_requests_status_check;
update public.topic_requests
set status = 'accepted'
where status = 'approved';
update public.topic_requests
set status = 'rejected'
where status = 'closed';
alter table public.topic_requests
	add constraint topic_requests_status_check
	check (status in ('new', 'reviewing', 'accepted', 'rejected'));
comment on column public.topic_requests.status is 'Editorial queue status; user submissions default to new.';
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
			'accepted'
		)
	);
create or replace function public.moderate_item(
	target_type text,
	target_id uuid,
	new_status text,
	action_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_target_type text := lower(trim($1));
	v_target_id uuid := $2;
	v_new_status text := lower(trim($3));
	v_action_reason text := nullif(trim($4), '');
	v_moderator_id uuid := auth.uid();
	v_target_table text;
	v_rows_updated integer;
begin
	if v_moderator_id is null then
		raise exception 'Authentication is required to moderate content.';
	end if;

	if not public.is_moderator_or_admin() then
		raise exception 'Only admins and moderators can moderate content.';
	end if;

	case v_target_type
		when 'opinion' then
			if v_new_status not in ('pending', 'approved', 'rejected', 'flagged', 'hidden') then
				raise exception 'Invalid opinion moderation status: %', v_new_status;
			end if;

			update public.opinions
			set status = v_new_status
			where id = v_target_id;

			v_target_table := 'opinions';

		when 'opinion_report' then
			if v_new_status not in ('open', 'reviewed', 'dismissed', 'action_taken') then
				raise exception 'Invalid opinion report moderation status: %', v_new_status;
			end if;

			update public.opinion_reports
			set status = v_new_status
			where id = v_target_id;

			v_target_table := 'opinion_reports';

		when 'human_question_answer' then
			if v_new_status not in ('pending', 'approved', 'rejected', 'flagged', 'hidden') then
				raise exception 'Invalid human question answer moderation status: %', v_new_status;
			end if;

			update public.human_question_answers
			set status = v_new_status
			where id = v_target_id;

			v_target_table := 'human_question_answers';

		when 'dilemma_vote' then
			if v_new_status not in ('pending', 'approved', 'rejected', 'flagged', 'hidden') then
				raise exception 'Invalid dilemma vote moderation status: %', v_new_status;
			end if;

			update public.dilemma_votes
			set status = v_new_status
			where id = v_target_id;

			v_target_table := 'dilemma_votes';

		when 'topic_request' then
			if v_new_status not in ('new', 'reviewing', 'accepted', 'rejected') then
				raise exception 'Invalid topic request moderation status: %', v_new_status;
			end if;

			update public.topic_requests
			set status = v_new_status
			where id = v_target_id;

			v_target_table := 'topic_requests';

		else
			raise exception 'Unsupported moderation target type: %', v_target_type;
	end case;

	get diagnostics v_rows_updated = row_count;

	if v_rows_updated <> 1 then
		raise exception 'Moderation target not found: % %', v_target_type, v_target_id;
	end if;

	insert into public.moderation_actions (
		moderator_id,
		target_table,
		target_id,
		action,
		reason
	)
	values (
		v_moderator_id,
		v_target_table,
		v_target_id,
		v_new_status,
		v_action_reason
	);

	return jsonb_build_object('ok', true);
end;
$$;
comment on function public.moderate_item(text, uuid, text, text) is
	'Atomically updates a moderation target status and writes a moderation_actions audit record. Authenticated admin/moderator role required.';
revoke all on function public.moderate_item(text, uuid, text, text) from public;
grant execute on function public.moderate_item(text, uuid, text, text) to authenticated;
