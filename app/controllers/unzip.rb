# Parse an Android Binary XML file
#
# Inspired by the code in axml2xml.pl by Josh Guilfoyle
#

require 'zip/zipfilesystem'	# needs: gem 'rubyzip'
require 'nokogiri'		# needs: gem 'nokogirl'


    manifest = AndroidBinaryXML.open("/Users/larry/Projects/RailsProjects/android_manifest/db/AndroidManifest.xml")
    manifest.unpackXML
    manifest.close

# source should be a zip file.
# target should be a directory to output the contents to.

def unzip_file(source, target)
  # Create the target directory.
  # We'll ignore the error scenario where
  begin
    Dir.mkdir(target) unless File.exists? target
  end
  
  Zip::ZipFile.open(source) do |zipfile|
    dir = zipfile.dir
    
    dir.entries('.').each do |entry|
      zipfile.extract(entry, "#{target}/#{entry}")
    end
  end

  rescue Zip::ZipDestinationFileExistsError => ex
  # I'm going to ignore this and just overwrite the files.

  rescue => ex
  puts ex

end

# unzip_file('/home/styrmis/workspace/ruby/unzip/test.zip', '/home/styrmis/workspace/ruby/unzip/target')

def getAndroidManifestFromAPK(apkFile)
  apkFile = File.expand_path(apkFile)
  logger.debug "getAndroidManifestFromAPK:1 " + File.basename(__FILE__)

  File.open(apkFile, "r") do |file|
    logger.debug "getAndroidManifestFromAPK:2.1: " + file.path
  end

  if File.exist?(apkFile)
    logger.debug "getAndroidManifestFromAPK: open " + apkFile

    begin
      Zip::ZipFile.open(apkFile) do |zipfile|
	logger.debug "getAndroidManifestFromAPK:3: " + zipfile.name
	entry = zipfile.find_entry('AndroidManifest.xml')
	logger.debug "getAndroidManifestFromAPK: entry " + entry.name
	entry.get_input_stream() do |stream|
	  logger.debug "getAndroidManifestFromAPK: stream " + stream.eof?.to_s
	  
	  xmlDoc = Nokogiri::XML(stream)
	  logger.debug "getAndroidManifestFromAPK: xmlDoc " + xmlDoc.name
	  
	  root = xmlDoc.root()
	  logger.debug "getAndroidManifestFromAPK: root " + root.name
	  
	  Nokogiri::XML::Reader.from_io(stream).each do |node|
	  logger.debug "getAndroidManifestFromAPK: node "
	    if node.name == 'book' and node.node_type == XML::Reader::TYPE_ELEMENT
	      yield(Nokogiri::XML(node.outer_xml).root)
	    end
	  end
	  logger.debug "getAndroidManifestFromAPK: xml " + doc.url
	  
	  lines = stream.readlines
	  logger.debug "getAndroidManifestFromAPK: lines " + lines.length.to_s
	  logger.debug "getAndroidManifestFromAPK: line: " + lines[0]
	  #stream.each do |line|
	  #  logger.debug "getAndroidManifestFromAPK: line: " + line.to_s
	  #end
	end
	logger.debug "getAndroidManifestFromAPK:5"
      end
      
    rescue Zip::ZipDestinationFileExistsError => ex
      # I'm going to ignore this and just overwrite the files.
      logger.debug "getAndroidManifestFromAPK: File Does Not Exist: " + ex
	
      rescue => ex
    rescue  => ex
      logger.debug "getAndroidManifestFromAPK: Exception: " + ex
    end
  else
  end
  
  logger.debug "getAndroidManifestFromAPK:9 " + File.basename(__FILE__)
end

def sampleExceptions

	f = File.open("testfile")
	begin
	  # .. process
	rescue
	  # .. handle error
	ensure
	  f.close unless f.nil?
	end
end

#manifest = getAndroidManifestFromAPK('/home/styrmis/workspace/ruby/unzip/test.zip')
#puts manifest.package.name, manifest.package.versionCode, manifest.package.versionName
#puts manifest.applicationLabel, manifest.sdkVersion, manifest.targetSdkVersion
