-- Drop the table if it already exists to ensure a clean start for the run
DROP TABLE IF EXISTS staging_nyc_311_data;

-- Create the staging table for raw NYC 311 data
-- NOTE: Column types are set to VARCHAR(255) to accommodate the raw string data 
-- loaded directly by Azure Data Factory from the CSV file.
CREATE TABLE staging_nyc_311_data (
    -- Generic columns expected from the 311 API
    unique_key VARCHAR(255),
    created_date VARCHAR(255),
    closed_date VARCHAR(255),
    agency VARCHAR(255),
    agency_name VARCHAR(255),
    complaint_type VARCHAR(255),
    descriptor VARCHAR(255),
    location_type VARCHAR(255),
    incident_zip VARCHAR(255),
    incident_address VARCHAR(255),
    street_name VARCHAR(255),
    cross_street_1 VARCHAR(255),
    cross_street_2 VARCHAR(255),
    borough VARCHAR(255),
    open_data_channel_type VARCHAR(255),

    -- Location fields
    latitude NUMERIC,
    longitude NUMERIC,

    -- Metadata about the load
    load_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE staging_nyc_311_data IS 'Staging table for raw 311 data loaded via ADF from Azure Blob.';
