-- TKM Iwi / Hapū / Marae database schema
-- Works in SQLite (drop the GEOMETRY column) or PostgreSQL + PostGIS (as written).
-- Source: Te Kāhui Māngai, https://www.tkm.govt.nz/ (Te Puni Kōkiri)

CREATE TABLE region (
  region_id    TEXT PRIMARY KEY,          -- R01..R13
  region_name  TEXT NOT NULL,
  tkm_url      TEXT,
  notes        TEXT
);

CREATE TABLE iwi (
  iwi_id                TEXT PRIMARY KEY, -- I001..
  iwi_name              TEXT NOT NULL,
  primary_region_id     TEXT REFERENCES region(region_id),
  tkm_url               TEXT UNIQUE,      -- slug in URL is the natural key
  mfa_status            TEXT,             -- 'Recognised iwi in the Māori Fisheries Act 2004' | NULL
  population            INTEGER,
  population_source     TEXT,             -- e.g. 'Census 2013'
  rohe_description      TEXT,
  rohe_map_image_url    TEXT,
  rohe_document_url     TEXT,
  rohe_copyright_holder TEXT,
  rohe_geom             GEOMETRY(MULTIPOLYGON, 4326),  -- load from TPK ArcGIS Iwi Areas of Interest
  tkm_last_updated      DATE,
  notes                 TEXT
);

CREATE TABLE iwi_region (                 -- an iwi may sit in two TKM regions
  iwi_id     TEXT REFERENCES iwi(iwi_id),
  region_id  TEXT REFERENCES region(region_id),
  PRIMARY KEY (iwi_id, region_id)
);

CREATE TABLE iwi_local_authority (
  iwi_id          TEXT REFERENCES iwi(iwi_id),
  authority_type  TEXT CHECK (authority_type IN ('Regional Council','Territorial Authority')),
  authority_name  TEXT NOT NULL,
  PRIMARY KEY (iwi_id, authority_type, authority_name)
);

CREATE TABLE hapu (
  hapu_id   TEXT PRIMARY KEY,             -- H001..
  hapu_name TEXT NOT NULL,
  iwi_id    TEXT NOT NULL REFERENCES iwi(iwi_id),
  notes     TEXT,
  UNIQUE (hapu_name, iwi_id)
);

CREATE TABLE marae (                      -- the geospatial table
  marae_id            TEXT PRIMARY KEY,   -- M0001..
  marae_name          TEXT NOT NULL,
  wharenui            TEXT,
  marae_type          TEXT CHECK (marae_type IN ('Iwi marae','Urban-Community marae','Institutional marae')),
  address_line        TEXT,
  locality            TEXT,
  postcode            TEXT,
  region_council_area TEXT,
  latitude            DOUBLE PRECISION,   -- WGS84
  longitude           DOUBLE PRECISION,
  nztm_easting        DOUBLE PRECISION,   -- EPSG:2193, optional
  nztm_northing       DOUBLE PRECISION,
  geom                GEOMETRY(POINT, 4326),
  geocode_source      TEXT,               -- 'TPK ArcGIS' | 'LINZ' | 'Google' | 'Manual'
  geocode_accuracy    TEXT,               -- 'Exact' | 'Street' | 'Locality' | 'Unknown'
  tkm_url             TEXT,
  notes               TEXT
);
CREATE INDEX marae_geom_idx ON marae USING GIST (geom);

CREATE TABLE marae_hapu (                 -- many-to-many
  marae_id TEXT REFERENCES marae(marae_id),
  hapu_id  TEXT REFERENCES hapu(hapu_id),
  iwi_id   TEXT REFERENCES iwi(iwi_id),
  notes    TEXT,
  PRIMARY KEY (marae_id, hapu_id, iwi_id)
);

CREATE TABLE representative_org (
  org_id                 TEXT PRIMARY KEY, -- O001..
  iwi_id                 TEXT NOT NULL REFERENCES iwi(iwi_id),
  org_name               TEXT NOT NULL,
  org_role               TEXT,            -- Iwi Representative Organisation / Hapū Representative Organisation / Other Iwi Authority (RMA)
  legal_entity           TEXT,
  governance_structure   TEXT,
  flag_treaty_mandate    BOOLEAN DEFAULT FALSE,
  flag_psge              BOOLEAN DEFAULT FALSE,
  flag_mfa_mandated      BOOLEAN DEFAULT FALSE,
  flag_mfa_recognised    BOOLEAN DEFAULT FALSE,
  flag_iao               BOOLEAN DEFAULT FALSE,
  flag_rma_iwi_authority BOOLEAN DEFAULT FALSE,
  flag_tuhono            BOOLEAN DEFAULT FALSE,
  settlement_act         TEXT,
  postal_address         TEXT,
  physical_address       TEXT,
  phone                  TEXT,
  email                  TEXT,
  website                TEXT,
  tkm_last_updated       DATE,
  notes                  TEXT
);

CREATE TABLE contact (
  contact_id TEXT PRIMARY KEY,            -- C001..
  org_id     TEXT NOT NULL REFERENCES representative_org(org_id),
  role       TEXT,                        -- Chair / CEO / RMA Contact / ...
  full_name  TEXT,
  phone      TEXT,
  email      TEXT,
  notes      TEXT
);

-- Flattened view for the web map: one row per marae with pop-up content
CREATE VIEW v_marae_map AS
SELECT
  m.marae_id, m.marae_name, m.wharenui, m.latitude, m.longitude, m.geom,
  trim(coalesce(m.address_line,'') || ' ' || coalesce(m.locality,'')) AS address,
  string_agg(DISTINCT h.hapu_name, '; ')     AS hapu_names,
  string_agg(DISTINCT i.iwi_name, '; ')      AS iwi_names,
  string_agg(DISTINCT r.region_name, '; ')   AS regions,
  string_agg(DISTINCT o.org_name || coalesce(' — ' || o.phone,'') || coalesce(' — ' || o.email,''), '; ') AS representative_orgs,
  string_agg(DISTINCT c.role || ': ' || c.full_name, '; ') FILTER (WHERE c.role IN ('Chair','CEO','RMA Contact')) AS key_contacts,
  m.tkm_url
FROM marae m
LEFT JOIN marae_hapu mh ON mh.marae_id = m.marae_id
LEFT JOIN hapu h  ON h.hapu_id = mh.hapu_id
LEFT JOIN iwi  i  ON i.iwi_id  = mh.iwi_id
LEFT JOIN region r ON r.region_id = i.primary_region_id
LEFT JOIN representative_org o ON o.iwi_id = i.iwi_id
LEFT JOIN contact c ON c.org_id = o.org_id
GROUP BY m.marae_id;

-- Export for Leaflet / Mapbox:
-- SELECT json_build_object('type','FeatureCollection','features',
--   json_agg(json_build_object('type','Feature','geometry',ST_AsGeoJSON(geom)::json,
--   'properties', to_jsonb(v) - 'geom'))) FROM v_marae_map v WHERE geom IS NOT NULL;

-- ---------------- Whakapapa layer ----------------
CREATE TABLE tupuna (
  tupuna_id   TEXT PRIMARY KEY,           -- T001..
  name        TEXT NOT NULL,
  other_names TEXT,
  born        TEXT,                       -- free text, may be approximate
  died        TEXT,
  birthplace  TEXT,
  mother      TEXT,                       -- name or tupuna_id
  father      TEXT,
  notes       TEXT,
  source      TEXT
);

CREATE TABLE tupuna_location (            -- a tupuna can point at many locations of interest
  link_id         TEXT PRIMARY KEY,
  tupuna_id       TEXT NOT NULL REFERENCES tupuna(tupuna_id),
  location_type   TEXT CHECK (location_type IN ('Marae','Hapū','Iwi','Place')),
  location_ref    TEXT NOT NULL,          -- marae/hapū/iwi name, or a label for a Place
  location_detail TEXT,                   -- marae Location text (disambiguation) or block/kāinga detail
  latitude        DOUBLE PRECISION,       -- Place only
  longitude       DOUBLE PRECISION,
  geom            GEOMETRY(POINT, 4326),
  relationship    TEXT CHECK (relationship IN ('Born','Lived','Died','Buried','Affiliated','Land interest','Other')),
  notes           TEXT,
  source          TEXT
);
-- Later: Pātaka Whenua blocks (polygon) + block_owner(tupuna_id, block_id, share) join here.
