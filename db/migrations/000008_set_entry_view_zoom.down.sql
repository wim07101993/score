ALTER TABLE set_entry_views
    DROP CONSTRAINT IF EXISTS set_entry_views_zoom_check;
ALTER TABLE set_entry_views
    DROP COLUMN IF EXISTS zoom;
