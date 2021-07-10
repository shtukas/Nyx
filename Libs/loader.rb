
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'colorize'

require 'sqlite3'

require 'find'

require 'thread'

require "time"

require 'colorize'

require 'pepin'

=begin
list = Array[String]
item = Pepin.search(list) # Launches interactive window and returns selected item
=end

# -----------------------------------------------------------------------

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"

# ------------------------------------------------------------

require_relative "BinaryBlobsService.rb"

require_relative "Config.rb"

require_relative "Elizabeth.rb"

require_relative "Fsck.rb"

require_relative "Galaxy.rb"

require_relative "Interpreting.rb"

require_relative "NxNode.rb"
require_relative "NxUniqueString.rb"
require_relative "Nx45AstPointer.rb"
require_relative "Nx102.rb"

require_relative "NxEntity.rb"
require_relative "NxEvent.rb"
require_relative "NxListing.rb"
require_relative "NxTag.rb"
require_relative "NxTimelinePoint.rb"

require_relative "NxDirectory2.rb"

require_relative "Links.rb"

require_relative "Search.rb"

require_relative "Utils.rb"

# ------------------------------------------------------------


