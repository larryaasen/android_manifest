# Class: AndroidAPK
#
# Open the APK file and parse the AndroidManifest.XML file
#

require 'AndroidBinaryXML'

class AndroidAPK < ApplicationController

	def AndroidAPK.getAndroidManifestFromAPK(apkFile)
		apkFile = File.expand_path(apkFile)
		logger.debug "getAndroidManifestFromAPK:1 " + File.basename(__FILE__)
	
		#File.open(apkFile, "r") do |file|
		#	logger.debug "getAndroidManifestFromAPK:2.1: " + file.path
		#end
	
		logger.debug "getAndroidManifestFromAPK:2 open " + apkFile
		if File.exist?(apkFile)
			
			begin
				Zip::ZipFile.open(apkFile) do |zipfile|
					logger.debug "getAndroidManifestFromAPK:3: " + zipfile.name
					entry = zipfile.find_entry('AndroidManifest.xml')
					logger.debug "getAndroidManifestFromAPK: entry " + entry.name
					

					# Create a new filename for the extracted AndroidManifest.xml file
          file_path = File.join(File.dirname(apkFile), entry.name)
          
          # If the extracted file exists then remove it
          if File.exists?(file_path)
						FileUtils.rm(file_path)
          end
          
          # Extract the AndroidManifest.xml file
          zipfile.extract(entry, file_path)

					logger.debug "getAndroidManifestFromAPK: file_path #{file_path}"
						
					manifest = AndroidBinaryXML.open(file_path)
					manifest.unpackXML
					manifest.close
					
					logger.debug "getAndroidManifestFromAPK:5"
				end		# do |zipfile|
				
#			rescue Zip::ZipDestinationFileExistsError => ex
#				logger.debug "getAndroidManifestFromAPK: File Does Not Exist: " + ex
		
#			rescue  => ex
#				logger.debug "getAndroidManifestFromAPK: Exception: #{ex}"
			end
		else
		end
		
		logger.debug "getAndroidManifestFromAPK:9 " + File.basename(__FILE__)
	end
  
end