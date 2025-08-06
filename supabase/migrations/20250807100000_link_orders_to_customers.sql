-- Link Orders to Customers Migration

-- Step 1: Add customer_id to the orders table
ALTER TABLE public.orders
ADD COLUMN customer_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- Step 2: Make customer_name and customer_phone optional
-- They will be automatically fetched from the customer's profile.
ALTER TABLE public.orders
ALTER COLUMN customer_name DROP NOT NULL,
ALTER COLUMN customer_phone DROP NOT NULL;

-- Step 3: Create an index for faster lookups
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);

-- Step 4: Update the create_order function
-- This function will now automatically use the authenticated user's ID
-- and fetch their information from the profiles table.
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

  IF user_profile IS NULL THEN
    RAISE EXCEPTION 'User profile not found. Cannot create order.';
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
    user_profile.full_name,
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

-- Step 5: Update RLS Policies for the orders table
-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Restaurant owners can view their restaurant's orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON public.orders;

-- Allow customers to see their own orders
CREATE POLICY "Users can view their own orders"
ON public.orders FOR SELECT
TO authenticated
USING (customer_id = auth.uid());

-- Allow restaurant owners to view orders for their restaurants
CREATE POLICY "Restaurant owners can view their restaurant's orders"
ON public.orders FOR SELECT
USING (
  (SELECT get_user_role(auth.uid())) = 'owner' AND
  restaurant_id IN (SELECT id FROM public.restaurants WHERE owner_id = auth.uid())
);

-- Allow admins to see all orders
CREATE POLICY "Admins can manage all orders"
ON public.orders FOR SELECT
USING ((SELECT get_user_role(auth.uid())) = 'admin');

-- Enable RLS on order_items table for consistency
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Allow users to see items for orders they have access to
CREATE POLICY "Users can view items for their accessible orders"
ON public.order_items FOR SELECT
USING (
  (SELECT COUNT(*) FROM public.orders WHERE id = order_id) = 1
);
