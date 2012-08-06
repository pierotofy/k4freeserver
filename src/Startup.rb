require './ProgramInfo'
def startup(args)
  puts PROGRAM_NAME + " " + PROGRAM_VERSION if args.v
  
  if args.help
    puts <<EOF
Usage: k4freeserver <arguments>

--help               Display this message
-v                   Enable verbose
--version            Display version
--bindaddr           Specify a bind address for the server (default is 0:0:0:0)
--device             <device> (case sensitive)
                     1 --> Kindle 4
                     2 --> Kindle Touch
EOF
    exit(0)
  end

  if args.version
    puts PROGRAM_VERSION
    exit(0)
  end
end
