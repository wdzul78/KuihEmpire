class_name OrderItem
extends Resource

## One line of a customer order: "3 x Onde-onde".

@export var kuih: KuihData
@export var count: int = 3


static func make(p_kuih: KuihData, p_count: int) -> OrderItem:
	var item := OrderItem.new()
	item.kuih = p_kuih
	item.count = maxi(1, p_count)
	return item
