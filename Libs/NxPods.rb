
# encoding: UTF-8

class NxPod

    def initialize(id)
        raise "09fed5b4-d479-4b00-b4fa-1ccceae5c897 ; #{id}" if !Space::idIsUsed(id)
        @id = id
    end

    # -- Nx Common --------------------------------------------------------

    def id()
        @id
    end

    def folderpath()
        "#{Space::spaceFolderPath()}/#{@id}"
    end

    def unixtime()
        IO.read("#{folderpath()}/unixtime.txt").strip.to_i
    end

    def description()
        IO.read("#{folderpath()}/description.txt").strip
    end

    def nxType()
        "NxPod"
    end

    def isStillAlive()
        Space::idIsUsed(id)
    end

    def getConnectedIds()
        filepath = "#{folderpath()}/links.json"
        return [] if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    def addConnectedId(id)
        ids = (getConnectedIds() + [id]).uniq.sort
        File.open("#{folderpath()}/links.json", "w"){|f| f.puts(JSON.pretty_generate(ids)) }
    end

    def removeConnectedId(id)
        ids = getConnectedIds() - [id]
        File.open("#{folderpath()}/links.json", "w"){|f| f.puts(JSON.pretty_generate(ids)) }
    end

    def landing()
        NxPods::landing(self)
    end

    # -- NxPods --------------------------------------------------------

    def contentType()
        IO.read("#{folderpath()}/type.txt").strip
    end
end

class NxPods

    # NxPods::getNxPods()
    def self.getNxPods()
        Space::nxPodIds().map{|id| NxPod.new(id)}
    end

    # NxPods::getNxPodOrNull(id)
    def self.getNxPodOrNull(id)
        raise "5e991b84-6084-438a-b6ad-16ccf2629648 ; #{id}" if id[-2, 2] != "01"
        return nil if !Space::idIsUsed(id)
        NxPod.new(id)
    end

    # NxPods::destroyNxPod(uuid)
    def self.destroyNxPod(uuid)
        puts "NxPod destruction has not been implemented yet"
        exit
    end

    # NxPods::commitAttributeFileContentAtFolder(id, filename, data)
    def self.commitAttributeFileContentAtFolder(id, filename, data)
        folderpath = "#{Space::spaceFolderPath()}/#{id}"
        raise "c2847136-5f61-4dd3-88f8-404608a3bc1d ; #{id}" if !File.exists?(folderpath)
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.write(data) }
    end

    # --------------------------------------------------------------------

    # NxPods::toString(nxpod)
    def self.toString(nxpod)
        map = {
            "Line" => "lne",
            "Url"  => "url",
            "Text" => "txt",
            "UniqueFileClickable" => "clk",
            "FSLocation" => "loc",
            "FSUniqueString" => "ust"
        }
        "[#{map[nxpod.contentType()]}] #{nxpod.description()}"
    end

    # NxPods::interactivelyIssueNewNxPodOrNull()
    def self.interactivelyIssueNewNxPodOrNull()
        id = Space::issueNewId("NxPod")

        NxPods::commitAttributeFileContentAtFolder(id, "uuid.txt", id)
        NxPods::commitAttributeFileContentAtFolder(id, "unixtime.txt", Time.new.to_i)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            Space::destroyFolderIfExists(id)
            return nil 
        end

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line" | "Url" | "Text" | "UniqueFileClickable" | "FSLocation" | "FSUniqueString"])

        if type.nil? then
            Space::destroyFolderIfExists(id)
            return nil
        end

        NxPods::commitAttributeFileContentAtFolder(id, "type.txt", type)

        if type == "Line" then
            NxPods::commitAttributeFileContentAtFolder(id, "manifest.txt", "")
            return NxPod.new(id)
        end

        if type == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            if url == "" then
                Space::destroyFolderIfExists(id)
                return nil
            end
            NxPods::commitAttributeFileContentAtFolder(id, "manifest.txt", url)
            return NxPod.new(id)
        end

        if type == "Text" then
            text = Utils::editTextSynchronously("")
            filename = "#{SecureRandom.hex(4)}.txt"
            File.open("#{Space::spaceFolderPath()}/#{id}/#{filename}", "w") {|f| f.write(text)}
            NxPods::commitAttributeFileContentAtFolder(id, "manifest.txt", filename)
            return NxPod.new(id)
        end
        if type == "UniqueFileClickable" then
            filename = LucilleCore::askQuestionAnswerAsString("filename (on Desktop) (empty to abort): ")
            if filename == "" then
                Space::destroyFolderIfExists(id)
                return nil
            end
            filepath = "/Users/pascal/Desktop/#{filename}"
            if !File.exists?(filepath) then
                Space::destroyFolderIfExists(id)
                return nil
            end
            filename2 = "#{SecureRandom.hex(4)}#{File.extname(filepath)}"
            filepath2 = "#{Space::spaceFolderPath()}/#{id}/#{filename2}"
            FileUtils.cp(filepath, filepath2)
            NxPods::commitAttributeFileContentAtFolder(id, "manifest.txt", filename2)
            return NxPod.new(id)
        end
        if type == "FSLocation" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name (on Desktop) (empty to abort): ")
            if locationname == "" then
                Space::destroyFolderIfExists(id)
                return nil
            end
            location = "/Users/pascal/Desktop/#{locationname}"
            if !File.exists?(filepath) then
                Space::destroyFolderIfExists(id)
                return nil
            end

            foldername2 = SecureRandom.hex(4)
            folderpath2 = "#{Space::spaceFolderPath()}/#{id}/#{foldername2}"
            FileUtils.mkdir(folderpath2) # We always create a folder regardless of whether it was a file or a directory 
            FileUtils.mv(location, folderpath2) # We always move the thing (file or directory) into the folder
            NxPods::commitAttributeFileContentAtFolder(id, "manifest.txt", foldername2)
            return NxPod.new(id)
        end
        if type == "FSUniqueString" then
            raise "FSUniqueString not implemented yet"
        end
        nil
    end

    # NxPods::accessEdit(nxpod)
    def self.accessEdit(nxpod)
        type = nxpod.contentType()

        if type == "Line" then
            puts "line: #{nxpod.description()}"
            if LucilleCore::askQuestionAnswerAsBoolean("edit ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "description.txt", description)

                # Update Manifest
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "manifest.txt", "")
            end
        end

        if type == "Url" then
            puts "description: #{nxpod.description()}"
            url = IO.read("#{nxpod.folderpath()}/manifest.txt").strip
            puts "url: #{url}"
            Utils::openUrl(url)
            if LucilleCore::askQuestionAnswerAsBoolean("edit ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "description.txt", description)

                # Update Manifest
                url = Utils::editTextSynchronously(IO.read("#{nxpod.folderpath()}/manifest.txt"))
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "manifest.txt", url)
            end
        end

        if type == "Text" then
            filename = IO.read("#{nxpod.folderpath()}/manifest.txt")
            system("open '#{nxpod.folderpath()}/#{filename}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit (description) ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "description.txt", description)
            end
        end

        if type == "UniqueFileClickable" then
            puts "description: #{nxpod.description()}"
            filename = IO.read("#{nxpod.folderpath()}/manifest.txt")
            system("open '#{nxpod.folderpath()}/#{filename}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit description ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "description.txt", description)
            end
            if LucilleCore::askQuestionAnswerAsBoolean("edit file ? : ", false) then
                system("open '#{nxpod.folderpath()}'")
            end
        end

        if type == "FSLocation" then
            puts "description: #{nxpod.description()}"
            foldername = IO.read("#{nxpod.folderpath()}/manifest.txt")
            system("open '#{nxpod.folderpath()}/#{foldername}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit description ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "description.txt", description)
            end
        end

        if type == "FSUniqueString" then
            puts "description: #{nxpod.description()}"
            uniquestring = IO.read("#{nxpod.folderpath()}/manifest.txt")
            location = `atlas locate '#{uniquestring}'`
            if location.size > 0 then
                puts location
                LucilleCore::pressEnterToContinue()
            end
            if LucilleCore::askQuestionAnswerAsBoolean("edit ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "description.txt", description)

                # Update Manifest
                uniquestring = Utils::editTextSynchronously(IO.read("#{nxpod.folderpath()}/manifest.txt"))
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "manifest.txt", uniquestring)
            end
        end
    end

    # NxPods::transmute(id)
    def self.transmute()
        puts "NxPod transmute has not been implemented yet"
    end

    # NxPods::landing(nxpod)
    def self.landing(nxpod)

        loop {

            return if !nxpod.isStillAlive()

            puts "-- NxPod -----------------------------"

            puts NxPods::toString(nxpod).green

            puts "id: #{nxpod.id()}".yellow
            puts ""

            mx = LCoreMenuItemsNX1.new()

            mx.item("access (edit)".yellow, lambda {
                NxPods::accessEdit(nxpod)
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(nxpod.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpod.id(), "description.txt", description)
            })

            mx.item("attach".yellow, lambda { 
                puts "Not implemented yet"
            })

            mx.item("detach".yellow, lambda {
                puts "Not implemented yet"
            })

            mx.item("transmute".yellow, lambda {
                NxPods::transmute(nxpod.id())
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NxPods::destroyNxPod(nxpod.id())
                end
            })

            puts ""

            nxnav.getConnectedIds().each{|id|
                nxPoint = Space::idToNxPointOrNull(id)
                mx.item(nxPoint.description(), lambda { 
                    nxPoint.landing()
                })
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # --------------------------------------------------------------------

    # NxPods::mx19s()
    def self.mx19s()
        NxPods::getNxPods()
            .map{|nxpod|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NxPods::toString(nxpod)}",
                    "mx15"     => {
                        "type"    => "nxpod",
                        "payload" => nxpod
                    }
                }
            }
    end

    # --------------------------------------------------------------------

    # NxPods::fsckNxPod(id)
    def self.fsckNxPod(id)
        raise "3c517e92-09a1-4f6b-92a3-063a68fbbbfe ; #{id}" if id[-2, 2] != "01"
        folderpath = "#{Space::spaceFolderPath()}/#{id}"
        if !File.exists?(folderpath) then
            raise "fsck fail: did not find nxpod folderpath for id: #{id}"
        end
        if !File.exists?("#{folderpath}/uuid.txt") then
            raise "fsck fail: did not find file uuid.txt for id: #{id}"
        end
        if id != IO.read("#{folderpath}/uuid.txt").strip then
            raise "fsck fail: did not validate uuid in uuid.txt for id: #{id}"
        end
        if !File.exists?("#{folderpath}/description.txt") then
            raise "fsck fail: did not find file description.txt for id: #{id}"
        end
        if !File.exists?("#{folderpath}/type.txt") then
            raise "fsck fail: did not find file type.txt for id: #{id}"
        end
        if !File.exists?("#{folderpath}/manifest.txt") then
            raise "fsck fail: did not find file manifest.txt for id: #{id}"
        end
        contentType = IO.read("#{folderpath}/type.txt")
        if !["Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"].include?(contentType) then
            raise "fsck fail: non standard type (found '#{contentType}') for id: #{id}"
        end
        if ["Line"].include?(contentType) then
            # Nothing
        end
        if ["Url", "FSUniqueString"].include?(contentType) then
            if IO.read("#{folderpath}/manifest.txt").strip.size == 0 then
                raise "fsck fail: empty manifest file for id: #{id}"
            end
        end
        if ["Text", "UniqueFileClickable", "FSLocation"].include?(contentType) then
            if IO.read("#{folderpath}/manifest.txt").strip.size == 0 then
                raise "fsck fail: empty manifest file for id: #{id}"
            end
            filename = IO.read("#{folderpath}/manifest.txt")
            if !File.exists?("#{folderpath}/#{filename}") then
                raise "fsck fail: missing manifest target for id: #{id}"
            end
        end
    end
end
