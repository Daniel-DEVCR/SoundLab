SAMPLE_RATEch = 44100

def sine_wave(freq, duration)
  samples = (SAMPLE_RATE * duration).to_i
  (0...samples).map do |i|
    Math.sin(2 * Math::PI * freq * i / SAMPLE_RATE)
  end
end

def kick
  sine_wave(60, 0.2).map.with_index do |sample, i|
    decay = 1.0 - (i.to_f / (SAMPLE_RATE * 0.2))
    sample * decay
  end
end

def snare
  samples = (SAMPLE_RATE * 0.2).to_i
  Array.new(samples) { rand(-1.0..1.0) * (1.0 - rand) }
end

def silence(duration)
  Array.new((SAMPLE_RATE * duration).to_i, 0.0)
end

def write_wav(filename, samples)
  File.open(filename, "wb") do |f|
    data = samples.map { |s| [[(s * 32767).to_i, 32767].min, -32768].max }.pack("s*")
    f.write "RIFF"
    f.write [36 + data.bytesize].pack("V")
    f.write "WAVEfmt "
    f.write [16, 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16].pack("VvvVVvv")
    f.write "data"
    f.write [data.bytesize].pack("V")
    f.write data
  end
end

beat = []
4.times do
  beat += kick
  beat += silence(0.2)
  beat += snare
  beat += silence(0.2)
end

filename = "beat_#{Time.now.to_i}.wav"
write_wav(filename, beat)
puts "Created #{filename}"


