extends HUD

@export var watermark:Label
@export var health_bar:TextureProgressBar
@export var opponent_icon:HealthIcon
@export var player_icon:HealthIcon
@export var song_text:Label
@export var score_text:Label
@export var judgement_display:JudgementDisplay

func _ready() -> void:
	if is_instance_valid(song_text):
		var song_name:String = Song.current.meta.display_name if !Song.current.meta.display_name.is_empty() else Song.current.chart._song_id
		song_text.text = "- %s [%s] -" % [song_name, Song.current.chart._difficulty.to_upper()]
	apply_config()

func apply_config() -> void:
	if Config.get_config("down_scroll"):
		if is_instance_valid(health_bar): health_bar.position.y -= 580
		if is_instance_valid(player_strumline):
			player_strumline.down_scroll = true
			player_strumline.position.y += 510
		if is_instance_valid(opponent_strumline):
			opponent_strumline.down_scroll = true
			opponent_strumline.position.y += 510
		if is_instance_valid(judgement_display):
			judgement_display.position.y += 510
		if is_instance_valid(score_text):
			score_text.position.y += 13
	if Config.get_config("middle_scroll"):
		if is_instance_valid(player_strumline):
			player_strumline.position.x = 416
		if is_instance_valid(opponent_strumline):
			opponent_strumline.visible = false
		if is_instance_valid(judgement_display):
			judgement_display.position.x -= 350

func _ready_post() -> void:
	_reload_icon()

func _reload_icon() -> void:
	if is_instance_valid(player_icon) && player_strumline.characters.size() > 0: player_icon.data = player_strumline.characters[0].health_icon
	if is_instance_valid(opponent_icon) && opponent_strumline.characters.size() > 0: opponent_icon.data = opponent_strumline.characters[0].health_icon
	
	health_bar.tint_progress = player_icon.data.color
	health_bar.tint_under = opponent_icon.data.color
	
func _update_score():
	if is_instance_valid(score_text):
		score_text.text = "Score: %s • Accuracy: %s [%s] • Combo Breaks: %s" % [Song.current.stats.score, str(floor(Song.current.stats.accuracy)) + "%", Song.current.stats.get_clear_rating(), Song.current.stats.combo_breaks]

func _process(_delta:float) -> void:
	_update_score()
	if is_instance_valid(health_bar):
		health_bar.value = Song.current.stats.health
	
	_update_icon_positions()

func _update_icon_positions() -> void:
	if is_instance_valid(health_bar):
		var bar_pos: float = health_bar.global_position.x + health_bar.size.x * (1.0 - remap(health_bar.value, 0, 2, 0, 1))
		if is_instance_valid(player_icon): player_icon.global_position.x = bar_pos + 50
		if is_instance_valid(opponent_icon): opponent_icon.global_position.x = bar_pos - 50

func _on_note_hit(_note:Note, strumline:Strumline, judge:String = "sick"):
	if !is_instance_valid(judgement_display):
		return
	if strumline == player_strumline:
		judgement_display.show_judgement(judge, Song.current.stats.combo)

func _on_note_miss(_note:Note, strumline:Strumline):
	if !is_instance_valid(judgement_display):
		return
	if strumline == player_strumline:
		judgement_display.hide_judgement()
