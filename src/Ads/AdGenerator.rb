class AdGenerator
  require 'fileutils'
  require 'digest/md5'
  
  require './zip/zip'
  require './zip/zipfilesystem'
 
  def initialize(verbose)
    @verbose = verbose
    
    @screensaver_extension =
      case $device
        when 'Kindle' 
          'gif'
        when 'KindleTouch' 
          'png'        
      end
    
    @details_extension = 
      case $device
        when 'Kindle' 
          'xml'
        when 'KindleTouch' 
          'html'        
      end
    
  end
  
  def generate_ad(ad_id, version, output_folder)
    root_dir = output_folder + "/" + ad_id +  "_tmp"
    Dir.mkdir(root_dir) if not Dir.exists?(root_dir)
    
    ad_content_folder = root_dir + "/" + ad_id
    Dir.mkdir(ad_content_folder) if not Dir.exists?(ad_content_folder)
    
    # Cleanup
    File.delete(root_dir + "/ad-manifest.json") if File.exists?(root_dir + "/ad-manifest.json")
    File.delete(root_dir + "/archive.zip") if File.exists?(root_dir + "/archive.zip")
    File.delete(ad_content_folder + "/snippet.json") if File.exists?(ad_content_folder + "/snippet.json")
    File.delete(ad_content_folder + "/details.xml") if File.exists?(ad_content_folder + "/details.xml")
    File.delete(ad_content_folder + "/details.html") if File.exists?(ad_content_folder + "/details.html")
    File.delete(ad_content_folder + "/screensvr.gif") if File.exists?(ad_content_folder + "/screensvr.gif")
    File.delete(ad_content_folder + "/screensvr.png") if File.exists?(ad_content_folder + "/screensvr.png")
    File.delete(ad_content_folder + "/thumb.gif") if File.exists?(ad_content_folder + "/thumb.gif")
    File.delete(ad_content_folder + "/banner.gif") if File.exists?(ad_content_folder + "/banner.gif")
    
    # OK!
    save_to_file(generate_details_file(ad_id), ad_content_folder + "/details.#{@details_extension}")
    
    # Copy static files
    FileUtils::copy_file("./Ads/#{$device}/Static/banner.gif", ad_content_folder + "/banner.gif")
    FileUtils::copy_file("./Ads/#{$device}/Static/thumb.gif", ad_content_folder + "/thumb.gif")
    FileUtils::copy_file("./Ads/#{$device}/Static/snippet.json", ad_content_folder + "/snippet.json")
    
    # Need to sync for concurrent access?
    screensaver_file = $g_screensavers[($g_scindex+=1) % $g_screensavers.count] 
    FileUtils::copy_file(screensaver_file, ad_content_folder + "/screensvr.#{@screensaver_extension}")
    
    save_to_file(generate_ad_manifest_file(ad_id, version, ad_content_folder), root_dir + "/ad-manifest.json")
    
    # Zip it up, result is in "archive.zip"
    
    # On windows use compress utility
    if RUBY_PLATFORM =~ /(win|w)32$/
      project_home = Dir.pwd
      Dir.chdir(project_home + "/" + root_dir)
      puts "Directory changed to #{project_home}/#{root_dir}" if @verbose
      puts "Executing #{project_home}/winzip/zip.exe -r #{project_home}/#{root_dir}/archive.zip ." if @verbose
      system(%Q{"#{project_home}/winzip/zip.exe" -r "#{project_home}/#{root_dir}/archive.zip" .})
      
      puts "Directory reverted to #{project_home}" if @verbose
      Dir.chdir(project_home)      
    else 
      # On others use the zip lib
      compress(root_dir)
    end
    
    # Return md5 and size
    return compute_md5(root_dir + "/archive.zip"),
           File.size(root_dir + "/archive.zip")
  end
  
  def save_to_file(content, path)
    f = File.new(path, "w")
    f.write(content)
    f.close
  end
  
  def compute_md5(filename)
    Digest::MD5.hexdigest(File.open(filename, "rb") { |f| f.read })
  end
  
  def compress(path)
    path.sub!(%r[/$],'')
    archive = File.join(path,'archive.zip')
    FileUtils.rm archive, :force=>true

    Zip::ZipFile.open(archive, 'w') do |zipfile|
      Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
        zipfile.add(file.sub(path+'/',''),file)
      end
    end
  end
  
  def generate_details_file(ad_id)
    details_content = get_template("details.#{@details_extension}"){ |entry|
        case entry
          when "AD_ID"
            ad_id
        end
      }
     
    return details_content
  end
  
  def generate_ad_manifest_file(ad_id, version, ad_content_folder)
      ad_manifest = get_template("ad-manifest.json"){ |entry|
        case entry
          when "AD_ID"
            ad_id
          when "VERSION"
            version
          when "CREATIVE_ID"
            # Random 13 digit number????
            '%010d' % rand(10 ** 13)
          when "SCREEN_SAVER_CHKSUM"
            compute_md5(ad_content_folder + "/screensvr.#{@screensaver_extension}")
          when "DETAILS_CHKSUM"
            compute_md5(ad_content_folder + "/details.#{@details_extension}")
          when "BANNER_CHKSUM"
            compute_md5(ad_content_folder + "/banner.gif")
          when "THUMB_CHKSUM"
            compute_md5(ad_content_folder + "/thumb.gif")
          when "SNIPPET_CHKSUM"
            compute_md5(ad_content_folder + "/snippet.json")
         
        end
      }
     
    return ad_manifest  
  end
  
  def get_template_content(template_filename)
    filename = "Ads/#{$device}/Templates/#{template_filename}"

    if File.exists?(filename)
      return File.read(filename)
    end

    return ""
  end

  def get_template(template_filename)
    content = get_template_content(template_filename)

    content = content.gsub(/\{([\w_\d]+)\}/){
      yield $1
    }
    return content
  end
end
