extends Node
## Headless day-UI check. Boots Main, opens the one-screen day hub, and
## asserts the UI-clarity contract: core-only top bar, tokenized Daylight
## with hover ghost preview, honest hull bar, all cards visible at once, a
## truthful Tonight forecast, and a fixed Start Night button. Run with:
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
	assert(main._hull_fill.max_value == 85.0, "hull bar must use max_hull")
	assert(main._hull_fill.value == 79.0, "hull bar must use current hull")
	assert(main._hull_label.text == "HULL 79/85")

	# One screen: both action groups and all projects visible at once.
	assert(main._light_list.get_child_count() >= 3, "Keep the Light column missing cards")
	assert(main._prov_list.get_child_count() >= 4, "Provisions column missing cards")
	assert(main._project_list.get_child_count() == CampaignState.START_PROJECTS.size())
	assert(main.find_children("*", "ScrollContainer", true, false).is_empty(),
		"day hub must not use scrollbars at current content level")
	assert(not main.find_children("DayTabs", "TabContainer", true, false).is_empty(),
		"day hub must use focused tab pages")

	# The Tonight forecast tells the truth: it counts the same plan the
	# spawner will consume.
	var plan := CampaignState.night_plan()
	assert(main._tonight_holder.get_child_count() > 0, "Tonight panel missing")
	assert(CampaignState.forecast_text().begins_with("%d boats" % plan.size()))

	# Start Night exists, is fixed in the footer, and survives card rebuilds.
	var start := main._start_night_label.get_parent() as Button
	assert(start.name == "FixedStartNightButton")
	assert(main._start_night_label.text.begins_with("LIGHT THE LANTERN"))
	var fixed_pos := start.global_position
	main._rebuild_day_cards()
	await get_tree().process_frame
	assert(start.global_position == fixed_pos, "Start Night moved on rebuild")

	# Action cards must be tall enough for their manually laid-out content.
	for list in [main._light_list, main._prov_list]:
		for card in list.get_children():
			if card is Button:
				for content in card.get_children():
					if content is VBoxContainer:
						var needed: float = content.get_combined_minimum_size().y + content.position.y
						assert(card.custom_minimum_size.y >= needed, "card content overflows")

	# Unaffordable projects stay inspectable: card exists, button not disabled.
	CampaignState.gold = 0
	main._rebuild_day_cards()
	await get_tree().process_frame
	var found_cannot_start := false
	for card in main._project_list.get_children():
		for button in card.find_children("*", "Button", true, false):
			if button.text == "Cannot Start":
				found_cannot_start = true
				assert(not button.disabled, "unaffordable project must stay clickable")
	assert(found_cannot_start, "expected an unaffordable project card")

	# Save/load round-trip through the autoload (bare instances don't persist).
	CampaignState.gold = 17
	CampaignState.day = 4
	CampaignState.save_run()
	CampaignState.gold = 1
	CampaignState.day = 9
	assert(CampaignState.load_run(), "saved run must load")
	assert(CampaignState.gold == 17 and CampaignState.day == 4, "load must restore fields")
	CampaignState.delete_save()
	assert(not CampaignState.has_save(), "delete_save must remove the file")

	# Windowed runs also drop a screenshot for eyeballing the layout.
	if DisplayServer.get_name() != "headless":
		CampaignState.gold = 21
		main._refresh_day_ui()
		main._rebuild_day_cards()
		await get_tree().create_timer(0.4).timeout
		get_viewport().get_texture().get_image().save_png("user://day_ui_check.png")

	print("day_ui_check: PASS")
	get_tree().quit(0)
