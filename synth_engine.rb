SAMPLE_RATE = 44101

# Generate a waveform
def wave(freq, duration, type=:sine)
  samples = (SAMPLE_RATE * duration).to_i
  (0...samples).map do |i|
    t = i.to_f / SAMPLE_RATE
    case type
    when :sine
      Math.sin(2 * Math::PI * freq * t)
    when :square
      Math.sin(2 * Math::PI * freq * t) >= 0 ? 1 : -1
    when :triangle
      2 * (2 * (freq * t - (freq * t).floor) - 1).abs - 1
    when :saw
      2 * (freq t - (freq * t).floor) - 1
    else
      0
    end
  end
end

# Apply simple volume envelope (Attack + Decay)
def envelope(samples, attack: 0.01, decay: 0.1)
  total = samples.size
  attack_samples = (SAMPLE_RATE * attack).to_i
  decay_samples = (SAMPLE_RATE * decay).to_i

  samples.each_with_index.map do |s, i|
    env = if i < attack_samples
      i.to_f / attack_samples
    elsif i > total - decay_samples
      (total - i).to_f / decay_samples
    else
      1.0
    end
    s * env
  end
end

# Generate kick and Snare


def kick
  env_wave = envelope(wave(60, 0.2, :sine), attack: 0.01, decay: 0.2)
  env_wave.map { |s| s * 1.0 }  # boost volume
end

def snare
  samples = (SAMPLE_RATE * 0.2).to_i
  Array.new(samples) { (rand*2 - 1) * 0.5 }  # white noise
end

# Simple Hi-hat

def hihat
  samples = (SAMPLE_RATE * 0.1).to_i
  Array.new(samples) { (rand*2 - 1) * 0.3 }  # softer noise
end

beat = []

4.times do
  beat += kick
  beat += hihat
  beat += snare
  beat += hihat
end

# Map note name to frequency (A4 = 440 Hz)
NOTES = {
  "C4" => 261.63,
  "D4" => 293.66,
  "E4" => 329.63,
  "F4" => 349.23,
  "G4" => 392.00,
  "A4" => 440.00,
  "B4" => 493.88,
  "C5" => 523.25
}

def note_freq(note)
  NOTES[note] || 440.0
end


def synth(note, duration, type=:sine)
  samples = wave(note_freq(note), duration, type)
  envelope(samples, attack: 0.01, decay: duration/2)
end

beat = []

4.times do
  beat += kick
  beat += hihat
  beat += snare
  beat += hihat
  beat += synth("C4", 0.2, :square)  # melodic line
  beat += synth("E4", 0.2, :square)
  beat += synth("G4", 0.2, :square)
end

def bass(note, duration)
  samples = wave(note_freq(note), duration, :triangle)
  envelope(samples, attack: 0.01, decay: duration/2)
end

# 16-step sequencer
STEPS = 16
TEMPO = 120 # BPM
BEAT_DURATION = 60.0 / TEMPO / 4 # 16th note duration

# Drums patterns (1 = hit, 0 = silent)
kick_pattern   = [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0]
snare_pattern  = [0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0]
hihat_pattern  = [1]*16  # constant hi-hat

# Synth melody pattern (notes or nil)
synth_pattern = ["C4", nil, "E4", nil, "G4", nil, "C5", nil,
                 "C4", nil, "E4", nil, "G4", nil, "C5", nil]

# Bass pattern
bass_pattern = ["C2", nil, "C2", nil, "G2", nil, "G2", nil,
                "C2", nil, "C2", nil, "G2", nil, "G2", nil]


beat = []

STEPS.times do |i|
  beat += kick if kick_pattern[i] == 1
  beat += snare if snare_pattern[i] == 1
  beat += hihat if hihat_pattern[i] == 1
  beat += synth(synth_pattern[i], BEAT_DURATION, :square) if synth_pattern[i]
  beat += bass(bass_pattern[i], BEAT_DURATION) if bass_pattern[i]
end


def write_wav(filename, samples)
  File.open(filename, "wb") do |f|
    data = samples.map { |s| [[(s * 32767).to_i, 32767].min, -32768].max }.pack("s*")
    f.write "RIFF"
    f.write [36 + data.bytesize].pack("V")
    f.write "WAVEfmt "
    f.write [16, 1, 1, SAMPLE_RATE, SAMPLE_RATE*2, 2, 16].pack("VvvVVvv")
    f.write "data"
    f.write [data.bytesize].pack("V")
    f.write data
  end
end

filename = "beat_#{Time.now.to_i}.wav"
write_wav(filename, beat)
puts "Created #{filename}"

