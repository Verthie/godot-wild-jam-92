@tool
extends EditorScript
## Automatically adds all MusicTrack resources found in the [member folder_path] that are not already in the [member music_manager_path]'s tracks Array.

var music_manager_path: String = "res://scenes/autoload/music_manager.tscn" ## The path to the music manager scene.
var music_manager_scene: PackedScene = load(music_manager_path) ## Loads the music manager scene so the tool can modify it.
var folder_path: String = "res://resources/music/" ## The path to your folder containing your MusicTrack resources.
var files: PackedStringArray = DirAccess.get_files_at(folder_path) ## Get a list of all files in the [member folder_path].
var modified: bool ## Stores if the music manager scene is updated, we only need to resave if updated.

func _run() -> void:
	# Unpack the music manager scene
	var music_manager_instance: Node = music_manager_scene.instantiate()

	# Loop through each file in the folder, load the resource, check if it's in the array or not, and if not, add it.
	for file: String in files:
		var file_path: String = folder_path + "/" + file ## The full path to the resource
		var resource: Resource = load(file_path) ## Set to the resource to load

		# Check if the resource is valid and not already in the array
		if resource != null and not resource in music_manager_instance.tracks and resource is MusicTrack:
			modified = true
			# Add the resource to the MusicManager tracks array.
			music_manager_instance.tracks.append(resource)

	# Save the modified scene only if we've modified it.
	if modified == true:
		music_manager_scene = PackedScene.new()
		music_manager_scene.pack(music_manager_instance)
		ResourceSaver.save(music_manager_scene, music_manager_path)
		print("MusicManager updated. If you have the scene open in the editor, you may need to reload it to see the updates.")
	else:
		print("MusicManager was not updated, no new MusicTrack resources found.")
