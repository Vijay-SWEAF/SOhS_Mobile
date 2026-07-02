-- Harden profile self-update policy without blocking moderators/admins.
--
-- Prior policy required role = 'user' in WITH CHECK, which blocked moderator/admin
-- accounts from updating safe profile fields. This migration allows self-updates for
-- any role while requiring the role value to remain unchanged.

create or replace function public.profile_role_matches_current_user(next_role text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
	select exists (
		select 1
		from public.profiles
		where id = auth.uid()
			and role = next_role
	);
$$;
comment on function public.profile_role_matches_current_user(text) is
	'Checks whether the proposed profile role matches the current authenticated user role.';
drop policy if exists "profiles_update_own_safe_fields" on public.profiles;
create policy "profiles_update_own_safe_fields"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (
	id = auth.uid()
	and public.profile_role_matches_current_user(role)
);
