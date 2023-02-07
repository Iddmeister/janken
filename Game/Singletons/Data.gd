extends Node

const saveLocation:String = "user://janken.data"
var file:ConfigFile = ConfigFile.new()

func _ready() -> void:
	var err = loadData(saveLocation)
	if err != OK:
		print("Creating Save File")
		var err2 = file.save(saveLocation)
		if err2 != OK:
			print("Error Saving Data, code: %s" % err2)

func loadData(path:String):
	var err = file.load(path)
	if err != OK:
		print("Error Loading Save Data, code: %s" % err)
	return err
	
func getData(key:String, default=null, section:String="data"):
	if (not file.has_section(section)) or (not file.has_section_key(section, key)):
		return default
	return file.get_value(section, key)

func saveData(key:String, value, section:String="data"):
	file.set_value(section, key, value)
	var err = file.save(saveLocation)
	if err != OK:
			print("Error Saving Data, code: %s" % err)
