# Class: AndroidBinaryXML
#
# Parse an Android Binary XML file
#
# Inspired by the code in axml2xml.pl by Josh Guilfoyle
#

require 'zip/zipfilesystem'	# needs: gem 'rubyzip'
require 'nokogiri'		# needs: gem 'nokogirl'

#manifest = getAndroidManifestFromAPK('/home/styrmis/workspace/ruby/unzip/test.zip')
#puts manifest.package.name, manifest.package.versionCode, manifest.package.versionName
#puts manifest.applicationLabel, manifest.sdkVersion, manifest.targetSdkVersion

# manifest = AndroidBinaryXML.open("/Users/larry/Projects/RailsProjects/android_manifest/db/AndroidManifest.xml")
# manifest.unpackXML
# manifest.close

# TODO: make this class Ruby only without Rails dependencies

class AndroidBinaryXML < ApplicationController
  @@TAG_OPEN = 0x10
  @@TAG_SUPPORTS_CHILDREN = 0x100000
  @@TAG_TEXT = 0x08
  
  def AndroidBinaryXML.open(filename)
    object = AndroidBinaryXML.new
    object.openFile(filename)
    return object
  end

  def openFile(filename)
    @nsmap = {}
    @xmlns = []
    @file = File.new(filename, "rb")
    return
  end
  
  def close
    return if @file == nil
    @file.close
    return
  end

# returns a hash with tags (HTML elements) and child tags
  def unpackXML
    return if @file == nil
    
    logger.debug "unpackXML start"
  
    # Some header, seems to be 3000 8000 always.
    magic = @file.read(4).unpack('vv')
    
    # Total file length.
    length = @file.read(4).unpack('V')
    length = length[0]			# convert from array to integer
  
    # Unknown, always 0100 1c00
    unknown1 = @file.read(4).unpack('vv')
    
    # Seems to be related to the total length of the string table.
    tlen = @file.read(4).unpack('V')
    tlen = tlen[0]			# convert from array to integer
  
    # Number of items in the string table, plus some header non-sense?
    totalStrings = @file.read(4).unpack('V')
    totalStrings = totalStrings[0]	#convert from array to integer
  
    # Seems to always be 0.
    unknown2 = @file.read(4).unpack('V')
    
    # Seems to always be 1.
    unknown3 = @file.read(4).unpack('V')
    
    # No clue, relates to the size of the string table?
    unknown4 = @file.read(4).unpack('V')
    
    # Seems to always be 0.
    unknown5 = @file.read(4).unpack('V')
  
    stringOffsets = []
    
    # Offset in string table of each string.
    totalStrings.times do |zz|
      offset = @file.read(4).unpack('V')
      stringOffsets[zz] = offset[0]
    end
  
    logger.debug stringOffsets
    
    strings = {}
    currentOffset = 0
    
    # The string table looks to have been serialized from a hash table, since
    # the positions are not sorted :)
    stringOffsets.each do |offset|
      if offset != currentOffset
        break
      end
      
      len = @file.read(2).unpack('v')
      
      len = len[0]	# convert from array to integer
  
      stringUnpacked = @file.read(len*2)
      str = stringUnpacked.tr_s(0.chr, '')
      logger.debug offset.to_s + ": " + str
  
      # Read the NUL, we're not interested in storing it.
      @file.read(2)
  
      strings[offset] = str
      
      currentOffset += ((len + 1) * 2) + 2
    end
  
    # Looks like the string table is word-aligned, so skip a few bytes
    @file.read(@file.tell % 4)
  
    # Read past the sentinel
    read_doc_past_sentinel(@file)
    
    # Convert the hash of strings to an array of strings
    strings = strings.values
    
    # Dump the string table to the logger
    strings.each_index do |zz|
      logger.debug "%2d:0x%x %s" % [zz, zz, strings[zz]]
    end
    
    tagHash = read_meat(@file, strings)
  
    logger.debug "unpackXML end - tagHash #{tagHash}"
    
    return tagHash
  end
  
private            # subsequent methods will be 'private'

  def read_doc_past_sentinel(file)
    # Read to sentinel
    while word = file.read(4)
      unpackedWord = word.unpack('V')
      unpackedWord = unpackedWord[0]			# convert from array to integer
      break if unpackedWord == 0xFFFFFFFF
    end
    
    # Read past it
    while word = peek_doc(file, 4)
      unpackedWord = word.unpack('V')
      unpackedWord = unpackedWord[0]			# convert from array to integer
      break unless unpackedWord == 0xFFFFFFFF
  
      file.read(4)
      break
    end
  end
  
  def read_meat(file, strings)
    tag = read_tag(file, strings)
    logger.debug "read_meat: tag: #{tag}"
    return if tag == nil
    
    tag['children'] = read_children(file, strings, tag['name'])
    
    return tag
  end
  
  # returns and array of tags
  def read_children(file, strings, stopTag)
    logger.debug "read_children: stopTag = #{stopTag}"
    
    tagArray = []
    while tag = read_tag(file, strings)
      # Whitespace leaks into this, but we don't support parsing it
      # correctly.
    #		next unless $tag->{name} =~ m/[a-z]/i;
    
    ##logger.debug "read_children: read_tag tag = #{tag}"
    
      if tag['flags'] & @@TAG_SUPPORTS_CHILDREN != 0
        if tag['flags'] & @@TAG_OPEN != 0
          tag['children'] = read_children(file, strings, tag['name']) 
        elsif tag['name'] == stopTag
          break
        end
      end
    
      tagArray << tag
    end
    
    logger.debug "read_children: end"
    return tagArray
  end
  
  # returns a tag hash
  def read_tag(file, strings)
    # Hack to support the strange xmlns attribute encoding without disrupting our
    # processor.
    readAgain = true
    tagHash = {}
    tagHash['attrs'] = 0
    flags = 0
    name = 0
    
    while readAgain
      readAgain = false
      name = file.read(4).unpack('V')
      name = name[0]			# convert from array to integer
      logger.debug "tags=%s (index %d, 0x%x) @ 0x%x" % [strings[name], name, name, file.pos]
    
      flags = file.read(4).unpack('V')
      flags = flags[0]			# convert from array to integer
      logger.debug "	flags=0x%04x (%d, open=%d, children=%d, text=%d)" % [flags,
                           flags,
                           flags & @@TAG_OPEN,
                           flags & @@TAG_SUPPORTS_CHILDREN,
                           flags & @@TAG_TEXT]
    
      # Strange way to specify xmlns attribute.
      if strings[name] && strings[flags]
        ns = strings[name]
        url = strings[flags]
      
        # TODO: How do we expect this?
        if ns =~ /[a-z]/i ### && url =~ m/^http:\/\//
          logger.debug "new map: #{flags} => #{name}"
          @nsmap[flags] = name
          logger.debug " nsmap #{@nsmap}"
  
          @xmlns << { 'name' => "xmlns:#{ns}", 'value' => url }
  
          read_doc_past_sentinel(file)
          readAgain = true
        end
      end
    end
  
    if (flags & @@TAG_SUPPORTS_CHILDREN) != 0 && (flags & @@TAG_OPEN) != 0
      tagHash['attrs'] = []

      attrs = file.read(4).unpack('V')
      attrs = attrs[0]			# convert from array to integer
      logger.debug "	attrs=%d" % attrs
  
      unknown = file.read(4).unpack('V')
      unknown = unknown[0]			# convert from array to integer
  
      attrs.times do |zz|
        ns = file.read(4).unpack('V')
        ns = ns[0]			# convert from array to integer
  
        ns != 0xFFFFFFFF and
          logger.debug "		namespace=%s" % strings[ns]
  
        attr = file.read(4).unpack('V')
        attr = attr[0]			# convert from array to integer
        logger.debug "		attr=%s" % strings[attr]
  
        # TODO: Escaping?
        value = file.read(4).unpack('V')
        value = value[0]			# convert from array to integer
        logger.debug "		value=%s (%x)" % [strings[value], value]
  
        attrflags = file.read(4).unpack('V')
        attrflags = attrflags[0]			# convert from array to integer
  
        attr = {
          'name' => strings[attr],
          'value' => strings[value],
          'flags' => attrflags
        }
        logger.debug " attr hash: #{attr}"
  
        #xx = @nsmap[ns]
        ns != 0xFFFFFFFF and attr['ns'] = strings[@nsmap[ns]]
  
        tagHash['attrs'] << attr
  
        padding = file.read(4).unpack('V')
      end
  
      read_doc_past_sentinel(file)
    else
      # There is strong evidence here that what I originally thought to be a sentinel is not
      whatever = file.read(4).unpack('V')
      huh = file.read(4).unpack('V')
      
      read_doc_past_sentinel(file)
    end
 
    tagHash['name'] = strings[name]
    tagHash['flags'] = flags

logger.debug "read_tag end - tagHash: #{tagHash}" 
    return tagHash
  end

  def peek_doc(file, numBytes)
    data = file.read(numBytes)
    file.pos -= numBytes
    return data
  end
end