-- This function is triggered when a new user signs up.
-- It automatically creates a corresponding row in our public.profiles table,
-- extracting the role, full name, and phone from the user's metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone',
    COALESCE(new.raw_user_meta_data->>'role', 'customer') -- Default to 'customer' if not provided
  );
  return new;
end;
$$;

-- This trigger calls the function after a new user is created.
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();