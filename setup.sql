-- =============================================
-- עזר טילוף — Supabase Setup Script
-- Run this in Supabase SQL Editor
-- =============================================

-- 1. Create cadets table
CREATE TABLE IF NOT EXISTS cadets (
  id SERIAL PRIMARY KEY,
  number INT NOT NULL UNIQUE CHECK (number >= 1 AND number <= 50),
  full_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create checkpoint_status table
CREATE TABLE IF NOT EXISTS checkpoint_status (
  id SERIAL PRIMARY KEY,
  cadet_id INT NOT NULL REFERENCES cadets(id) ON DELETE CASCADE,
  station INT NOT NULL CHECK (station >= 1 AND station <= 4),
  checked BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (cadet_id, station)
);

-- 3. Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger on checkpoint_status
DROP TRIGGER IF EXISTS set_updated_at ON checkpoint_status;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON checkpoint_status
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- 5. Function to auto-create checkpoint rows when a cadet is added
CREATE OR REPLACE FUNCTION create_checkpoints_for_cadet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO checkpoint_status (cadet_id, station, checked)
  VALUES
    (NEW.id, 1, FALSE),
    (NEW.id, 2, FALSE),
    (NEW.id, 3, FALSE),
    (NEW.id, 4, FALSE);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Trigger to auto-create checkpoints on cadet insert
DROP TRIGGER IF EXISTS auto_create_checkpoints ON cadets;
CREATE TRIGGER auto_create_checkpoints
  AFTER INSERT ON cadets
  FOR EACH ROW
  EXECUTE FUNCTION create_checkpoints_for_cadet();

-- 7. Enable Row Level Security
ALTER TABLE cadets ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkpoint_status ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies — public read + write (no auth required)
-- Cadets
DROP POLICY IF EXISTS "Public read cadets" ON cadets;
CREATE POLICY "Public read cadets" ON cadets FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Public insert cadets" ON cadets;
CREATE POLICY "Public insert cadets" ON cadets FOR INSERT WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Public delete cadets" ON cadets;
CREATE POLICY "Public delete cadets" ON cadets FOR DELETE USING (TRUE);

-- Checkpoint status
DROP POLICY IF EXISTS "Public read checkpoints" ON checkpoint_status;
CREATE POLICY "Public read checkpoints" ON checkpoint_status FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Public update checkpoints" ON checkpoint_status;
CREATE POLICY "Public update checkpoints" ON checkpoint_status FOR UPDATE USING (TRUE);

DROP POLICY IF EXISTS "Public insert checkpoints" ON checkpoint_status;
CREATE POLICY "Public insert checkpoints" ON checkpoint_status FOR INSERT WITH CHECK (TRUE);

-- 9. Enable Realtime on both tables
ALTER PUBLICATION supabase_realtime ADD TABLE cadets;
ALTER PUBLICATION supabase_realtime ADD TABLE checkpoint_status;

-- 10. Add comments
ALTER TABLE cadets ADD COLUMN IF NOT EXISTS comment TEXT DEFAULT '';

-- 11. bug fix
CREATE POLICY "Public update cadets" ON cadets FOR UPDATE USING (TRUE);

-- =============================================
-- Done! Now open the app and add cadets via Admin mode.
-- =============================================




