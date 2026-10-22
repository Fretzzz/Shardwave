extends Node
## Synthesized SFX bank. The game ships with zero imported audio files: every
## cue is built once at first use from a sine sweep + noise, so the repo and the
## APK stay clean. Swapping in real samples later means changing only _build().

const RATE := 16000
const VOICES := 6

var enabled := true

var _bank: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_voices.append(p)


func play_sfx(kind: String) -> void:
	if not enabled:
		return
	if not _bank.has(kind):
		_bank[kind] = _build(kind)
	var p := _voices[_next]
	_next = (_next + 1) % VOICES
	p.stream = _bank[kind]
	p.pitch_scale = randf_range(0.95, 1.05) if kind == "place" else 1.0
	p.play()


# --- Semantic events. Game code calls these, never raw clip names. ---

func place() -> void:
	play_sfx("place")


func line() -> void:
	play_sfx("line")


func multi(line_count: int = 2) -> void:
	play_sfx("multi" if line_count < 3 else "prism")


func prism() -> void:
	play_sfx("prism")


func over() -> void:
	play_sfx("over")


func ui() -> void:
	play_sfx("ui")


# --- synthesis ---

func _build(kind: String) -> AudioStreamWAV:
	match kind:
		"place": return _synth(220.0, 110.0, 0.09, 0.55, 0.16, 1)
		"line": return _synth(520.0, 900.0, 0.20, 0.42, 0.04, 2)
		"multi": return _synth(430.0, 1250.0, 0.28, 0.42, 0.05, 3)
		"prism": return _synth(180.0, 1500.0, 0.45, 0.50, 0.07, 3)
		"over": return _synth(300.0, 80.0, 0.55, 0.45, 0.02, 1)
		"ui": return _synth(700.0, 880.0, 0.05, 0.28, 0.0, 1)
	return _synth(440.0, 440.0, 0.08, 0.30, 0.0, 1)


func _synth(start_hz: float, end_hz: float, dur: float, gain: float,
		noise: float, harmonics: int) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase := 0.0
	var norm := 1.0 + (0.35 if harmonics >= 2 else 0.0) + (0.18 if harmonics >= 3 else 0.0)

	for i in n:
		var t := float(i) / float(n)
		var freq := lerpf(start_hz, end_hz, t * t)
		phase += TAU * freq / RATE

		var s := sin(phase)
		if harmonics >= 2:
			s += 0.35 * sin(phase * 2.0)
		if harmonics >= 3:
			s += 0.18 * sin(phase * 3.0 + sin(phase) * 0.5)
		s /= norm
		s += randf_range(-1.0, 1.0) * noise

		# 6 ms attack kills the click; squared decay keeps it percussive
		var env: float = minf(1.0, float(i) / (RATE * 0.006)) * pow(1.0 - t, 2.2)
		s *= env * gain
		bytes.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
