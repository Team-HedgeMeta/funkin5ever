extends HBoxContainer

var meta:SongMetadata:
	set(value):
		if meta == value:
			return
		meta = value
		%label.text = meta.display_name.to_upper() if meta.display_name.length() > 0 else meta._song_id
		%icon.data = meta.freeplay_icon
