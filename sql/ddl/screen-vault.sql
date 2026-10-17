
-- Kritical Lens™ — Screen Capture Vault (.5125 / WAVE-5132)
-- Database: KriticalBrain on .\SQLEXPRESS (per CLAUDE.md DATA-STORAGE-CANONICAL TIER 2)

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'lens_screen_capture')
CREATE TABLE dbo.lens_screen_capture (
  capture_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
  utc             DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  app             VARCHAR(40) NOT NULL,
  version_tag     VARCHAR(80) NOT NULL,
  route           VARCHAR(200) NOT NULL,
  viewport        VARCHAR(20) NOT NULL,
  http_status     INT,
  visual_hash     CHAR(64) NOT NULL,
  png_bytes       INT NOT NULL,
  png_path        VARCHAR(500) NOT NULL,
  html_sha256     CHAR(64),
  dom_node_count  INT,
  load_time_ms    INT,
  INDEX ix_app_version (app, version_tag),
  INDEX ix_route (route),
  INDEX ix_hash (visual_hash)
);

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'lens_screen_diff')
CREATE TABLE dbo.lens_screen_diff (
  diff_id          BIGINT IDENTITY(1,1) PRIMARY KEY,
  utc              DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  app              VARCHAR(40) NOT NULL,
  route            VARCHAR(200) NOT NULL,
  viewport         VARCHAR(20) NOT NULL,
  version_a        VARCHAR(80) NOT NULL,
  version_b        VARCHAR(80) NOT NULL,
  visual_changed   BIT NOT NULL,
  pixel_diff_pct   DECIMAL(5,2),
  dom_node_delta   INT,
  diff_class       VARCHAR(30),  -- 'IDENTICAL' / 'COSMETIC' / 'CONTENT' / 'STRUCTURAL'
  INDEX ix_app_route (app, route),
  INDEX ix_ver_pair (version_a, version_b)
);

-- Pairwise diff materialization (window-function lazy, materialized only as needed)
IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_lens_screen_churn_per_route')
EXEC ('CREATE VIEW dbo.vw_lens_screen_churn_per_route AS
  SELECT app, route, viewport,
         COUNT(DISTINCT visual_hash) AS unique_visual_states,
         COUNT(*) AS total_captures,
         MIN(utc) AS first_seen, MAX(utc) AS last_seen
  FROM dbo.lens_screen_capture
  GROUP BY app, route, viewport');
