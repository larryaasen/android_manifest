require 'zip/zipfilesystem'	# needs: gem 'rubyzip'

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
  logger.debug "getAndroidManifestFromAPK:1 " + File.basename(__FILE__)
  begin
    Zip::ZipFile.open(apkFile) do |zipfile|
      logger.debug "getAndroidManifestFromAPK:2: " + zipfile
      dir = zipfile.dir
      logger.debug "getAndroidManifestFromAPK:3: " + dir
	
      entry = dir.find_entry('AndroidManifest.xml')
      logger.debug "getAndroidManifestFromAPK:4"
      entry.get_input_stream('')
      logger.debug "getAndroidManifestFromAPK:5"
    end
    
  rescue Zip::ZipDestinationFileExistsError => e
    # I'm going to ignore this and just overwrite the files.
    logger.debug "File Does Not Exist: " + e
      
    rescue => e
  else
    logger.debug "Exception: " + e
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
