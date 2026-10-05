extends Node

signal updated()
var service: LeaderboardService = LocalLeaderboardService.new()

func _ready() -> void:
	service.refreshed.connect(_provider_refreshed)

func _provider_refreshed() -> void:
	updated.emit()

func refresh() -> void:
	service.submit_progress(PlayerRankingSnapshot.current())
	service.refresh_rankings()

func set_provider(provider: LeaderboardService) -> void:
	if service.refreshed.is_connected(_provider_refreshed):
		service.refreshed.disconnect(_provider_refreshed)
	service = provider
	service.refreshed.connect(_provider_refreshed)
	refresh()
