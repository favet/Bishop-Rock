extends Node
## Headless day-UI check. Boots Main, opens the day hub directly, and
## asserts the UI-clarity contract: core-only top bar, tokenized Daylight
## with hover ghost preview, honest hull bar, and a Start Night button that
## stays put across zone switches. Run with:
##   godot --headless --path . res://tests/DayUiCheck.tscn

const MAIN := preload("res://scenes/main/Main.tscn")

func _ready() -> void:
	# Failed asserts abort this coroutine but leave the tree running; the
	# timer turns that into a nonzero exit instead of a hung process.
	get_tree().create_timer(20.0).timeout.connect(func() -> void:
		printerr("day_ui_check: FAILED (timeout)")
		get_tree().quit(1))
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame

	CampaignState.hull = 79
	CampaignState.max_hull = 85
	main._show_day_hub()
	await get_tree().process_frame
	await get_tree().process_frame

	# Top bar: hull, daylight, gold, wood, scrap, food, day — nothing else.
	assert(main._top_bar.get_child_count() == 7, "top bar must show only the 7 core entries")
	assert(main._top_bar.has_node("DaylightDisplay"), "daylight display missing")

	# Daylight is tokenized, one token per point of max energy.
	assert(main._daylight_tokens.size() == CampaignState.energy_max)
	for token in main._daylight_tokens:
		assert(token.modulate.a > 0.9, "tokens must start solid")

	# Hover preview ghosts exactly the hovered cost, then restores.
	for spend in [1, 2]:
		main._set_daylight_preview(spend)
		var ghosted := 0
		for token in main._daylight_tokens:
			if token.modulate.a < 0.5:
				ghosted += 1
		assert(ghosted == spend, "preview must ghost exactly %d tokens" % spend)
	main._set_daylight_preview(0)
	for i in CampaignState.energy_today:
		assert(main._daylight_tokens[i].modulate.a > 0.9, "tokens must restore after hover")

	# Hull bar fill matches the label's own denominator (79/85, not /100).
	var expected := 140.0 * 79.0 / 85.0
	assert(absf(main._hull_fill.size.x - expected) < 0.5, "hull fill must use max_hull")
	assert(main._hull_label.text == "HULL 79/85")

	# Start Night stays in the same place whatever zone is selected.
	var start := main._start_night_label.get_parent() as Button
	assert(start.name == "FixedStartNightButton")
	assert(main._start_night_label.text.begins_with("START NIGHT"))
	var fixed_pos := start.global_position
	for zone in ["Repairs", "Crafting", "Supplies", "Rest"]:
		main._select_zone(zone)
		await get_tree().process_frame
		assert(start.global_position == fixed_pos, "Start Night moved on zone switch")
		# Action cards must be tall enough for their manually laid-out content.
		for card in main._action_list.get_children():
			if card is Button:
				for content in card.get_children():
					if content is VBoxContainer:
						var needed: float = content.get_combined_minimum_size().y + content.position.y
						if card.custom_minimum_size.y < needed:
							print("OVERFLOW %s: min=%.1f needed=%.1f size=%.1f" % [zone, card.custom_minimum_size.y, needed, card.size.y])
						assert(card.custom_minimum_size.y >= needed, "card content overflows in %s" % zone)

	# Unaffordable projects stay inspectable: card exists, button not disabled.
	CampaignState.gold = 0
	main._select_zone("Crafting")
	await get_tree().process_frame
	var found_cannot_start := false
	for card in main._action_list.get_children():
		for button in card.find_children("*", "Button", true, false):
			if button.text == "Cannot Start":
				found_cannot_start = true
				assert(not button.disabled, "unaffordable project must stay clickable")
	assert(found_cannot_start, "expected an unaffordable project card")

	# Save/load round-trip through the autoload (bare instances don't persist).
	CampaignState.gold = 17
	CampaignState.day = 4
	CampaignState.active_crops.assign([{"crop": "potatoes", "days_left": 2}])
	CampaignState.save_run()
	CampaignState.gold = 1
	CampaignState.day = 9
	CampaignState.active_crops.clear()
	assert(CampaignState.load_run(), "saved run must load")
	assert(CampaignState.gold == 17 and CampaignState.day == 4, "load must restore fields")
	assert(CampaignState.active_crops.size() == 1, "load must restore crops")
	CampaignState.delete_save()
	assert(not CampaignState.has_save(), "delete_save must remove the file")

	# Windowed runs also drop a screenshot for eyeballing the layout.
	if DisplayServer.get_name() != "headless":
		CampaignState.gold = 21
		main._refresh_day_ui()
		main._select_zone("Repairs")
		await get_tree().create_timer(0.4).timeout
		get_viewport().get_texture().get_image().save_png("user://day_ui_check.png")

	print("day_ui_check: PASS")
	get_tree().quit(0)
