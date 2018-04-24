extends Node

const MSAA_DEFAULT = 2
const FOV_DEFAULT = 70
const MUSIC_DEFAULT = 50
const SFX_DEFAULT = 70

const MIN_FOV = 60
const MAX_FOV = 110

const DESKTOP_OS = ["Haiku", "OSX", "Windows", "UWP", "X11"]

const CONFIG_FILE_NAME = "user://settings.cfg"
var configFile

var msaa = MSAA_DEFAULT
var fov = FOV_DEFAULT
var musicVolume = MUSIC_DEFAULT
var sfxVolume = SFX_DEFAULT

func loadConfig():
	configFile = ConfigFile.new()
	var err = configFile.load(CONFIG_FILE_NAME)
	if err == OK:
		msaa = configFile.get_value("graphics", "msaa", MSAA_DEFAULT)
		fov = configFile.get_value("graphics", "fov", FOV_DEFAULT)
		musicVolume = configFile.get_value("audio", "music_vol", MUSIC_DEFAULT)
		sfxVolume = configFile.get_value("audio", "sfx_vol", SFX_DEFAULT)
		
		if not typeof(msaa) == TYPE_INT:
			msaa = MSAA_DEFAULT
		
		if not typeof(fov) == TYPE_INT or fov < MIN_FOV or fov > MAX_FOV:
			fov = FOV_DEFAULT
		
		if not typeof(musicVolume) == TYPE_INT and not typeof(musicVolume) == TYPE_REAL:
			musicVolume = MUSIC_DEFAULT
		
		if not typeof(sfxVolume) == TYPE_INT and not typeof(sfxVolume) == TYPE_REAL:
			sfxVolume = SFX_DEFAULT

func saveConfig():
	if not configFile:
		loadConfig()
		
	fov = clamp(fov, MIN_FOV, MAX_FOV)
	
	configFile.set_value("graphics", "msaa", msaa)
	configFile.set_value("graphics", "fov", int(fov))
	configFile.set_value("audio", "music_vol", musicVolume)
	configFile.set_value("audio", "sfx_vol", sfxVolume)
	
	configFile.save(CONFIG_FILE_NAME)
	

func getMSAALevel():
	if msaa == 0:
		return Viewport.MSAA_DISABLED
	elif msaa == 1:
		return Viewport.MSAA_2X
	elif msaa == 2:
		return Viewport.MSAA_4X
	elif msaa == 3:
		return Viewport.MSAA_8X
	else:
		msaa = 0
		print("Bad MSAA Level detected. Reset to OFF.")
		return Viewport.MSAA_DISABLED

func convertLinearToDecibel(linear):
	if linear > 0:
		return 20.0 * (log(linear) / log(10))
	else:
		return -144.0

func configAudio():
	musicVolume = clamp(musicVolume, 0, 100)
	sfxVolume = clamp(sfxVolume, 0, 100)
	
	var musicCoef = musicVolume / 100.0
	var sfxCoef = sfxVolume / 100.0
	
	var musicDB = convertLinearToDecibel(musicCoef)
	var sfxDB = convertLinearToDecibel(sfxCoef)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), musicDB)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfxDB)

func configCamera(camera):
	camera.get_viewport().msaa = getMSAALevel()
	camera.fov = fov

func changeMusicVolume(vol):
	musicVolume = vol
	configAudio()

func changeSfxVolume(vol):
	sfxVolume = vol
	configAudio()
