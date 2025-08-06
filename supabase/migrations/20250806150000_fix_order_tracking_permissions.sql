-- Fix order tracking permissions
-- This migration ensures customers can properly view their order details

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Owners and Admins can view order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can view order items for their orders" ON public.order_items;

-- Create comprehensive policies for order_items
-- Allow customers to view order items for their own orders
CREATE POLICY "Customers can view their order items"
ON public.order_items FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM public.orders 
    WHERE customer_id = auth.uid()
  )
);

-- Allow restaurant owners to view order items for their restaurant's orders
CREATE POLICY "Restaurant owners can view their order items"
ON public.order_items FOR SELECT
USING (
  (SELECT get_user_role(auth.uid())) = 'owner' AND
  order_id IN (
    SELECT o.id FROM public.orders o
    JOIN public.restaurants r ON o.restaurant_id = r.id
    WHERE r.owner_id = auth.uid()
  )
);

-- Allow admins to view all order items
CREATE POLICY "Admins can view all order items"
ON public.order_items FOR SELECT
USING ((SELECT get_user_role(auth.uid())) = 'admin');

-- Ensure dishes can be read by anyone (needed for order item details)
DROP POLICY IF EXISTS "Allow public read access to dishes" ON public.dishes;
CREATE POLICY "Allow public read access to dishes"
ON public.dishes FOR SELECT
USING (true);

-- Ensure restaurants can be read by anyone (needed for order tracking)
DROP POLICY IF EXISTS "Allow public read access to restaurants" ON public.restaurants;
CREATE POLICY "Allow public read access to restaurants"
ON public.restaurants FOR SELECT
USING (true);