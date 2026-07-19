class_name MovementRules
extends RefCounted

static func executed_edge_is_valid(state: Dictionary, from_tile: String, to_tile: String, neighbors: Array) -> bool:
  return state.get("tiles", {}).has(to_tile) and neighbors.has(to_tile)

static func friendly_merge_destination(first_stack_id: String, second_stack_id: String) -> String:
  return first_stack_id if first_stack_id < second_stack_id else second_stack_id

static func cohort_id_order(cohort_id: String) -> int:
  if cohort_id.length() > 1 and cohort_id.substr(0, 1) == "C" and cohort_id.substr(1).is_valid_int():
    return int(cohort_id.substr(1))
  return 2147483647
