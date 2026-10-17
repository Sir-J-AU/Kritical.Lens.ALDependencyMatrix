-- Kritical Lens™ — Wave Telemetry Warehouse (.5128j)
-- KriticalBrain.dbo on .\SQLEXPRESS (per CLAUDE.md DATA-STORAGE-CANONICAL TIER 2)
-- Apply: sqlcmd -S .\SQLEXPRESS -d KriticalBrain -E -i ALBrain/contracts/sql-ddl-wave-telemetry.sql

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='lens_wave_telemetry')
CREATE TABLE dbo.lens_wave_telemetry (
  telemetry_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
  ingested_utc      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  -- Identity
  wave_id           VARCHAR(200) NOT NULL,
  iter_id           INT NULL,
  pillar            VARCHAR(60) NULL,
  subproject        VARCHAR(40) NULL,                 -- via Lens-QueueConsolidator classifier
  preset_active     VARCHAR(40) NULL,                 -- parallel-1x / parallel-4x / etc
  max_parallel      INT NULL,
  pace_mode         VARCHAR(20) NULL,
  -- Lifecycle
  picked_utc        DATETIME2 NULL,
  started_utc       DATETIME2 NULL,
  shipped_utc       DATETIME2 NULL,
  status_final      VARCHAR(20) NULL,                 -- shipped / failed / deferred / blocked / verifying
  verdict           VARCHAR(20) NULL,                 -- PASS / FAIL / WARN
  -- Throughput
  duration_ms       BIGINT NULL,                      -- end-to-end including verify
  api_duration_ms   BIGINT NULL,                      -- Anthropic API time only
  ttft_ms           BIGINT NULL,                      -- time-to-first-token
  num_turns         INT NULL,
  tokens_input      BIGINT NULL,
  tokens_output     BIGINT NULL,
  tokens_cache_create BIGINT NULL,
  tokens_cache_read BIGINT NULL,
  cost_usd          DECIMAL(10,4) NULL,               -- Anthropic-computed equivalent
  -- Provider
  provider          VARCHAR(40) NULL,                 -- claude-code / codex / scx / hermes
  model             VARCHAR(60) NULL,
  bin_path          VARCHAR(500) NULL,
  -- Outcome flags
  saw_success       BIT NULL,
  saw_max_turns     BIT NULL,
  was_429           BIT NULL,
  saw_autocompact   BIT NULL,
  thinking_block_err BIT NULL,
  timed_out         BIT NULL,
  hole_in_one       BIT NULL,                         -- success first try (retry_count=0)
  -- Retry context
  retry_count       INT NULL,
  last_fail_reason  VARCHAR(120) NULL,
  -- System
  mem_pct_at_start  DECIMAL(5,2) NULL,
  cpu_pct_at_start  DECIMAL(5,2) NULL,
  -- Git
  commit_sha        CHAR(40) NULL,
  files_changed     INT NULL,
  lines_added       INT NULL,
  lines_deleted     INT NULL,
  -- Raw refs
  receipt_path      VARCHAR(500) NULL,
  spawn_log_path    VARCHAR(500) NULL,
  raw_stdout_head   NVARCHAR(MAX) NULL,
  INDEX ix_wave (wave_id),
  INDEX ix_subproject (subproject),
  INDEX ix_shipped (shipped_utc),
  INDEX ix_status (status_final),
  INDEX ix_preset (preset_active)
);

-- Per-iter aggregate (one row per supervisor iter, regardless of waves picked)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='lens_iter_telemetry')
CREATE TABLE dbo.lens_iter_telemetry (
  iter_id           BIGINT IDENTITY(1,1) PRIMARY KEY,
  iter_started_utc  DATETIME2 NOT NULL,
  iter_ended_utc    DATETIME2 NULL,
  iter_duration_ms  BIGINT NULL,
  waves_picked      INT DEFAULT 0,
  waves_shipped     INT DEFAULT 0,
  waves_failed      INT DEFAULT 0,
  budget_hourly_usd DECIMAL(10,4) NULL,
  budget_consumed   DECIMAL(10,4) NULL,
  budget_remaining  DECIMAL(10,4) NULL,
  mem_pct_avg       DECIMAL(5,2) NULL,
  preset_active     VARCHAR(40) NULL,
  parallel_actual   INT NULL,
  parallel_configured INT NULL,
  quota_pct_used    DECIMAL(5,2) NULL,
  network_bytes_tx  BIGINT NULL,
  network_bytes_rx  BIGINT NULL,
  INDEX ix_iter_start (iter_started_utc)
);

-- Mining views (the "what do we actually use" + "where the holes are")
IF EXISTS (SELECT 1 FROM sys.views WHERE name='vw_lens_wave_holes_in_one')
  DROP VIEW dbo.vw_lens_wave_holes_in_one;
GO
CREATE VIEW dbo.vw_lens_wave_holes_in_one AS
  SELECT wave_id, subproject, pillar, duration_ms, num_turns, cost_usd, tokens_output, shipped_utc
  FROM dbo.lens_wave_telemetry
  WHERE hole_in_one = 1 AND verdict = 'PASS';
GO

IF EXISTS (SELECT 1 FROM sys.views WHERE name='vw_lens_throughput_per_preset')
  DROP VIEW dbo.vw_lens_throughput_per_preset;
GO
CREATE VIEW dbo.vw_lens_throughput_per_preset AS
  SELECT preset_active, COUNT(*) AS total_waves,
         AVG(CAST(duration_ms AS BIGINT)) AS avg_duration_ms,
         AVG(num_turns) AS avg_turns,
         AVG(cost_usd) AS avg_cost_usd,
         SUM(CASE WHEN status_final='shipped' THEN 1 ELSE 0 END) AS shipped,
         SUM(CASE WHEN status_final='failed'  THEN 1 ELSE 0 END) AS failed,
         100.0 * SUM(CASE WHEN status_final='shipped' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS pct_success
  FROM dbo.lens_wave_telemetry
  GROUP BY preset_active;
GO

IF EXISTS (SELECT 1 FROM sys.views WHERE name='vw_lens_fail_pareto')
  DROP VIEW dbo.vw_lens_fail_pareto;
GO
CREATE VIEW dbo.vw_lens_fail_pareto AS
  -- .5128k — ORDER BY removed; SQL Server disallows in views without TOP/OFFSET.
  -- Caller should ORDER BY occurrences DESC at query time.
  SELECT last_fail_reason, COUNT(*) AS occurrences,
         AVG(duration_ms) AS avg_duration_ms,
         AVG(cost_usd) AS avg_cost_burnt,
         SUM(cost_usd) AS total_cost_wasted
  FROM dbo.lens_wave_telemetry
  WHERE status_final='failed' AND last_fail_reason IS NOT NULL
  GROUP BY last_fail_reason;
GO

IF EXISTS (SELECT 1 FROM sys.views WHERE name='vw_lens_subproject_burn')
  DROP VIEW dbo.vw_lens_subproject_burn;
GO
CREATE VIEW dbo.vw_lens_subproject_burn AS
  SELECT subproject, COUNT(*) AS waves,
         SUM(cost_usd) AS total_cost,
         SUM(tokens_input + tokens_output) AS total_tokens,
         SUM(duration_ms)/1000.0/60 AS total_minutes,
         100.0 * SUM(CASE WHEN status_final='shipped' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS pct_success
  FROM dbo.lens_wave_telemetry
  GROUP BY subproject;
GO
