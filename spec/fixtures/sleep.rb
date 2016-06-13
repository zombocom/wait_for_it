STDOUT.sync = true

puts "Started"
val = ENV["SLEEP"].to_i
sleep val
puts "slept for #{val}"
puts "Done"