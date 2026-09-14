extends Node
## Legacy HUD compatibility only. Authoritative currency now lives on the server.
signal coins_changed(amount: int)
var coins: int = 0
func add_coins(_amount: int) -> void:
	pass
