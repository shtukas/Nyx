
# encoding: UTF-8

class Nodes

    # -------------------------------------------------------
    # Config

    # Nodes::nodesFolderpath()
    def self.nodesFolderpath()
        "/Users/pascal/Galaxy/Nyx/Nodes"
    end

    # Nodes::stdFSTrees()
    def self.stdFSTrees()
        "/Users/pascal/Galaxy/Nyx/StdFSTrees"
    end

    # Nodes::networkTypes()
    def self.networkTypes()
        ["NxTag", "Url", "Text", "UniqueFile", "StdFSTree", "FSUniqueString"] 
    end

    # -------------------------------------------------------
    # Ids (eg: 024677747775-07)

    # Nodes::randomDigit()
    def self.randomDigit()
        (0..9).to_a.sample
    end

    # Nodes::randomId(length)
    def self.randomId(length)
        (1..length).map{|i| Nodes::randomDigit() }.join()
    end

    # Nodes::forgeNewId()
    def self.forgeNewId()
        raise "ed679236-713a-41e9-bed0-b19d4b65986d" if !Nodes::networkTypes()
        "#{Nodes::randomId(12)}-#{Nodes::randomId(2)}"
    end

    # Nodes::ids()
    def self.ids()
        LucilleCore::locationsAtFolder(Nodes::nodesFolderpath())
            .map{|location| File.basename(location) }
            .select{|s| s[-7, 7] == ".marble" }
            .map{|s| s[0, 15] }
    end

    # Nodes::issueNewId()
    def self.issueNewId()
        loop {
            id = Nodes::forgeNewId()
            next if Nodes::exists?(id)
            return id
        }
    end

    # -------------------------------------------------------
    # Nodes General

    # Nodes::nodesFilepaths()
    def self.nodesFilepaths()
        LucilleCore::locationsAtFolder(Nodes::nodesFolderpath())
            .map{|location| File.basename(location)}
            .select{|s| s[-7, 7] == ".marble"}
    end

    # Nodes::networkIds()
    def self.networkIds()
        Nodes::nodesFilepaths().map{|filepath| File.basename(filepath)[0, 15] }
    end

    # Nodes::stdFSTreeFolderpath(id)
    def self.stdFSTreeFolderpath(id)
        "#{Nodes::stdFSTrees()}/#{id}"
    end

    # Nodes::link(id1, id2)
    def self.link(id1, id2)
        return if Nodes::filepathOrNull(id1).nil?
        return if Nodes::filepathOrNull(id2).nil?
        Marbles::addSetData(Nodes::filepathOrNull(id1), "links:b645d07ddd5", id2, id2)
        Marbles::addSetData(Nodes::filepathOrNull(id2), "links:b645d07ddd5", id1, id1)
    end

    # Nodes::unlink(id1, id2)
    def self.unlink(id1, id2)
        return if Nodes::filepathOrNull(id1).nil?
        return if Nodes::filepathOrNull(id2).nil?
        Marbles::removeSetData(Nodes::filepathOrNull(id1), "links:b645d07ddd5", id2, id2)
        Marbles::removeSetData(Nodes::filepathOrNull(id2), "links:b645d07ddd5", id1, id1)
    end

    # Nodes::interactivelyMakeNewNodeOrNull()
    def self.interactivelyMakeNewNodeOrNull()
        id = Nodes::issueNewId()

        filepath = "#{Nodes::nodesFolderpath()}/#{id}.marble"

        Marbles::issueNewEmptyMarbleFile(filepath)

        Marbles::set(filepath, "uuid", id)
        Marbles::set(filepath, "unixtime", Time.new.to_i)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            Nodes::destroy(id)
            return nil 
        end
        Marbles::set(filepath, "description", description)

        nxType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["NxTag", "Url", "Text", "UniqueFile", "StdFSTree", "FSUniqueString"])

        if nxType.nil? then
            Nodes::destroy(id)
            return nil
        end

        Marbles::set(filepath, "nxType", nxType)

        if nxType == "NxTag" then
            return id
        end

        if nxType == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            if url == "" then
                Nodes::destroy(id)
                return nil
            end
            Marbles::set(filepath, "url", url)
            return id
        end

        if nxType == "Text" then
            text = Utils::editTextSynchronously("")
            Marbles::set(filepath, "text", text)
            return id
        end
        if nxType == "UniqueFile" then
            filename = LucilleCore::askQuestionAnswerAsString("filename (on Desktop) (empty to abort): ")
            if filename == "" then
                Nodes::destroy(id)
                return nil
            end
            fp1 = "/Users/pascal/Desktop/#{filename}"
            if !File.exists?(fp1) then
                Nodes::destroy(id)
                return nil
            end
            operator = MarblesElizabeth.new(filepath)
            nhash = AionCore::commitLocationReturnHash(operator, fp1)
            Marbles::set(filepath, "nhash", nhash)
            return id
        end
        if nxType == "StdFSTree" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name (on Desktop) (empty to abort): ")
            if locationname == "" then
                Nodes::destroy(id)
                return nil
            end
            location = "/Users/pascal/Desktop/#{locationname}"
            if !File.exists?(location) then
                Nodes::destroy(id)
                return nil
            end

            folderpath2 = Nodes::stdFSTreeFolderpath(id)

            FileUtils.mkdir(folderpath2) # We always create a folder regardless of whether it was a file or a directory 
            FileUtils.mv(location, folderpath2) # We always move the thing (file or directory) into the folder

            return id
        end
        if nxType == "FSUniqueString" then
            unique = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            if unique == "" then
                Nodes::destroy(id)
                return nil
            end
            Marbles::set(filepath, "uniquestring", uniquestring)
        end
        nil
    end

    # Nodes::architect()
    def self.architect()
        filepath = Nodes::selectOneAsteroidOrNull()
        return filepath if filepath
        Nodes::interactivelyMakeNewNodeOrNull()
    end

    # -------------------------------------------------------
    # Asteroids

    # Nodes::filepathOrNull(id)
    def self.filepathOrNull(id)
        filepath = "#{Nodes::nodesFolderpath()}/#{id}.marble"
        return nil if !File.exists?(filepath)
        filepath
    end

    # Nodes::exists?(id)
    def self.exists?(id)
        File.exists?("#{Nodes::nodesFolderpath()}/#{id}.marble")
    end

    # Nodes::destroy(id)
    def self.destroy(id)
        filepath = "#{Nodes::nodesFolderpath()}/#{id}.marble"
        if File.exists?(filepath) then
            LucilleCore::removeFileSystemLocation(filepath)
        end
        folderpath = Nodes::stdFSTreeFolderpath(id)
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
    end

    # Nodes::description(id)
    def self.description(id)
        filepath = Nodes::filepathOrNull(id)
        raise "dcfa2f7b-80e0-4930-9b37-9d41e15acd9c" if filepath.nil?
        Marbles::get(filepath, "description")
    end

    # Nodes::setDescription(id, description)
    def self.setDescription(id, description)
        filepath = Nodes::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # Nodes::nxType(id)
    def self.nxType(id)
        filepath = Nodes::filepathOrNull(id)
        raise "ebde87c8-1fa8-44b6-b56e-0812ca779c0f" if filepath.nil?
        Marbles::get(filepath, "nxType")
    end

    # Nodes::unixtime(id)
    def self.unixtime(id)
        filepath = Nodes::filepathOrNull(id)
        raise "60583265-18d3-4ec9-87dc-36c27036630a" if filepath.nil?
        Marbles::get(filepath, "unixtime").to_i
    end

    # Nodes::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        filepath = Nodes::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # Nodes::datetime(id)
    def self.datetime(id)
        Time.at(Nodes::unixtime(id)).utc.iso8601
    end

    # Nodes::connected(id)
    def self.connected(id)
        filepath = Nodes::filepathOrNull(id)
        raise "a6bb1f94-e1c4-439e-9196-03b5742a142c" if filepath.nil?
        Marbles::getSet(filepath, "links:b645d07ddd5")
    end

    # Nodes::connected2(id)
    def self.connected2(id)
        Nodes::connected(id)
            .select{|id| Nodes::exists?(id) }
    end

    # -------------------------------------------------------
    # Asteroid Ops

    # Nodes::access(id)
    def self.access(id)

        if Nodes::nxType(id) == "NxTag" then
            puts "line: #{Nodes::description(id)}"
            LucilleCore::pressEnterToContinue()
        end

        if Nodes::nxType(id) == "Url" then
            puts "description: #{Nodes::description(id)}"
            url = Marbles::get(Nodes::filepathOrNull(id), "url")
            puts "url: #{url}"
            Utils::openUrl(url)
        end

        if Nodes::nxType(id) == "Text" then
            text = Marbles::get(Nodes::filepathOrNull(id), "text")
            puts "text:\n#{text}"
            LucilleCore::pressEnterToContinue()
        end

        if Nodes::nxType(id) == "UniqueFile" then
            puts "description: #{Nodes::description(id)}"
            nhash = Marbles::get(Nodes::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(Nodes::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
        end

        if Nodes::nxType(id) == "StdFSTree" then
            puts "description: #{Nodes::description(id)}"
            system("open '#{Nodes::stdFSTreeFolderpath(id)}'")
            LucilleCore::pressEnterToContinue()
        end

        if Nodes::nxType(id) == "FSUniqueString" then
            puts "description: #{Nodes::description(id)}"
            uniquestring = Marbles::get(Nodes::filepathOrNull(id), "uniquestring")
            location = `atlas locate '#{uniquestring}'`.strip
            if location == "" then
                puts "Could not locate unique string #{uniquestring}"
                LucilleCore::pressEnterToContinue()
            end
            if File.directory?(location) then
                puts location
                if LucilleCore::askQuestionAnswerAsBoolean("open directory ? : ") then
                    system("open '#{location}'")
                end
            end
            if File.file?(location) then
                puts location
                if LucilleCore::askQuestionAnswerAsBoolean("open file ? : ") then
                    system("open '#{location}'")
                end
            end
        end
    end

    # Nodes::edit(id)
    def self.edit(id)

        if Nodes::nxType(id) == "NxTag" then
            puts "line: #{Nodes::description(id)}"
            # Update Description
            description = Utils::editTextSynchronously(Nodes::description(id))
            if description != "" then
                Nodes::setDescription(id, description)
            end
        end

        if Nodes::nxType(id) == "Url" then
            puts "description: #{Nodes::description(id)}"
            url = Marbles::get(Nodes::filepathOrNull(id), "url")
            puts "url: #{url}"
            url = Utils::editTextSynchronously(url)
            Marbles::set(Nodes::filepathOrNull(id), "url", url)
        end

        if Nodes::nxType(id) == "Text" then
            puts "description: #{Nodes::description(id)}"
            text = Marbles::get(Nodes::filepathOrNull(id), "text")
            text = Utils::editTextSynchronously(text)
            Marbles::set(Nodes::filepathOrNull(id), "text", text)
        end

        if Nodes::nxType(id) == "UniqueFile" then
            puts "description: #{Nodes::description(id)}"
            nhash = Marbles::get(Nodes::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(Nodes::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
            if LucilleCore::askQuestionAnswerAsBoolean("edit file ? : ", false) then
                # Write the line to edit the file.
            end
        end

        if Nodes::nxType(id) == "StdFSTree" then
            puts "description: #{Nodes::description(id)}"
            system("open '#{Nodes::stdFSTreeFolderpath(id)}'")
            LucilleCore::pressEnterToContinue()
        end

        if Nodes::nxType(id) == "FSUniqueString" then
            puts "description: #{Nodes::description(id)}"
            uniquestring = Marbles::get(Nodes::filepathOrNull(id), "uniquestring")
            uniquestring = Utils::editTextSynchronously(uniquestring)
            Marbles::set(Nodes::filepathOrNull(id), "uniquestring", uniquestring)
        end
    end

    # Nodes::landing(id)
    def self.landing(id)

        filepath = Nodes::filepathOrNull(id)

        loop {
            system("clear")

            return if !Nodes::exists?(id)

            puts Nodes::description(id)
            puts "(#{Nodes::nxType(id)}, id: #{id}, datetime: #{Nodes::datetime(id)})"
            puts ""

            mx = LCoreMenuItemsNX1.new()

            Nodes::connected2(id)
                .sort{|idx1, idx2| Nodes::unixtime(idx1) <=> Nodes::unixtime(idx2) }
                .each{|idx|
                    mx.item(Nodes::description(idx), lambda {
                        Nodes::landing(idx)
                    })
                }

            puts ""

            mx.item("access".yellow, lambda {
                Nodes::access(id)
            })
            mx.item("edit".yellow, lambda {
                Nodes::edit(id)
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(Nodes::description(id))
                return if description == ""
                Nodes::setDescription(id, description)
            })

            mx.item("edit datetime".yellow, lambda {
                datetime = Utils::editTextSynchronously(Nodes::datetime(id))
                return if !Utils::isDateTime_UTC_ISO8601(datetime)
                unixtime = DateTime.parse(datetime).to_time.to_i
                Nodes::setUnixtime(id, unixtime)
            })

            mx.item("link".yellow, lambda { 
                idx = Nodes::architect()
                return if idx.nil?
                Nodes::link(id, idx)
            })

            mx.item("unlink".yellow, lambda {
                idx = LucilleCore::selectEntityFromListOfEntitiesOrNull("Asteroid", Nodes::connected2(id), lambda{|idx| Nodes::description(idx) })
                return if idx.nil?
                Nodes::unlink(id, idx)
            })

            mx.item("relocate (move a selection of connected points somewhere else)".yellow, lambda {
                puts "(1) target selection ; (2) moving points selection"
                id1 = Nodes::architect()
                return if id1.nil?

                selected, unselected = LucilleCore::selectZeroOrMore("Asteroids", [], Nodes::connected2(id), lambda{|idx| Nodes::description(idx) })
                selected.each{|idx|
                    puts "Connecting   : #{Nodes::description(id1)}, #{Nodes::description(idx)}"
                    Nodes::link(id1, idx)
                    puts "Disconnecting: #{Nodes::description(id)}, #{Nodes::description(idx)}"
                    Nodes::unlink(id, idx)
                }
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    code = SecureRandom.hex(2)
                    input = LucilleCore::askQuestionAnswerAsString("Special protocol. Enter this string: '#{code}' : ")
                    return if input != code
                    Nodes::destroy(id)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Nodes::fsck(id)
    def self.fsck(id)

        filepath = Nodes::filepathOrNull(id)

        if filepath.nil? then
            raise "fsck fail: did not find marble file for id: #{id}"
        end
        if Marbles::getOrNull(filepath, "uuid").nil? then
            raise "fsck fail: did not find uuid for id: #{id}"
        end
        if id != Marbles::getOrNull(filepath, "uuid") then
            raise "fsck fail: did not validate uuid for id: #{id}"
        end
        if Marbles::getOrNull(filepath, "description").nil?  then
            raise "fsck fail: did not find description for id: #{id}"
        end
        if Marbles::getOrNull(filepath, "nxType").nil? then
            raise "fsck fail: did not find nxType for id: #{id}"
        end

        nxType = Marbles::get(filepath, "nxType")

        if !["NxTag", "Url", "Text", "UniqueFile", "StdFSTree", "FSUniqueString"].include?(nxType) then
            raise "fsck unsupported nxType for id: #{id} (found: #{nxType})"
        end

        if nxType == "NxTag" then
            # Nothing
        end
        
        if nxType == "Url" then
            if Marbles::getOrNull(filepath, "url").nil? then
                raise "fsck fail: no url found for id: #{id}"
            end
        end

        if nxType == "Text" then
            if Marbles::getOrNull(filepath, "text").nil? then
                raise "fsck fail: no text found for id: #{id}"
            end
        end

        if nxType == "UniqueFile" then
            if Marbles::getOrNull(filepath, "nhash").nil? then
                raise "fsck fail: no nhash found for id: #{id}"
            end
            nhash = Marbles::getOrNull(filepath, "nhash")
            operator = MarblesElizabeth.new(Nodes::filepathOrNull(id))
            status = AionFsck::structureCheckAionHash(operator, nhash)
            if !status then
                raise "fsck fail: Incorrect Aion Structure for nhash: #{nhash} (id: #{id})"
            end
        end

        if nxType == "StdFSTree" then
            if !File.exists?("#{Nodes::stdFSTreeFolderpath(id)}") then
                raise "fsck fail: missing folder target for id: #{id}"
            end
        end

        if nxType == "FSUniqueString" then
            if Marbles::getOrNull(filepath, "uniquestring").nil? then
                raise "fsck fail: no uniquestring found for id: #{id}"
            end
        end

    end

    # -------------------------------------------------------
    # Search

    # Nodes::mx19s()
    def self.mx19s()
        Nodes::ids()
            .map{|id|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{Nodes::description(id)}",
                    "id"       => id
                }
            }
    end

    # Nodes::selectOneMx19OrNull()
    def self.selectOneMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Nodes::mx19s(), lambda{|item| item["announce"] })
    end

    # Nodes::selectOneAsteroidOrNull()
    def self.selectOneAsteroidOrNull()
        mx19 = Nodes::selectOneMx19OrNull()
        return if mx19.nil?
        mx19["id"]
    end

    # Nodes::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            mx19 = Nodes::selectOneMx19OrNull()
            break if mx19.nil? 
            Nodes::landing(mx19["id"])
        }
    end
end
