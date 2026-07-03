extends MainLoop

func _init() -> void:
	var state := RunState.new()
	state.telemetry_enabled = false
	state.reset_campaign(7)
	assert(state.raid_profile()["wave_size"] == 3)
	assert(state.raid_profile()["fast_weight"] == 0.0)
	assert(state.raid_profile()["heavy_weight"] == 0.0)
	assert(state.raid_profile()["max_simultaneous"] == 1)
	assert(not state.turret_unlocked)
	assert(state.perform_action("gather_driftwood").contains("timber"))
	assert(state.wood == 12)

	state.gold = 20
	state.scrap = 5
	state.tools = 1
	assert(state.start_project("lens_crank_1").contains("Started"))
	assert(state.work_project("lens_crank_1").contains("Completed"))
	assert(state.beam_turn_multiplier() > 1.0)

	state.gold = 40
	state.scrap = 12
	state.tools = 2
	assert(state.start_project("rusty_autoturret").contains("Started"))
	state.energy_today = 4
	state.work_project("rusty_autoturret")
	state.work_project("rusty_autoturret")
	assert(state.work_project("rusty_autoturret").contains("Completed"))
	assert(state.turret_unlocked)

	# Endless scaling: pressure keeps growing past the old day-15 plateau.
	state.day = 40
	assert(int(state.raid_profile()["wave_size"]) > 13)

func _process(_delta: float) -> bool:
	return true
