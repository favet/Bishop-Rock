# tests/

Hand-rolled headless checks (no framework yet — adopt GUT/gdUnit4 when they outgrow this):

- `campaign_state_check.gd`, `campaign_loop_check.gd` — pure `RunState` logic. Run with
  `godot --headless --script res://tests/campaign_loop_check.gd --path .`
- `DayUiCheck.tscn` / `day_ui_check.gd` — boots Main and asserts the day-UI clarity contract
  (core-only top bar, Daylight token ghost preview, honest hull bar, fixed Start Night,
  inspectable unaffordable projects). Run with
  `godot --headless --path . res://tests/DayUiCheck.tscn`
- `ScreenshotRunner.tscn` — drives a night and saves screenshots to `user://`.
