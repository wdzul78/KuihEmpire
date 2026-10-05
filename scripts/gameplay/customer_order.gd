class_name CustomerOrder
extends RefCounted

## Runtime state of one customer's order.
##
## Completing every order is mandatory. Score only rates successful stages.

var customer: CustomerData = null
## kuih id -> how many are still missing.
var remaining: Dictionary = {}
## kuih id -> original requirement, used to draw the "6 / 10" label.
var target: Dictionary = {}
var served: bool = false
var total_collected: int = 0


static func from_spec(spec: CustomerOrderSpec) -> CustomerOrder:
	var order := CustomerOrder.new()
	order.customer = spec.customer
	for item in spec.items:
		if item == null or item.kuih == null:
			continue
		var count := item.count
		if spec.customer != null:
			count = maxi(1, int(round(float(count) * spec.customer.order_scale)))
		order.remaining[item.kuih.id] = int(order.remaining.get(item.kuih.id, 0)) + count
		order.target[item.kuih.id] = int(order.target.get(item.kuih.id, 0)) + count
	return order


## Applies collected kuih. Returns the leftover dictionary so the controller can
## pass surplus to the next customer - generosity keeps the game cozy.
func collect(totals: Dictionary) -> Dictionary:
	var leftover: Dictionary = {}
	for id in totals:
		var amount := int(totals[id])
		if amount <= 0:
			continue
		if remaining.has(id):
			var need := int(remaining[id])
			var used := mini(need, amount)
			remaining[id] = need - used
			total_collected += used
			leftover[id] = amount - used
		else:
			leftover[id] = amount
	return leftover


func is_complete() -> bool:
	for id in remaining:
		if int(remaining[id]) > 0:
			return false
	return true


func missing_total() -> int:
	var total := 0
	for id in remaining:
		total += int(remaining[id])
	return total


func required_total() -> int:
	var total := 0
	for id in target:
		total += int(target[id])
	return total


func progress_ratio() -> float:
	var need := required_total()
	if need <= 0:
		return 1.0
	return clampf(1.0 - float(missing_total()) / float(need), 0.0, 1.0)


func collected_for(id: StringName) -> int:
	return maxi(0, int(target.get(id, 0)) - int(remaining.get(id, 0)))


func wanted_for(id: StringName) -> int:
	return int(target.get(id, 0))


## Ids still missing, in the order the customer listed them.
func item_ids() -> Array:
	return target.keys()
