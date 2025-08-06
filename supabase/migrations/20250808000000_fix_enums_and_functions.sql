-- Fix app enums and create_order function
-- This migration addresses the PostgreSQL exceptions in the app

-- Step 1: Add 'customer' to app_role enum
ALTER TYPE public.app_role ADD VALUE 'customer';

-- Step 2: Add 'pending_payment' to order_status enum
ALTER TYPE public.order_status ADD VALUE 'pending_payment';

-- Step 3: Fix the create_order function to match the current calling pattern
-- The app is calling it with parameters that don't match the function signature
CREATE OR REPLACE FUNCTION public.create_order(
  restaurant_id uuid,
  total_price numeric,
  payment_method text,
  order_items jsonb,
  payment_proof_url text DEFAULT NULL,
  customer_location jsonb DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_order_id uuid;
  item jsonb;
  initial_status public.order_status;
  user_profile record;
BEGIN
  -- Get the profile of the currently authenticated user
  SELECT * INTO user_profile FROM public.profiles WHERE id = auth.uid();

  -- If no profile exists, create a default customer profile
  IF user_profile IS NULL THEN
    -- Get user email from auth.users
    INSERT INTO public.profiles (id, role, full_name)
    SELECT auth.uid(), 'customer', COALESCE(raw_user_meta_data->>'full_name', 'ضيف')
    FROM auth.users 
    WHERE id = auth.uid();
    
    -- Get the newly created profile
    SELECT * INTO user_profile FROM public.profiles WHERE id = auth.uid();
  END IF;

  -- If still no profile (shouldn't happen), create minimal profile
  IF user_profile IS NULL THEN
    INSERT INTO public.profiles (id, role, full_name) 
    VALUES (auth.uid(), 'customer', 'ضيف');
    
    SELECT * INTO user_profile FROM public.profiles WHERE id = auth.uid();
  END IF;

  -- Set initial status based on payment method
  IF payment_method = 'electronic' THEN
    initial_status := 'pending_payment';
  ELSE
    initial_status := 'preparing';
  END IF;

  -- Insert the new order
  INSERT INTO public.orders (
    customer_id,
    customer_name,
    customer_phone,
    customer_location,
    restaurant_id,
    total_price,
    payment_method,
    payment_proof_url,
    status
  ) VALUES (
    auth.uid(),
    COALESCE(user_profile.full_name, 'ضيف'),
    user_profile.phone,
    create_order.customer_location,
    create_order.restaurant_id,
    create_order.total_price,
    create_order.payment_method,
    create_order.payment_proof_url,
    initial_status
  ) RETURNING id INTO new_order_id;

  -- Insert order items
  FOR item IN SELECT * FROM jsonb_array_elements(create_order.order_items)
  LOOP
    INSERT INTO public.order_items (order_id, dish_id, quantity, unit_price)
    VALUES (
      new_order_id,
      (item->>'dish_id')::uuid,
      (item->>'quantity')::int,
      (item->>'unit_price')::numeric
    );
  END LOOP;

  RETURN new_order_id;
END;
$$;

-- Step 4: Update the user profile creation trigger to default to 'customer' instead of 'owner'
-- for regular user registrations
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY definer SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer')::public.app_role,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$;

-- Step 5: Update RLS policies to include customers
-- Allow customers to insert orders (needed for order creation)
CREATE POLICY "Authenticated users can create orders" ON public.orders
FOR INSERT TO authenticated WITH CHECK (true);

-- Allow customers to view their own orders (update existing policy)
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
CREATE POLICY "Users can view their own orders"
ON public.orders FOR SELECT
TO authenticated
USING (customer_id = auth.uid());

-- Step 6: Update order_items policies
-- Allow users to view order items for their orders
CREATE POLICY "Users can view order items for their orders" ON public.order_items
FOR SELECT TO authenticated
USING (
  order_id IN (
    SELECT id FROM public.orders WHERE customer_id = auth.uid()
  )
);

-- Allow users to insert order items for their orders (during order creation)
CREATE POLICY "Users can create order items" ON public.order_items
FOR INSERT TO authenticated WITH CHECK (true);