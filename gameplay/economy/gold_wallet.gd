class_name GoldWallet
extends Node

signal gold_changed(current: int, total_earned: int)
var current_gold: int = 0
var total_earned: int = 0

func award(amount: int) -> void:
	if amount <= 0:
		return
	current_gold += amount
	total_earned += amount
	gold_changed.emit(current_gold, total_earned)
