CREATE INDEX IF NOT EXISTS idx_country_name_partition ON country_name (partition);
CREATE INDEX IF NOT EXISTS idx_country_name_country_code ON country_name (country_code);