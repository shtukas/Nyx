
# encoding: UTF-8

=begin
    
Some Neired Entities are going to be represented as folders on the file system.

The folder name can be anything, unique, unrelated to the uuid of the quark. In this first implementation we are ging to use L22s.

Each folder then has the following files
    - uuid.txt        : which contains the uuid of the quark
    - description.txt : The description
    - type.txt        : which contains the type "Line" | "Url" | "Text" | "UniqueFileClickable" | "FSLocation" | "FSUniqueString"
    - manifest.txt     : which, depending on the type, contains
        - The line 
        - The url
        - The file name of the text file (which is in the same folder)
        - The filename of the clikable file (which is in the same folder)
        - The foldername of the directory (which is in the same folder)
        - The unique string

Glosarry:
    - The record in the database , record
    - The quark json object    , quark object
    - The quark filepath       , quark filepath
    - The content location       , content location

=end

class FileSystemAdapter

    # FileSystemAdapter::quarksRepositoryFolderPath()
    def self.quarksRepositoryFolderPath()
        "/Users/pascal/Galaxy/Documents/02-NyxQuarks"
    end

    # FileSystemAdapter::makeNewQuark(uuid, description, type, content)
    # Here is what the content is per type
    # "Line"                : the description, in this case the line is aligned with the description
    # "Url"                 : the url
    # "Text"                : the text
    # "UniqueFileClickable" : filepath
    # "FSLocation"          : location
    # "FSUniqueString"      : String
    def self.makeNewQuark(uuid, description, type, contentInstruction)
        raise "217a6dd1-ba91-45de-857b-b806d0c7d377" if !["Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"].include?(type)

        nyxQuarkFolderpath = "#{FileSystemAdapter::quarksRepositoryFolderPath()}/#{LucilleCore::l22()}"

        FileUtils.mkpath(nyxQuarkFolderpath)

        File.open("#{nyxQuarkFolderpath}/uuid.txt", "w") {|f| f.write(uuid)}
        File.open("#{nyxQuarkFolderpath}/description.txt", "w") {|f| f.write(description)}
        File.open("#{nyxQuarkFolderpath}/type.txt", "w") {|f| f.write(type)}

        if type == "Line" then
            raise "877fbaf8-1823-4996-b622-ffde548caf57" if (description != contentInstruction)
            File.open("#{nyxQuarkFolderpath}/manifest.txt", "w") {|f| f.write(contentInstruction)}
        end

        if type == "Url" then
            File.open("#{nyxQuarkFolderpath}/manifest.txt", "w") {|f| f.write(contentInstruction)}
        end

        if type == "Text" then
            contentFilename = "#{SecureRandom.hex(4)}.txt"
            contentFilepath = "#{nyxQuarkFolderpath}/#{contentFilename}"
            File.open(contentFilepath, "w") {|f| f.write(contentInstruction)}
            File.open("#{nyxQuarkFolderpath}/manifest.txt", "w") {|f| f.write(contentFilename)}
        end

        if type == "UniqueFileClickable" then
            filename2 = "#{SecureRandom.hex(4)}#{File.extname(contentInstruction)}"
            filepath2 = "#{nyxQuarkFolderpath}/#{filename2}"
            FileUtils.cp(contentInstruction, filepath2)
            File.open("#{nyxQuarkFolderpath}/manifest.txt", "w") {|f| f.write(filename2)}
        end

        if type == "FSLocation" then
            filename2 = SecureRandom.hex(4)
            filepath2 = "#{nyxQuarkFolderpath}/#{filename2}"
            FileUtils.mkdir(filepath2)
            LucilleCore::copyFileSystemLocation(contentInstruction, filepath2)
            File.open("#{nyxQuarkFolderpath}/manifest.txt", "w") {|f| f.write(filename2)}
        end
    end

    # FileSystemAdapter::getQuarkFolderpathByUUIDOrNullUseTheForce(uuid) : Folderpath or Nil
    def self.getQuarkFolderpathByUUIDOrNullUseTheForce(uuid)
        LucilleCore::locationsAtFolder(FileSystemAdapter::quarksRepositoryFolderPath()).each{|nyxQuarkFolderpath|
            uuidFilepath = "#{nyxQuarkFolderpath}/uuid.txt"
            quarkUUID = IO.read(uuidFilepath).strip
            return nyxQuarkFolderpath if (quarkUUID == uuid)
        }
        nil
    end

    # FileSystemAdapter::getQuarkFolderpathByUUIDOrNull(uuid) : Folderpath
    def self.getQuarkFolderpathByUUIDOrNull(uuid)
        folderpath = KeyValueStore::getOrNull(nil, "8308926b-332a-4ca9-acf0-3bbc63fc90ab:#{uuid}")
        if folderpath then
            uuidFilepath = "#{folderpath}/uuid.txt"
            if File.exists?(uuidFilepath) then
                return folderpath if (IO.read(uuidFilepath).strip == uuid)
            end
        end

        folderpath = FileSystemAdapter::getQuarkFolderpathByUUIDOrNullUseTheForce(uuid)
        return nil if folderpath.nil?
        KeyValueStore::set(nil, "8308926b-332a-4ca9-acf0-3bbc63fc90ab:#{uuid}", folderpath)

        folderpath 
    end

    # FileSystemAdapter::setQuarkDescription(uuid, description)
    def self.setQuarkDescription(uuid, description)
        # This updates the database and the quark on quark folder
        folderpath = FileSystemAdapter::getQuarkFolderpathByUUIDOrNull(uuid)
        raise "error: 2bb4a688-9303-4a94-b5be-0856902cdd90 ; could not set the description (quark folderpath not found) for uuid: #{uuid}"
        File.open("#{folderpath}/description.txt", "w") {|f| f.write(description)}
    end

    # FileSystemAdapter::getQuarkType(uuid) : Folderpath
    def self.getQuarkType(uuid)
        folderpath = FileSystemAdapter::getQuarkFolderpathByUUIDOrNull(uuid)
        raise "error: adfc4dc1-f7a3-462b-8c4e-b368f3f9621e ; could not get the type (quark folderpath not found) for uuid: #{uuid}" if folderpath.nil?
        filepath = "#{folderpath}/type.txt"
        raise "error: 8e0c51fa-89f7-4ef8-a1ef-b9ccf8f0588b ; could not find the type file (#{filepath}) for uuid: #{uuid}" if !File.exist?(filepath)
        IO.read(filepath)
    end

    # FileSystemAdapter::getQuarkContentDataOrNull(uuid)
    def self.getQuarkContentDataOrNull(uuid)
        # This only returns data for "Line", "Url", "FSUniqueString" otherwise raise an error
        folderpath = FileSystemAdapter::getQuarkFolderpathByUUIDOrNull(uuid)
        type = FileSystemAdapter::getQuarkType(uuid)
        raise "error: 32257b83-4473-494d-9d32-937db29767bf ; trying to extract content data for a non supported type" if !["Line", "Url", "FSUniqueString"].include?(type)
        IO.read("#{folderpath}/manifest.txt")
    end

    # FileSystemAdapter::getQuarkContentFilepathOrNull(uuid)
    def self.getQuarkContentFilepathOrNull(uuid)
        # This only returns data for "Text", "UniqueFileClickable", "FSLocation"
        folderpath = FileSystemAdapter::getQuarkFolderpathByUUIDOrNull(uuid)
        type = FileSystemAdapter::getQuarkType(uuid)
        raise "error: 781cc900-35ae-4b69-b0f4-bc6f0fa420f7 ; trying to extract content path for a non supported type" if !["Text", "UniqueFileClickable", "FSLocation"].include?(type)
        
        if type == "Text" then
            contentFilename = IO.read("#{folderpath}/manifest.txt").strip
            return "#{folderpath}/#{contentFilename}"
        end

        if type == "UniqueFileClickable" then
            contentFilename = IO.read("#{folderpath}/manifest.txt").strip
            return "#{folderpath}/#{contentFilename}"
        end

        if type == "FSLocation" then
            contentFilename = IO.read("#{folderpath}/manifest.txt").strip
            return "#{folderpath}/#{contentFilename}"
        end
    end

    # FileSystemAdapter::fsckQuark(uuid)
    def self.fsckQuark(uuid)
        quarkFolderpath = FileSystemAdapter::getQuarkFolderpathByUUIDOrNull(uuid)
        if quarkFolderpath.nil? then
            raise "fsck fail: did not find quark folderpath for uuid: #{uuid}"
        end
        if !File.exists?("#{quarkFolderpath}/uuid.txt") then
            raise "fsck fail: did not find uuid.txt for uuid: #{uuid}"
        end
        if uuid != IO.read("#{quarkFolderpath}/uuid.txt").strip then
            raise "fsck fail: did not validate uuid in uuid.txt for uuid: #{uuid}"
        end
        if !File.exists?("#{quarkFolderpath}/description.txt") then
            raise "fsck fail: did not find description.txt for uuid: #{uuid}"
        end
        if !File.exists?("#{quarkFolderpath}/type.txt") then
            raise "fsck fail: did not find type.txt for uuid: #{uuid}"
        end
        type = IO.read("#{quarkFolderpath}/type.txt")
        if !["Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"].include?(type) then
            raise "fsck fail: non standard type (found '#{type}') for uuid: #{uuid}"
        end
        if ["Line", "Url", "FSUniqueString"].include?(type) then
            if FileSystemAdapter::getQuarkContentDataOrNull(uuid).nil? then
                raise "fsck fail: could not find content data for uuid: #{uuid}"
            end
        end
        if ["Text", "UniqueFileClickable", "FSLocation"].include?(type) then
            if FileSystemAdapter::getQuarkContentFilepathOrNull(uuid).nil? then
                raise "fsck fail: could not find content filepath for uuid: #{uuid}"
            end
        end
    end

    # ----------------------------------------------------------------------------------------

    # FileSystemAdapter::access(uuid) # input: uuid: String | quark Quark
    def self.access(uuid)
        raise "Access has not been implemented yet"
    end

    # FileSystemAdapter::edit(uuid)
    def self.edit(uuid)
        raise "Edition has not been implemented yet"
    end

    # FileSystemAdapter::transmute(uuid)
    def self.transmute(uuid)
        raise "Transmutation has not been implemented yet"
    end

    # ----------------------------------------------------------------------------------------

    # FileSystemAdapter::destroyQuarkOnDisk(uuid)
    def self.destroyQuarkOnDisk(uuid)
        folderpath = FileSystemAdapter::getQuarkFolderpathByUUIDOrNull(uuid)
        raise "error: 40cbbc29-6e16-43d7-98e6-eaec68f762a7" if !File.exists?(folderpath)
        LucilleCore::removeFileSystemLocation(folderpath)
    end
end
