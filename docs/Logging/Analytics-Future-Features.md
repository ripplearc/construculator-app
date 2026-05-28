# Analytics — Future Features Planning

> Extracted from the [PostHog Integration Guide](Posthog-Integration.md) per reviewer request.
> Add new planned features here as they are scoped. Move events to [PostHog Event Tracking](PostHog-Event-Tracking.md) once instrumented.

---

## Global Search

**Events to Track:**
- `search_performed` — user initiates search
  - Properties: `query`, `search_type` (global/project/estimation), `results_count`
- `search_result_clicked` — user clicks a result
  - Properties: `query`, `result_type` (project/estimation), `result_position`
- `search_filter_applied`
  - Properties: `filter_type`, `filter_value`

**Funnels:**
- Search Engagement: `search_performed` → `search_result_clicked` → `estimation_viewed`

**Key Metrics:**
- Search usage rate (% of users who search)
- Average results per search
- Click-through rate on results
- Zero-result searches (improvement opportunities)

---

## Project Switching

**Events to Track:**
- `project_dropdown_clicked` — user opens project switcher
- `project_search_performed` — user searches within the switcher
- `project_switched`
  - Properties: `from_project_id`, `to_project_id`, `switch_method` (dropdown/search)

**Funnels:**
- Project Switch Flow: `project_dropdown_clicked` → `project_switched`

**Group Analytics:**
- Track which projects users switch between most (project affinity)

---

## File Attachments

**Events to Track:**
- `attachment_button_clicked`
- `file_upload_started`
  - Properties: `file_type`, `file_size_bytes`
- `file_uploaded`
  - Properties: `file_type`, `file_size_bytes`, `upload_duration_ms`
- `file_upload_failed`
  - Properties: `error_type`, `file_type`, `file_size_bytes`
- `file_downloaded`
- `file_deleted`

**Funnels:**
- Upload Success: `file_upload_started` → `file_uploaded`
- Engagement: `file_uploaded` → `file_downloaded`

**Key Metrics:** Upload success rate, average file size, most common file types, download rate

**Feature Flags:**
- `file_attachments_enabled` — gate by user plan
- `max_file_size_mb` — remote config via JSON payload

---

## Cost Files (Templates / Exports)

**Events to Track:**
- `template_selected`
  - Properties: `template_id`, `template_name`
- `estimation_exported`
  - Properties: `export_format` (PDF/Excel/CSV), `estimation_id`
- `export_shared`
  - Properties: `share_method` (email/link)

**A/B Tests:**
- Export format preference: PDF vs Excel
- Template picker UI: list vs gallery view
