extends MainLoop
## Balance guard: simulate whole runs with single-minded day policies and a
## coarse night model. Fails when a degenerate policy (all-fish, all-timber)
## keeps up with a balanced keeper, or when endless scaling stops ending runs.
## Run with: godot --headless --path . --script res://tests/policy_sim_check.gd
##
## The night model is deliberately crude — a fixed number of boats sunk by
## skill, mines absorb one crash each, barricades blunt one crash — because
## the question is economic (does the DAY loop have a dominant strategy),
## not ballistic.

const SKILL_SINK := 5    ## boats the abstract keeper sinks per night
const CRASH_DAMAGE := 6  ## basic-boat crash damage, matches night_board
const MAX_DAYS := 100

func _init() -> void:
	var results := {}
	for policy in ["fisher", "lumberjack", "balanced"]:
		results[policy] = _run_policy(policy)
	print("policy_sim nights held: ", results)
	assert(int(results["balanced"]) > int(results["fisher"]),
		"all-fish must not keep up with balanced play")
	assert(int(results["balanced"]) > int(results["lumberjack"]),
		"all-timber must not keep up with balanced play")
	for policy in results:
		assert(int(results[policy]) < MAX_DAYS,
			"endless scaling must eventually end every run (%s survived)" % policy)
	print("policy_sim_check: PASS")

func _run_policy(policy: String) -> int:
	var state := RunState.new()
	state.telemetry_enabled = false
	state.reset_campaign(1234)
	for _day in MAX_DAYS:
		_spend_day(state, policy)
		var boats := int(state.raid_profile()["wave_size"])
		var sunk := mini(SKILL_SINK, boats)
		state.gold += sunk * 3
		var crashes := boats - sunk
		var absorbed := mini(state.mines, crashes)
		state.mines -= absorbed
		crashes -= absorbed
		if state.barricades > 0 and crashes > 0:
			state.barricades -= 1
			crashes -= 1
		state.hull -= crashes * CRASH_DAMAGE
		if state.hull <= 0:
			return state.day - 1
		state.start_day()
	return MAX_DAYS

func _spend_day(state: RunState, policy: String) -> void:
	for _attempt in 12:  # more than any daylight pool; failed spends break out
		if state.energy_today <= 0:
			return
		var before := state.energy_today
		state.perform_action(_choose(state, policy))
		if state.energy_today == before:
			return  # couldn't afford anything useful

func _choose(state: RunState, policy: String) -> String:
	match policy:
		"fisher":
			return "fish"
		"lumberjack":
			return "gather_driftwood"
	# Balanced keeper: repair first, keep mines stocked, keep timber for
	# patches, earn otherwise.
	if state.hull <= state.max_hull - 12 and state.can_afford({"gold": 3, "wood": 2}):
		return "patch_hull"
	if state.wood < 4:
		return "gather_driftwood"
	if state.mines < 2 and state.can_afford({"gold": 4, "scrap": 3}):
		return "craft_mines"
	if state.scrap < 3:
		return "sort_scrap"
	return "fish"

func _process(_delta: float) -> bool:
	return true
