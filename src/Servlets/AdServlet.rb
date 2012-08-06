module Servlets
  require 'webrick'
  require './Ads/AdGenerator'
  require 'thread'
  
  # Manage requests (asynchronous requests are not supported, we allow only one
  # at a time)
  $semaphore = Mutex.new

  class AdServlet < WEBrick::HTTPServlet::AbstractServlet
   
    def initialize(server, verbose)
      super(server)
      @verbose = verbose
    end

    def do_GET(request, response)
      $semaphore.synchronize do
        # Parse request to find ad-id
        if request.to_s() =~ /GET \/DTCP\/[\d]{4}-[\d]{1,2}\/ad-([\d]+)\.([\d]+)\.apg/
          ad_id = $1
          version = $2

          print "ad-id matched ", ad_id, "\n" if @verbose
          print "version matched ", version, "\n" if @verbose

          # Generate ad based on ad-id
          adgen = AdGenerator.new(@verbose)
          (archive_md5, archive_size) = adgen.generate_ad(ad_id, version, "./tmp")

          # Send result ./tmp/ad_id_tmp/archive.zip

          response.status = 200
          response['Content-Type'] = "application/x-apg-zip"
          response['x-amz-id-2'] = "UnDcEw1ofRxKSLsv8JfRdi//qzoW6zqRhQ/vFtvll2HWHJA7mRk5VuojSsRc9mP6"
          response['x-amz-request-id'] = "5CB3E67F5EF4F262"
          response['ETag'] = "\"#{archive_md5}\""
          response['Content-Length'] = archive_size.to_s()
          response['Server'] = "AmazonS3"
          response['Accept-Ranges'] = "bytes"
          response.body = open("./tmp/#{ad_id}_tmp/archive.zip", "rb") {|io| io.read } 

          # TODO cleanup temporary directory
        end
      end
    end
  end
end
