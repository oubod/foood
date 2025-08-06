-- This migration forces PostgREST to reload its schema cache.
-- This is necessary to ensure that new relationships are detected by the API.
NOTIFY pgrst, 'reload schema';
