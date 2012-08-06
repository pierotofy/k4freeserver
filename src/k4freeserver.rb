#!/usr/bin/ruby1.9.1

require './PTCommon/Arguments'
require './Startup'
require './K4Server'

args = PTCommon::Arguments.new(
  {
  'bindaddr' => "0:0:0:0",
  'v' => false, # Verbose mode
  'help' => false,
  'version' => false,
  'device' => :askuser,
  })
startup(args)

if args.device == :askuser
  devicenumber = ''
  while not ('1'..'2').member?(devicenumber)
    puts "Not a valid option!" if devicenumber != ''
    
    puts "What device are you using?\n"
    puts "\t1) Kindle 4"
    puts "\t2) Kindle Touch"
    puts "[1-2]: ".chomp
    devicenumber = $stdin.gets.chomp[0]
  end  
else
  devicenumber = args.device
end

if not ('1'..'2').member?(devicenumber)
  $stderr.puts "Invalid device option #{devicenumber}, exiting..."
  exit(1)
end

case devicenumber
  when '1'
    $device = "Kindle"
  when '2'
    $device = "KindleTouch"
end

puts "Choosing #{$device} as device" if args.v

# Enum files in screensaver folder

if $device == 'Kindle'
  image_extension = 'gif'
elsif $device == 'KindleTouch'
  image_extension = 'png'
end

screensavers = Dir.glob("./Ads/#{$device}/Screensavers/*.#{image_extension}")
screensavers.concat(Dir.glob("./Ads/#{$device}/Screensavers/*.#{image_extension.upcase}"))
screensavers = screensavers.uniq

if screensavers.count == 0
  $stderr.puts "I wasn't able to find any screensavers in the ./Ads/#{$device}/Screensavers folder. Make sure there is at least one image in that folder before running this program. Exiting..."
  exit(1)
end

puts "Images found: ", screensavers if args.v

# Shuffle
$g_screensavers = screensavers.sort_by { rand }
$g_scindex = 0

begin
  server = K4Server.new(80, args.bindaddr, args.v)
  server.start
rescue Errno::EADDRINUSE
  $stderr.puts "Cannot start server on #{args.bindaddr}:#{args.port} because the port is already used by another program. Exiting..."
  exit(1)
end
