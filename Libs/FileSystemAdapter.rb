
# encoding: UTF-8

class FileSystemAdapter

    # FileSystemAdapter::nxpodsRepositoryFolderPath()
    def self.nxpodsRepositoryFolderPath()
        "/Users/pascal/Galaxy/Documents/NxPods"
    end

    # FileSystemAdapter::getNxPodFolderpathByUUID(uuid) : Folderpath
    def self.getNxPodFolderpathByUUID(uuid)
        "#{FileSystemAdapter::nxpodsRepositoryFolderPath()}/#{uuid}"
    end

    # FileSystemAdapter::makeNewNxPod(uuid, description, type, content)
    # Here is what the content is per type
    # "Line"                : the description, in this case the line is aligned with the description
    # "Url"                 : the url
    # "Text"                : the text
    # "UniqueFileClickable" : filepath
    # "FSLocation"          : location
    # "FSUniqueString"      : String
    def self.makeNewNxPod(uuid, description, type, contentInstruction)
        raise "217a6dd1-ba91-45de-857b-b806d0c7d377" if !["Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"].include?(type)

        nyxNxPodFolderpath = FileSystemAdapter::getNxPodFolderpathByUUID(uuid)

        FileUtils.mkpath(nyxNxPodFolderpath)

        File.open("#{nyxNxPodFolderpath}/uuid.txt", "w") {|f| f.write(uuid)}
        File.open("#{nyxNxPodFolderpath}/description.txt", "w") {|f| f.write(description)}
        File.open("#{nyxNxPodFolderpath}/type.txt", "w") {|f| f.write(type)}

        if type == "Line" then
            raise "877fbaf8-1823-4996-b622-ffde548caf57" if (description != contentInstruction)
            File.open("#{nyxNxPodFolderpath}/manifest.txt", "w") {|f| f.write(contentInstruction)}
        end

        if type == "Url" then
            File.open("#{nyxNxPodFolderpath}/manifest.txt", "w") {|f| f.write(contentInstruction)}
        end

        if type == "Text" then
            contentFilename = "#{SecureRandom.hex(4)}.txt"
            contentFilepath = "#{nyxNxPodFolderpath}/#{contentFilename}"
            File.open(contentFilepath, "w") {|f| f.write(contentInstruction)}
            File.open("#{nyxNxPodFolderpath}/manifest.txt", "w") {|f| f.write(contentFilename)}
        end

        if type == "UniqueFileClickable" then
            filename2 = "#{SecureRandom.hex(4)}#{File.extname(contentInstruction)}"
            filepath2 = "#{nyxNxPodFolderpath}/#{filename2}"
            FileUtils.cp(contentInstruction, filepath2)
            File.open("#{nyxNxPodFolderpath}/manifest.txt", "w") {|f| f.write(filename2)}
        end

        if type == "FSLocation" then
            filename2 = SecureRandom.hex(4)
            filepath2 = "#{nyxNxPodFolderpath}/#{filename2}"
            FileUtils.mkdir(filepath2)
            LucilleCore::copyFileSystemLocation(contentInstruction, filepath2)
            File.open("#{nyxNxPodFolderpath}/manifest.txt", "w") {|f| f.write(filename2)}
        end
    end

    # FileSystemAdapter::setNxPodDescription(uuid, description)
    def self.setNxPodDescription(uuid, description)
        # This updates the database and the nxpod on nxpod folder
        folderpath = FileSystemAdapter::getNxPodFolderpathByUUID(uuid)
        File.open("#{folderpath}/description.txt", "w") {|f| f.write(description)}
    end

    # FileSystemAdapter::getNxPodType(uuid) : Folderpath
    def self.getNxPodType(uuid)
        folderpath = FileSystemAdapter::getNxPodFolderpathByUUID(uuid)
        filepath = "#{folderpath}/type.txt"
        raise "error: 8e0c51fa-89f7-4ef8-a1ef-b9ccf8f0588b ; could not find the type file (#{filepath}) for uuid: #{uuid}" if !File.exist?(filepath)
        IO.read(filepath)
    end

    # FileSystemAdapter::getNxPodContentDataOrNull(uuid)
    def self.getNxPodContentDataOrNull(uuid)
        # This only returns data for "Line", "Url", "FSUniqueString" otherwise raise an error
        folderpath = FileSystemAdapter::getNxPodFolderpathByUUID(uuid)
        type = FileSystemAdapter::getNxPodType(uuid)
        raise "error: 32257b83-4473-494d-9d32-937db29767bf ; trying to extract content data for a non supported type" if !["Line", "Url", "FSUniqueString"].include?(type)
        IO.read("#{folderpath}/manifest.txt")
    end

    # FileSystemAdapter::getNxPodContentFilepathOrNull(uuid)
    def self.getNxPodContentFilepathOrNull(uuid)
        # This only returns data for "Text", "UniqueFileClickable", "FSLocation"
        folderpath = FileSystemAdapter::getNxPodFolderpathByUUID(uuid)
        type = FileSystemAdapter::getNxPodType(uuid)
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

    # FileSystemAdapter::fsckNxPod(uuid)
    def self.fsckNxPod(uuid)
        nxpodFolderpath = FileSystemAdapter::getNxPodFolderpathByUUID(uuid)
        if !File.exists?(nxpodFolderpath) then
            raise "fsck fail: did not find nxpod folderpath for uuid: #{uuid}"
        end
        if !File.exists?("#{nxpodFolderpath}/uuid.txt") then
            raise "fsck fail: did not find uuid.txt for uuid: #{uuid}"
        end
        if uuid != IO.read("#{nxpodFolderpath}/uuid.txt").strip then
            raise "fsck fail: did not validate uuid in uuid.txt for uuid: #{uuid}"
        end
        if !File.exists?("#{nxpodFolderpath}/description.txt") then
            raise "fsck fail: did not find description.txt for uuid: #{uuid}"
        end
        if !File.exists?("#{nxpodFolderpath}/type.txt") then
            raise "fsck fail: did not find type.txt for uuid: #{uuid}"
        end
        type = IO.read("#{nxpodFolderpath}/type.txt")
        if !["Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"].include?(type) then
            raise "fsck fail: non standard type (found '#{type}') for uuid: #{uuid}"
        end
        if ["Line", "Url", "FSUniqueString"].include?(type) then
            if FileSystemAdapter::getNxPodContentDataOrNull(uuid).nil? then
                raise "fsck fail: could not find content data for uuid: #{uuid}"
            end
        end
        if ["Text", "UniqueFileClickable", "FSLocation"].include?(type) then
            if FileSystemAdapter::getNxPodContentFilepathOrNull(uuid).nil? then
                raise "fsck fail: could not find content filepath for uuid: #{uuid}"
            end
        end
    end

    # ----------------------------------------------------------------------------------------

    # FileSystemAdapter::transmute(uuid)
    def self.transmute(uuid)
        raise "Transmutation has not been implemented yet"
    end

    # ----------------------------------------------------------------------------------------

    # FileSystemAdapter::destroyNxPodOnDisk(uuid)
    def self.destroyNxPodOnDisk(uuid)
        folderpath = FileSystemAdapter::getNxPodFolderpathByUUID(uuid)
        raise "error: 40cbbc29-6e16-43d7-98e6-eaec68f762a7 ; could not find folderpath '#{folderpath}' for uuid: #{uuid}" if !File.exists?(folderpath)
        puts "Delete folder '#{folderpath}'"
        LucilleCore::removeFileSystemLocation(folderpath)
    end
end
