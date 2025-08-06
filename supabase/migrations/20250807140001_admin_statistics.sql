-- Admin Statistics Functions

CREATE OR REPLACE FUNCTION get_system_statistics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    stats JSON;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    SELECT json_build_object(
        'users', json_build_object(
            'total', (SELECT COUNT(*) FROM profiles),
            'customers', (SELECT COUNT(*) FROM profiles WHERE role IS NULL),
            'owners', (SELECT COUNT(*) FROM profiles WHERE role = 'owner'),
            'admins', (SELECT COUNT(*) FROM profiles WHERE role = 'admin'),
            'new_today', (SELECT COUNT(*) FROM profiles WHERE created_at >= CURRENT_DATE),
            'new_this_week', (SELECT COUNT(*) FROM profiles WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
            'new_this_month', (SELECT COUNT(*) FROM profiles WHERE created_at >= CURRENT_DATE - INTERVAL '30 days')
        ),
        'restaurants', json_build_object(
            'total', (SELECT COUNT(*) FROM restaurants),
            'active', (SELECT COUNT(*) FROM restaurants WHERE owner_id IS NOT NULL),
            'pending_approval', (SELECT COUNT(*) FROM restaurants WHERE owner_id IS NULL),
            'new_this_month', (SELECT COUNT(*) FROM restaurants WHERE created_at >= CURRENT_DATE - INTERVAL '30 days')
        ),
        'orders', json_build_object(
            'total', (SELECT COUNT(*) FROM orders),
            'today', (SELECT COUNT(*) FROM orders WHERE created_at >= CURRENT_DATE),
            'this_week', (SELECT COUNT(*) FROM orders WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
            'this_month', (SELECT COUNT(*) FROM orders WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'),
            'completed', (SELECT COUNT(*) FROM orders WHERE status = 'delivered'),
            'cancelled', (SELECT COUNT(*) FROM orders WHERE status = 'cancelled'),
            'in_progress', (SELECT COUNT(*) FROM orders WHERE status NOT IN ('delivered', 'cancelled'))
        ),
        'revenue', json_build_object(
            'total', COALESCE((SELECT SUM(total_price) FROM orders WHERE status = 'delivered'), 0),
            'today', COALESCE((SELECT SUM(total_price) FROM orders WHERE status = 'delivered' AND created_at >= CURRENT_DATE), 0),
            'this_week', COALESCE((SELECT SUM(total_price) FROM orders WHERE status = 'delivered' AND created_at >= CURRENT_DATE - INTERVAL '7 days'), 0),
            'this_month', COALESCE((SELECT SUM(total_price) FROM orders WHERE status = 'delivered' AND created_at >= CURRENT_DATE - INTERVAL '30 days'), 0)
        )
    ) INTO stats;

    RETURN stats;
END;
$$;
