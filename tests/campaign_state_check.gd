extends MainLoop

func _init() -> void:
	var state = preload("res://scripts/campaign/run_state.gd").new()
	state.reset_campaign()
	assert(state.day == 1)
	assert(state.hull == 85)
	assert(state.energy_today == 6)
	assert(state.raid_profile()["wave_size"] < 24)
	assert(state.raid_profile()["heavy_weight"] == 0.0)
	assert(state.perform_action("gather_driftmaterials").contains("materials"))
	pass
	pass
	state.materials = 5
	assert(state.perform_action("make_tool").contains("tool"))
	state.food = 4
	assert(state.perform_action("plant_potatoes").contains("planted"))
	state.start_day()
	state.start_day()
	state.start_day()
	assert(state.perform_action("harvest_potatoes").contains("Harvested"))
	assert(state.food >= 8)

func _process(_delta: float) -> bool:
	return true
