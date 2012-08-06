require 'webrick'
include WEBrick

class ServerLogger < BasicLog
  def initialize(verbose)
    super($stdout)
    @verbose = verbose
  end
  
  def log(level, data)
    super(level,data) if @verbose
  end
  
  def fatal(msg)
    $stderr.puts msg
    exit(1)
  end
  
  def error(msg)
    $stderr.puts msg
  end
end
