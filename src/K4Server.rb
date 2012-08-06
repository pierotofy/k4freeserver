require './Servlets/AdServlet'

require './ServerLogger'

require 'webrick'
include WEBrick

class K4Server
  attr_accessor :webrick

  def initialize(port, address = nil, verbose = false)
   @verbose = verbose
   @webrick = HTTPServer.new(:Port => port, :Logger => ServerLogger.new(verbose), 
     :DocumentRoot => "./WebRoot", :DoNotReverseLookup => true)
   registerServlets   
   ['INT', 'TERM'].each { |signal|
      trap(signal){ @webrick.shutdown } 
   }
  end
  
  def registerServlets
    @webrick.mount "/DTCP/", Servlets::AdServlet, @verbose  #Pass params to servlet here
  end
  
  def start
    @webrick.start;
  end
  
end
