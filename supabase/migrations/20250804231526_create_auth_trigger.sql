-- This function is triggered when a new user signs up.
-- It automatically creates a corresponding row in our public.profiles table.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, role)
  values (new.id, 'owner'); -- Defaults every new user to the 'owner' role
  return new;
end;
$$;

-- This trigger calls the function after a new user is created.
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();