extends MainLoop

func _init() -> void:
	var state = preload("res://scripts/campaign/run_state.gd").new()
	state.reset_campaign()
	assert(state.raid_profile()["wave_size"] == 3)
	assert(state.raid_profile()["fast_weight"] == 0.0)
	assert(state.raid_profile()["heavy_weight"] == 0.0)
	assert(state.raid_profile()["max_simultaneous"] == 1)
	assert(not state.turret_unlocked)
	var gold_before = state.gold
	assert(state.perform_action("gather_driftmaterials").contains("materials"))
	assert(state.materials == 14)
	assert(state.start_project("greased_crank").contains("Started"))
	assert(state.work_project("greased_crank").contains("Completed"))
	assert(state.beam_turn_multiplier() > 1.0)
	state.gold = 55
	state.materials = 14
	state.tools = 2
	assert(state.start_project("rusty_autoturret").contains("Started"))
	state.energy_today = 4
	state.work_project("rusty_autoturret")
	state.work_project("rusty_autoturret")
	state.work_project("rusty_autoturret")
	assert(state.work_project("rusty_autoturret").contains("Completed"))
	assert(state.turret_unlocked)

func _process(_delta: float) -> bool:
	return true
