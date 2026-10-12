class_name Enhance
extends RefCounted

## Item enhancing, level transfer and gem merging (docs/khung-ky-thuat.md, section 7.2).
## All costs come from data/economy/*.csv.

const MAX_LEVEL := 200


## Row of enhance_curve.csv for going from level-1 to [param level].
static func cost_for(level: int) -> Dictionary:
	for row in GameDB.tables.enhance_curve:
		if int(row.level) == level:
			return row
	return {}


static func gem_key(tier: int) -> String:
	return "gem_%d" % tier


## Tries to raise [param uid] by one level. Returns "ok", "fail" or why it could not try.
static func enhance(profile: Profile, uid: String, rng: RandomNumberGenerator) -> String:
	var level := profile.item_level(uid)
	if level >= MAX_LEVEL:
		return "max"
	var cost := cost_for(level + 1)
	if cost.is_empty():
		return "no_data"
	var gem := gem_key(int(cost.gem_tier))
	if profile.amount(gem) < cost.gem_count or profile.amount("gold") < cost.gold_cost:
		return "not_enough"
	profile.spend(gem, cost.gem_count, "enhance")
	profile.spend("gold", cost.gold_cost, "enhance")
	if rng.randf() < cost.success_rate:
		profile.data.inventory[uid].level = level + 1
		return "ok"
	profile.data.inventory[uid].level = maxi(level - int(cost.fail_drop), 0)
	return "fail"


## Gold to move [param from_uid]'s level onto [param to_uid], and the level it lands at.
static func transfer_quote(profile: Profile, from_uid: String) -> Dictionary:
	var rule: Dictionary = GameDB.tables.enhance_transfer[0]
	var level := profile.item_level(from_uid)
	return {
		"gold": level * rule.gold_per_level,
		"level": floori(level * rule.keep_ratio),
	}


## Moves the enhance level to another item of the same slot (decision 20). Old item drops to 0.
static func transfer(profile: Profile, from_uid: String, to_uid: String) -> String:
	if from_uid == to_uid:
		return "same_item"
	if profile.item_base(from_uid).slot != profile.item_base(to_uid).slot:
		return "different_slot"
	var quote := transfer_quote(profile, from_uid)
	if not profile.spend("gold", quote.gold, "enhance_transfer"):
		return "not_enough"
	profile.data.inventory[to_uid].level = maxi(profile.item_level(to_uid), quote.level)
	profile.data.inventory[from_uid].level = 0
	return "ok"


## Merges lower-tier gems into one of the next tier, [param times] times. Returns how many merged.
static func merge_gems(profile: Profile, from_tier: int, times: int = 1) -> int:
	var rule := {}
	for row in GameDB.tables.gem_merge:
		if int(row.from_tier) == from_tier:
			rule = row
	if rule.is_empty():
		return 0
	var done := 0
	for i in times:
		if profile.amount(gem_key(from_tier)) < rule.count_in or profile.amount("gold") < rule.gold_cost:
			break
		profile.spend(gem_key(from_tier), rule.count_in, "gem_merge")
		profile.spend("gold", rule.gold_cost, "gem_merge")
		profile.add(gem_key(int(rule.to_tier)), 1, "gem_merge")
		done += 1
	return done
