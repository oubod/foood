-- POLICY 1: Allow public, anonymous access to VIEW images.
create policy "Allow public read access to food images"
  on storage.objects for select
  using ( bucket_id = 'food-images' ); -- CORRECTED NAME

-- POLICY 2: Allow authenticated 'admins' or 'owners' to UPLOAD images.
create policy "Allow owners and admins to upload images"
  on storage.objects for insert
  with check (
    bucket_id = 'food-images' AND -- CORRECTED NAME
    (public.get_user_role(auth.uid()) = 'admin' OR public.get_user_role(auth.uid()) = 'owner')
  );

-- POLICY 3: Allow authenticated 'admins' or 'owners' to UPDATE images.
create policy "Allow owners and admins to update images"
  on storage.objects for update
  using (
    bucket_id = 'food-images' AND -- CORRECTED NAME
    (public.get_user_role(auth.uid()) = 'admin' OR public.get_user_role(auth.uid()) = 'owner')
  );

-- POLICY 4: Allow authenticated 'admins' or 'owners' to DELETE images.
create policy "Allow owners and admins to delete images"
  on storage.objects for delete
  using (
    bucket_id = 'food-images' AND -- CORRECTED NAME
    (public.get_user_role(auth.uid()) = 'admin' OR public.get_user_role(auth.uid()) = 'owner')
  );