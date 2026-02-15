SAMPLE_RATE = 44100  # standard CD quality

# -----------------------
# Waveforms + Envelope
# -----------------------
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
      2 * (freq * t - (freq * t).floor) - 1
    else
      0
    end
  end
end

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

# -----------------------
# Drums
# -----------------------
def kick
  env_wave = envelope(wave(60, 0.2, :sine), attack: 0.01, decay: 0.2)
  env_wave.map { |s| s * 1.0 }
end

def snare
  samples = (SAMPLE_RATE * 0.2).to_i
  Array.new(samples) { (rand*2 - 1) * 0.5 }
end

def hihat
  samples = (SAMPLE_RATE * 0.1).to_i
  raw = Array.new(samples) { (rand*2 - 1) * 0.2 }  # quieter
  envelope(raw, attack: 0.0, decay: 0.05)           # super short decay
end

# -----------------------
# Synth + Notes
# -----------------------
NOTES = {
  "C2"=>65.41,"D2"=>73.42,"E2"=>82.41,"F2"=>87.31,"G2"=>98.00,"A2"=>110.0,"B2"=>123.47,
  "C4"=>261.63,"D4"=>293.66,"E4"=>329.63,"F4"=>349.23,"G4"=>392.00,"A4"=>440.00,"B4"=>493.88,"C5"=>523.25
}

def note_freq(note)
  NOTES[note] || 440.0
end

def synth(note, duration, type=:sine)
  samples = wave(note_freq(note), duration, type)
  envelope(samples, attack: 0.01, decay: duration/2)
end

def bass(note, duration)
  samples = wave(note_freq(note), duration, :triangle)
  envelope(samples, attack: 0.01, decay: duration/2)
end

# -----------------------
# Sequencer Settings
# -----------------------
STEPS = 16        # 16 steps per pattern
TEMPO = 100       # BPM
BEAT_DURATION = 60.0 / TEMPO / 4  # 16th note

# -----------------------
# Patterns (can loop)
# -----------------------
# Syncopated Kick / Snare / Hi-hat
# 16-step groove pattern
kick_pattern  = [1,0,0,0,0,1,0,0,1,0,0,0,0,1,0,0] 
snare_pattern = [0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0]
hihat_pattern = [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1]  # on off-beats

synth_pattern = [
  ["C4","E4"], nil, ["G4","C5"], nil, ["E4","G4"], nil, ["C5","E5"], nil,
  ["D4","F4"], nil, ["A4","C5"], nil, ["F4","A4"], nil, ["D5","F5"], nil
]

bass_pattern = ["C2", nil, "G2", nil, "A2", nil, "F2", nil,
                "D2", nil, "G2", nil, "C2", nil, "G2", nil]


# -----------------------
# Build Long Track
# -----------------------
beat = []

# Repeat patterns to make longer track
# Repeat patterns to make longer track
LOOPS = 8  # 8×16 steps = 128 steps → longer song
LOOPS.times do
  STEPS.times do |i|
    beat += kick if kick_pattern[i] == 1
    beat += snare if snare_pattern[i] == 1
    beat += hihat if hihat_pattern[i] == 1

    # ← Replace your old synth line with this
    if synth_pattern[i]
      notes = [synth_pattern[i]].flatten  # allow single note or chord
      notes.each do |note|
        beat += synth(note, BEAT_DURATION, :triangle)
      end
    end

    beat += bass(bass_pattern[i], BEAT_DURATION) if bass_pattern[i]
  end
end


# -----------------------
# Write WAV File
# -----------------------
def write_wav(filename, samples)
  File.open(filename, "wb") do |f|
    # normalize to prevent clipping
    max_amp = samples.map(&:abs).max
    normalized = samples.map { |s| s / max_amp } if max_amp > 0
    data = normalized.map { |s| [[(s * 32767).to_i, 32767].min, -32768].max }.pack("s*")

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

