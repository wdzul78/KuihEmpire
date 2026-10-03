class_name CustomerOrderSpec
extends Resource

## Authoring-time definition of one customer's order, including the customer
## archetype that stands in front of the stall.

@export var customer: CustomerData
@export var items: Array[OrderItem] = []


static func make(p_customer: CustomerData, p_items: Array[OrderItem]) -> CustomerOrderSpec:
	var spec := CustomerOrderSpec.new()
	spec.customer = p_customer
	spec.items = p_items
	return spec


func total_items() -> int:
	var total := 0
	for item in items:
		total += item.count
	return total
