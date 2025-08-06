-- 1. Enable RLS for all tables we want to protect
alter table public.profiles enable row level security;
alter table public.restaurants enable row level security;
alter table public.dishes enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- 2. POLICIES FOR 'profiles' TABLE
-- Users can see their own profile.
create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

-- 3. POLICIES FOR 'restaurants' TABLE
-- Anyone can view all restaurants.
create policy "Allow public read access to restaurants"
  on public.restaurants for select
  using (true);

-- Admins can create restaurants.
create policy "Admins can create restaurants"
  on public.restaurants for insert
  with check (public.get_user_role(auth.uid()) = 'admin');

-- Owners can update their own restaurant. Admins can update any.
create policy "Owners or Admins can update restaurants"
  on public.restaurants for update
  using (public.get_user_role(auth.uid()) = 'admin' or (public.get_user_role(auth.uid()) = 'owner' and owner_id = auth.uid()))
  with check (public.get_user_role(auth.uid()) = 'admin' or (public.get_user_role(auth.uid()) = 'owner' and owner_id = auth.uid()));

-- Admins can delete restaurants.
create policy "Admins can delete restaurants"
  on public.restaurants for delete
  using (public.get_user_role(auth.uid()) = 'admin');

-- 4. POLICIES FOR 'dishes' TABLE
-- Anyone can view all dishes.
create policy "Allow public read access to dishes"
  on public.dishes for select
  using (true);

-- Owners can add dishes to their own restaurant. Admins can add to any.
create policy "Owners or Admins can create dishes"
  on public.dishes for insert
  with check (
    public.get_user_role(auth.uid()) = 'admin' or
    (
      public.get_user_role(auth.uid()) = 'owner' and
      restaurant_id in (select id from public.restaurants where owner_id = auth.uid())
    )
  );

-- Owners can update their own dishes. Admins can update any.
create policy "Owners or Admins can update dishes"
  on public.dishes for update
  using (
    public.get_user_role(auth.uid()) = 'admin' or
    (
      public.get_user_role(auth.uid()) = 'owner' and
      restaurant_id in (select id from public.restaurants where owner_id = auth.uid())
    )
  );

-- Owners can delete their own dishes. Admins can delete any.
create policy "Owners or Admins can delete dishes"
  on public.dishes for delete
  using (
    public.get_user_role(auth.uid()) = 'admin' or
    (
      public.get_user_role(auth.uid()) = 'owner' and
      restaurant_id in (select id from public.restaurants where owner_id = auth.uid())
    )
  );

-- 5. POLICIES FOR 'orders' & 'order_items' TABLES
-- IMPORTANT: This allows anyone to create an order, as customers are not logged in.
create policy "Allow anyone to create an order"
  on public.orders for insert
  with check (true);

create policy "Allow anyone to create order items"
  on public.order_items for insert
  with check (true);

-- Owners can see orders for their restaurant. Admins can see all.
create policy "Owners and Admins can view orders"
  on public.orders for select
  using (
    public.get_user_role(auth.uid()) = 'admin' or
    (public.get_user_role(auth.uid()) = 'owner' and restaurant_id in (select id from public.restaurants where owner_id = auth.uid()))
  );

-- Link order_items visibility to the parent order's visibility.
create policy "Owners and Admins can view order items"
  on public.order_items for select
  using (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
    )
  );

-- Owners can update status of their orders. Admins can update any.
create policy "Owners and Admins can update orders"
  on public.orders for update
  using (
    public.get_user_role(auth.uid()) = 'admin' or
    (public.get_user_role(auth.uid()) = 'owner' and restaurant_id in (select id from public.restaurants where owner_id = auth.uid()))
  )
  with check (
    public.get_user_role(auth.uid()) = 'admin' or
    (public.get_user_role(auth.uid()) = 'owner' and restaurant_id in (select id from public.restaurants where owner_id = auth.uid()))
  );