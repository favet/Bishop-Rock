extends MainLoop

func _init() -> void:
	var state := RunState.new()
	state.telemetry_enabled = false
	state.reset_campaign(42)
	assert(state.day == 1)
	assert(state.hull == 85)
	assert(state.energy_today == 4)
	assert(state.raid_profile()["wave_size"] < 24)
	assert(state.raid_profile()["heavy_weight"] == 0.0)
	assert(state.perform_action("gather_driftwood").contains("timber"))
	assert(state.wood == 12)
	assert(state.perform_action("make_tool").begins_with("Missing"))
	state.scrap = 5
	assert(state.perform_action("make_tool").contains("part"))
	assert(state.tools == 1)
	state.food = 4
	assert(state.perform_action("hearty_supper").contains("Tomorrow"))
	assert(state.perform_action("hearty_supper").contains("done for today"))
	state.start_day()
	assert(state.energy_today == 6, "supper must add +2 Daylight next dawn")

	# The forecast is the plan the spawner consumes — same seed, same list.
	var plan := state.night_plan()
	assert(plan.size() == int(state.raid_profile()["wave_size"]))
	assert(plan == state.night_plan(), "night plan must be deterministic")
	assert(state.forecast_text().contains("boats") or state.forecast_text().contains("skiff"))

func _process(_delta: float) -> bool:
	return true
