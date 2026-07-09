SAMPLE_RATE = 44100

# -----------------------
# Mix Utility
# -----------------------
def mix(tracks)
  max_length = tracks.map(&:length).max
  mixed = Array.new(max_length, 0.0)

  tracks.each do |track|
    track.each_with_index do |sample, i|
      mixed[i] += sample
    end
  end

  mixed
end

# -----------------------
# Wave Generator
# -----------------------
def wave(freq, duration, type=:sine)
  samples = (SAMPLE_RATE * duration).to_i

  (0...samples).map do |i|
    t = i.to_f / SAMPLE_RATE
    case type
    when :sine
      Math.sin(2 * Math::PI * freq * t)
    when :triangle
      2 * (2 * (freq * t - (freq * t).floor) - 1).abs - 1
    else
      0
    end
  end
end

# -----------------------
# Envelope
# -----------------------
def envelope(samples, attack: 0.02, decay: 0.5)
  total = samples.size
  attack_samples = (SAMPLE_RATE * attack).to_i
  decay_samples = (SAMPLE_RATE * decay).to_i

  samples.each_with_index.map do |s, i|
    env =
      if i < attack_samples
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
# Notes
# -----------------------
NOTES = {
  "C2"=>65.41,"G2"=>98.00,"A2"=>110.0,"F2"=>87.31,
  "C4"=>261.63,"E4"=>329.63,"G4"=>392.00,"A4"=>440.00,
  "C5"=>523.25,"D5"=>587.33,"E5"=>659.25,"G5"=>783.99
}

def note_freq(note)
  NOTES[note] || 440.0
end

# -----------------------
# Instruments
# -----------------------
def pad(note, duration)
  samples = wave(note_freq(note), duration, :sine)
  envelope(samples, attack: 0.3, decay: duration/2).map { |s| s * 0.25 }
end

def bass(note, duration)
  samples = wave(note_freq(note), duration, :sine)
  envelope(samples, attack: 0.05, decay: duration/2).map { |s| s * 0.35 }
end

def piano(note, duration)
  # Layer sine + triangle for piano feel
  sine = wave(note_freq(note), duration, :sine)
  tri  = wave(note_freq(note), duration, :triangle)

  blended = sine.zip(tri).map { |a,b| (a*0.7 + b*0.3) }
  envelope(blended, attack: 0.01, decay: duration*0.8).map { |s| s * 0.4 }
end

def soft_kick
  base = wave(55, 0.4, :sine)
  shaped = base.each_with_index.map do |s, i|
    s * (1.0 - i.to_f / base.length)
  end
  envelope(shaped, attack: 0.01, decay: 0.3).map { |s| s * 0.3 }
end

# -----------------------
# Tempo
# -----------------------
TEMPO = 70
BEAT = 60.0 / TEMPO
BAR  = BEAT * 4

track = []
LOOPS = 6

chords = [
  ["C4","E4","G4"],
  ["A4","C5","E5"],
  ["F2","A4","C5"],
  ["G4","C5","E5"]
]

bass_line = ["C2","A2","F2","G2"]

# Calm melody pattern (very spacious)
melody = [
  "E5", nil, "G5", nil,
  "C5", nil, "D5", nil
]

LOOPS.times do
  chords.each_with_index do |chord, i|
    layers = []

    # Pad chords
    chord.each do |note|
      layers << pad(note, BAR)
    end

    # Bass
    layers << bass(bass_line[i], BAR)

    # Soft kick
    layers << soft_kick

    # Piano melody (plays over bar)
    melody.each do |note|
      if note
        layers << piano(note, BEAT * 2)
      end
    end

    track += mix(layers)
  end
end

# -----------------------
# Write WAV
# -----------------------
def write_wav(filename, samples)
  max_amp = samples.map(&:abs).max
  normalized = samples.map { |s| s / max_amp }

  data = normalized.map do |s|
    [[(s * 32767).to_i, 32767].min, -32768].max
  end.pack("s*")

  File.open(filename, "wb") do |f|
    f.write "RIFF"
    f.write [36 + data.bytesize].pack("V")
    f.write "WAVEfmt "
    f.write [16, 1, 1, SAMPLE_RATE, SAMPLE_RATE*2, 2, 16].pack("VvvVVvv")
    f.write "data"
    f.write [data.bytesize].pack("V")
    f.write data
  end
end

filename = "nightfall_v1#{Time.now.to_i}.wav"
write_wav(filename, track)

puts "Created #{filename}"
