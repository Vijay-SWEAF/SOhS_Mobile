-- Align UGC workflow statuses with the public form behavior.
-- Topic requests enter the editorial queue as "new"; reports enter moderation as "open".

update public.topic_requests
set status = 'new'
where status = 'pending';
alter table public.topic_requests
	alter column status set default 'new';
alter table public.topic_requests
	drop constraint if exists topic_requests_status_check;
alter table public.topic_requests
	add constraint topic_requests_status_check
	check (status in ('new', 'reviewing', 'approved', 'rejected', 'closed'));
comment on column public.topic_requests.status is 'Editorial queue status; user submissions default to new.';
drop policy if exists "topic_requests_insert_own_pending" on public.topic_requests;
create policy "topic_requests_insert_own_new"
on public.topic_requests for insert
to authenticated
with check (user_id = auth.uid() and status = 'new');
update public.opinion_reports
set status = 'open'
where status = 'pending';
alter table public.opinion_reports
	alter column status set default 'open';
alter table public.opinion_reports
	drop constraint if exists opinion_reports_status_check;
alter table public.opinion_reports
	add constraint opinion_reports_status_check
	check (status in ('open', 'reviewed', 'dismissed', 'actioned'));
comment on column public.opinion_reports.status is 'Moderation queue status; user reports default to open.';
drop policy if exists "opinion_reports_insert_own_pending" on public.opinion_reports;
create policy "opinion_reports_insert_own_open"
on public.opinion_reports for insert
to authenticated
with check (
	(reporter_id = auth.uid() or reporter_id is null)
	and status = 'open'
);
