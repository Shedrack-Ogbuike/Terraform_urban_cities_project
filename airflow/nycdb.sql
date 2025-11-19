-- This script performs the final transformation and loading (T) after ADF (L) completes.

-- 1. Create the Final Production Table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.nyc_311_requests_final (
    request_id          BIGINT PRIMARY KEY,
    created_at          TIMESTAMP,
    closed_at           TIMESTAMP,
    complaint_category  TEXT,
    borough             VARCHAR(50),
    location_zip        VARCHAR(10),
    location_lat        NUMERIC,
    location_lon        NUMERIC,
    agency              TEXT,
    etl_load_date       TIMESTAMP DEFAULT NOW()
);

-- 2. Insert and Transform Data from Staging to Final (FIXED for robust casting and old PG version)
INSERT INTO public.nyc_311_requests_final (
    request_id,
    created_at,
    closed_at,
    complaint_category,
    borough,
    location_zip,
    location_lat,
    location_lon,
    agency
)
SELECT
    -- FIX: Safely cast unique_key to BIGINT, or NULL if it contains non-numeric data
    CASE WHEN TRIM(T1.unique_key) ~ '^[0-9]+$' THEN CAST(TRIM(T1.unique_key) AS BIGINT) ELSE NULL END AS request_id,
    NULLIF(T1.created_date, '')::TIMESTAMP,
    NULLIF(T1.closed_date, '')::TIMESTAMP,
    TRIM(T1.complaint_type),
    UPPER(TRIM(T1.borough)),
    TRIM(T1.incident_zip),
    T1.latitude,
    T1.longitude,
    T1.agency
FROM
    public.staging_nyc_311_data T1
WHERE NOT EXISTS (
    -- FIX: Replaces ON CONFLICT, checks if request_id already exists using the safe cast
    SELECT 1 
    FROM public.nyc_311_requests_final T2
    WHERE T2.request_id = CASE WHEN TRIM(T1.unique_key) ~ '^[0-9]+$' THEN CAST(TRIM(T1.unique_key) AS BIGINT) ELSE NULL END
)
-- FIX: Only attempt insert if unique_key is a valid number to avoid PRIMARY KEY constraint failure on NULL
AND TRIM(T1.unique_key) ~ '^[0-9]+$';

-- 3. Cleanup: Drop the staging table after a successful transformation
DROP TABLE public.staging_nyc_311_data;
