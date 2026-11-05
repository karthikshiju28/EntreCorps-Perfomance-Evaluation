-- Private storage for per-project evaluation reports (e.g. FA26 midpoint PDFs).
-- File path: <project_id>/<cycle_id>.pdf
-- Read: SLT, or the PM / SC / External Lead of that project. Upload/replace/delete: SLT only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('reports', 'reports', false, 10485760, array['application/pdf'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function can_read_report(object_name text) returns boolean
language sql stable security definer set search_path = public as $$
  select is_slt() or exists (
    select 1 from my_led_projects() pid
    where pid::text = (storage.foldername(object_name))[1]
  )
$$;
revoke execute on function can_read_report(text) from anon, public;
grant execute on function can_read_report(text) to authenticated;

drop policy if exists reports_read on storage.objects;
create policy reports_read on storage.objects for select to authenticated
  using (bucket_id = 'reports' and can_read_report(name));

drop policy if exists reports_slt_insert on storage.objects;
create policy reports_slt_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'reports' and is_slt());

drop policy if exists reports_slt_update on storage.objects;
create policy reports_slt_update on storage.objects for update to authenticated
  using (bucket_id = 'reports' and is_slt()) with check (bucket_id = 'reports' and is_slt());

drop policy if exists reports_slt_delete on storage.objects;
create policy reports_slt_delete on storage.objects for delete to authenticated
  using (bucket_id = 'reports' and is_slt());
