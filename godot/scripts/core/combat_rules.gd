class_name CombatRules
extends RefCounted

static func defender_for(controller: String, live_owners: Array) -> String:
  if live_owners.has(controller):
    return controller
  var ordered: Array = live_owners.duplicate()
  ordered.sort()
  return String(ordered[0]) if not ordered.is_empty() else ""

static func attacker_for(defender: String, live_owners: Array) -> String:
  var ordered: Array = live_owners.duplicate()
  ordered.sort()
  for owner in ordered:
    if String(owner) != defender:
      return String(owner)
  return ""
