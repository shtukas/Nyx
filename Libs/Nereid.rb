# require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Nereid.rb"

# ---------------------------------------------------------------------------------------

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require 'sqlite3'

require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, "SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

# ---------------------------------------------------------------------------------------

class NereidUtils

    # NereidUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.hex
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # NereidUtils::openUrl(url)
    def self.openUrl(url)
        system("open -a Safari '#{url}'")
    end
end

class NereidBinaryBlobsService

    # NereidBinaryBlobsService::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Elements-Datablobs"
    end

    # NereidBinaryBlobsService::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # NereidBinaryBlobsService::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{NereidBinaryBlobsService::repositoryFolderPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # NereidBinaryBlobsService::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = "#{NereidBinaryBlobsService::repositoryFolderPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}/#{nhash}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
end

