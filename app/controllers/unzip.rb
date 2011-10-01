require 'zip/zipfilesystem'	# needs: gem 'rubyzip'
require 'nokogiri'		# needs: gem 'nokogirl'

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

def unpackXML
      
  file = File.new("/Users/larry/Projects/RailsProjects/android_manifest/db/AndroidManifest.xml", "rb")

  # Some header, seems to be 3000 8000 always.
  magic = file.read(4).unpack('vv')
  
  # Total file length.
  length = file.read(4).unpack('V')

  # Unknown, always 0100 1c00
  unknown1 = file.read(4).unpack('vv')
  
  # Seems to be related to the total length of the string table.
  tlen = file.read(4).unpack('V')

  # Number of items in the string table, plus some header non-sense?
  totalStrings = file.read(4).unpack('V')
  
  totalStrings = totalStrings[0]		#convert from array to integer

  # Seems to always be 0.
  unknown2 = file.read(4).unpack('V')
  
  # Seems to always be 1.
  unknown3 = file.read(4).unpack('V')
  
  # No clue, relates to the size of the string table?
  unknown4 = file.read(4).unpack('V')
  
  # Seems to always be 0.
  unknown5 = file.read(4).unpack('V')

  stringOffsets = []
  
  # Offset in string table of each string.
  totalStrings.times do |zz|
    stringOffsets[zz] = file.read(4).unpack('V')
  end

  strings = {}
  currentOffset = 0
  
  # The string table looks to have been serialized from a hash table, since
  # the positions are not sorted :)
  stringOffsets.each do |offset|
    if offset != currentOffset
      break
    end
    
    len = file.read(2).unpack('v')
    
    len = len[0]	# convert from array to integer

    stringUnpacked = file.read(len*2)
    str = stringUnpacked.tr_s(0.chr, '')
    logger.debug str

    # Read the NUL, we're not interested in storing it.
    file.read(2)

    strings[offset] = str
    
    currentOffset += ((len + 1) * 2) + 2
  end

end

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
