-- CUSTOM TYPES for roles and order status
create type public.app_role as enum ('admin', 'owner');
create type public.order_status as enum ('preparing', 'ready', 'delivered', 'cancelled');

-- PROFILES table to store user metadata like their role
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  role public.app_role not null default 'owner',
  primary key (id)
);
-- This function allows us to easily check a user's role
create function public.get_user_role(user_id uuid)
returns text
language plpgsql
security definer
as $$
begin
  return (select role from public.profiles where id = user_id);
end;
$$;

-- RESTAURANTS table
create table public.restaurants (
  id uuid not null default gen_random_uuid(),
  created_at timestamp with time zone not null default now(),
  name text not null,
  cuisine text,
  image_url text,
  owner_id uuid references auth.users on delete set null,
  primary key (id)
);

-- DISHES table
create table public.dishes (
  id uuid not null default gen_random_uuid(),
  created_at timestamp with time zone not null default now(),
  name text not null,
  description text,
  price numeric not null,
  image_url text,
  restaurant_id uuid not null references public.restaurants on delete cascade,
  primary key (id)
);

-- ORDERS table
create table public.orders (
  id uuid not null default gen_random_uuid(),
  created_at timestamp with time zone not null default now(),
  customer_name text not null,
  customer_phone text not null,
  customer_location jsonb, -- For storing lat/lng
  restaurant_id uuid not null references public.restaurants on delete cascade,
  status public.order_status not null default 'preparing',
  total_price numeric not null,
  payment_method text not null, -- "electronic" or "cash"
  payment_proof_url text, -- Link to uploaded screenshot
  primary key (id)
);

-- ORDER_ITEMS table (links orders to dishes)
create table public.order_items (
  id uuid not null default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  dish_id uuid not null references public.dishes on delete cascade,
  quantity int not null,
  unit_price numeric not null, -- Store price at time of order
  primary key (id)
);

-- Enable Realtime on our key tables
alter table public.restaurants replica identity full;
alter table public.dishes replica identity full;
alter table public.orders replica identity full;