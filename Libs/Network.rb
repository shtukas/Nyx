
# encoding: UTF-8

class Network

    # -------------------------------------------------------
    # Config

    # Network::folderpath()
    def self.folderpath()
        "/Users/pascal/Galaxy/Nyx"
    end

    # Network::networkTypes()
    def self.networkTypes()
        ["NxTag", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"] 
    end

    # -------------------------------------------------------
    # Ids (eg: 024677747775-07)

    # Network::randomDigit()
    def self.randomDigit()
        (0..9).to_a.sample
    end

    # Network::randomId(length)
    def self.randomId(length)
        (1..length).map{|i| Network::randomDigit() }.join()
    end

    # Network::forgeNewId()
    def self.forgeNewId()
        raise "ed679236-713a-41e9-bed0-b19d4b65986d" if !Network::networkTypes()
        "#{Network::randomId(12)}-#{Network::randomId(2)}"
    end

    # Network::ids()
    def self.ids()
        LucilleCore::locationsAtFolder(Network::folderpath())
            .map{|location| File.basename(location) }
            .select{|s| s[-7, 7] == ".marble" }
            .map{|s| s[0, 15] }
    end

    # Network::issueNewId()
    def self.issueNewId()
        loop {
            id = Network::forgeNewId()
            next if Network::exists?(id)
            return id
        }
    end

    # -------------------------------------------------------
    # Network General

    # Network::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Network::folderpath())
            .map{|location| File.basename(location)}
            .select{|s| s[-7, 7] == ".marble"}
    end

    # Network::networkIds()
    def self.networkIds()
        Network::filepaths().map{|filepath| File.basename(filepath)[0, 15] }
    end

    # Network::link(id1, id2)
    def self.link(id1, id2)
        return if Network::filepathOrNull(id1).nil?
        return if Network::filepathOrNull(id2).nil?
        Marbles::addSetData(Network::filepathOrNull(id1), "links:b645d07ddd5", id2, id2)
        Marbles::addSetData(Network::filepathOrNull(id2), "links:b645d07ddd5", id1, id1)
    end

    # Network::unlink(id1, id2)
    def self.unlink(id1, id2)
        return if Network::filepathOrNull(id1).nil?
        return if Network::filepathOrNull(id2).nil?
        Marbles::removeSetData(Network::filepathOrNull(id1), "links:b645d07ddd5", id2, id2)
        Marbles::removeSetData(Network::filepathOrNull(id2), "links:b645d07ddd5", id1, id1)
    end

    # Network::interactivelyMakeNewNodeOrNull()
    def self.interactivelyMakeNewNodeOrNull()
        id = Network::issueNewId()

        filepath = "#{Network::folderpath()}/#{id}.marble"

        Marbles::issueNewEmptyMarbleFile(filepath)

        Marbles::set(filepath, "uuid", id)
        Marbles::set(filepath, "unixtime", Time.new.to_i)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            Network::destroy(id)
            return nil 
        end
        Marbles::set(filepath, "description", description)

        nxType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["NxTag", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"])

        if nxType.nil? then
            Network::destroy(id)
            return nil
        end

        Marbles::set(filepath, "nxType", nxType)

        if nxType == "NxTag" then
            return id
        end

        if nxType == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            if url == "" then
                Network::destroy(id)
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
        if nxType == "UniqueFileClickable" then
            filename = LucilleCore::askQuestionAnswerAsString("filename (on Desktop) (empty to abort): ")
            if filename == "" then
                Network::destroy(id)
                return nil
            end
            fp1 = "/Users/pascal/Desktop/#{filename}"
            if !File.exists?(fp1) then
                Network::destroy(id)
                return nil
            end
            operator = MarblesElizabeth.new(filepath)
            nhash = AionCore::commitLocationReturnHash(operator, fp1)
            Marbles::set(filepath, "nhash", nhash)
            return id
        end
        if nxType == "FSLocation" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name (on Desktop) (empty to abort): ")
            if locationname == "" then
                Network::destroy(id)
                return nil
            end
            location = "/Users/pascal/Desktop/#{locationname}"
            if !File.exists?(location) then
                Network::destroy(id)
                return nil
            end

            folderpath2 = "#{Network::folderpath()}/#{id}"

            FileUtils.mkdir(folderpath2) # We always create a folder regardless of whether it was a file or a directory 
            FileUtils.mv(location, folderpath2) # We always move the thing (file or directory) into the folder

            return id
        end
        if nxType == "FSUniqueString" then
            unique = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            if unique == "" then
                Network::destroy(id)
                return nil
            end
            Marbles::set(filepath, "uniquestring", uniquestring)
        end
        nil
    end

    # Network::architect()
    def self.architect()
        filepath = Network::selectOneAsteroidOrNull()
        return filepath if filepath
        Network::interactivelyMakeNewNodeOrNull()
    end

    # -------------------------------------------------------
    # Asteroids

    # Network::filepathOrNull(id)
    def self.filepathOrNull(id)
        filepath = "#{Network::folderpath()}/#{id}.marble"
        return nil if !File.exists?(filepath)
        filepath
    end

    # Network::exists?(id)
    def self.exists?(id)
        File.exists?("#{Network::folderpath()}/#{id}.marble")
    end

    # Network::destroy(id)
    def self.destroy(id)
        filepath = "#{Network::folderpath()}/#{id}.marble"
        folderpath = "#{Network::folderpath()}/#{id}"
        if File.exists?(filepath) then
            LucilleCore::removeFileSystemLocation(filepath)
        end
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
    end

    # Network::description(id)
    def self.description(id)
        filepath = Network::filepathOrNull(id)
        raise "dcfa2f7b-80e0-4930-9b37-9d41e15acd9c" if filepath.nil?
        Marbles::get(filepath, "description")
    end

    # Network::setDescription(id, description)
    def self.setDescription(id, description)
        filepath = Network::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # Network::nxType(id)
    def self.nxType(id)
        filepath = Network::filepathOrNull(id)
        raise "ebde87c8-1fa8-44b6-b56e-0812ca779c0f" if filepath.nil?
        Marbles::get(filepath, "nxType")
    end

    # Network::unixtime(id)
    def self.unixtime(id)
        filepath = Network::filepathOrNull(id)
        raise "60583265-18d3-4ec9-87dc-36c27036630a" if filepath.nil?
        Marbles::get(filepath, "unixtime").to_i
    end

    # Network::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        filepath = Network::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # Network::datetime(id)
    def self.datetime(id)
        Time.at(Network::unixtime(id)).utc.iso8601
    end

    # Network::connected(id)
    def self.connected(id)
        filepath = Network::filepathOrNull(id)
        raise "a6bb1f94-e1c4-439e-9196-03b5742a142c" if filepath.nil?
        Marbles::getSet(filepath, "links:b645d07ddd5")
    end

    # Network::connected2(id)
    def self.connected2(id)
        Network::connected(id)
            .select{|id| Network::exists?(id) }
    end

    # -------------------------------------------------------
    # Asteroid Ops

    # Network::access(id)
    def self.access(id)

        if Network::nxType(id) == "NxTag" then
            puts "line: #{Network::description(id)}"
            LucilleCore::pressEnterToContinue()
        end

        if Network::nxType(id) == "Url" then
            puts "description: #{Network::description(id)}"
            url = Marbles::get(Network::filepathOrNull(id), "url")
            puts "url: #{url}"
            Utils::openUrl(url)
        end

        if Network::nxType(id) == "Text" then
            text = Marbles::get(Network::filepathOrNull(id), "text")
            puts "text:\n#{text}"
            LucilleCore::pressEnterToContinue()
        end

        if Network::nxType(id) == "UniqueFileClickable" then
            puts "description: #{Network::description(id)}"
            nhash = Marbles::get(Network::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(Network::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
        end

        if Network::nxType(id) == "FSLocation" then
            puts "description: #{Network::description(id)}"
            system("open '#{Network::folderpath()}/#{id}'")
            LucilleCore::pressEnterToContinue()
        end

        if Network::nxType(id) == "FSUniqueString" then
            puts "description: #{Network::description(id)}"
            uniquestring = Marbles::get(Network::filepathOrNull(id), "uniquestring")
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

    # Network::edit(id)
    def self.edit(id)

        if Network::nxType(id) == "NxTag" then
            puts "line: #{Network::description(id)}"
            # Update Description
            description = Utils::editTextSynchronously(Network::description(id))
            if description != "" then
                Network::setDescription(id, description)
            end
        end

        if Network::nxType(id) == "Url" then
            puts "description: #{Network::description(id)}"
            url = Marbles::get(Network::filepathOrNull(id), "url")
            puts "url: #{url}"
            url = Utils::editTextSynchronously(url)
            Marbles::set(Network::filepathOrNull(id), "url", url)
        end

        if Network::nxType(id) == "Text" then
            puts "description: #{Network::description(id)}"
            text = Marbles::get(Network::filepathOrNull(id), "text")
            text = Utils::editTextSynchronously(text)
            Marbles::set(Network::filepathOrNull(id), "text", text)
        end

        if Network::nxType(id) == "UniqueFileClickable" then
            puts "description: #{Network::description(id)}"
            nhash = Marbles::get(Network::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(Network::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
            if LucilleCore::askQuestionAnswerAsBoolean("edit file ? : ", false) then
                # Write the line to edit the file.
            end
        end

        if Network::nxType(id) == "FSLocation" then
            puts "description: #{Network::description(id)}"
            system("open '#{Network::folderpath()}/#{id}'")
            LucilleCore::pressEnterToContinue()
        end

        if Network::nxType(id) == "FSUniqueString" then
            puts "description: #{Network::description(id)}"
            uniquestring = Marbles::get(Network::filepathOrNull(id), "uniquestring")
            uniquestring = Utils::editTextSynchronously(uniquestring)
            Marbles::set(Network::filepathOrNull(id), "uniquestring", uniquestring)
        end
    end

    # Network::landing(id)
    def self.landing(id)

        filepath = Network::filepathOrNull(id)

        loop {
            system("clear")

            return if !Network::exists?(id)

            puts Network::description(id)
            puts "(#{Network::nxType(id)}, id: #{id}, datetime: #{Network::datetime(id)})"
            puts ""

            mx = LCoreMenuItemsNX1.new()

            Network::connected2(id)
                .sort{|idx1, idx2| Network::unixtime(idx1) <=> Network::unixtime(idx2) }
                .each{|idx|
                    mx.item(Network::description(idx), lambda {
                        Network::landing(idx)
                    })
                }

            puts ""

            mx.item("access".yellow, lambda {
                Network::access(id)
            })
            mx.item("edit".yellow, lambda {
                Network::edit(id)
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(Network::description(id))
                return if description == ""
                Network::setDescription(id, description)
            })

            mx.item("edit datetime".yellow, lambda {
                datetime = Utils::editTextSynchronously(Network::datetime(id))
                return if !Utils::isDateTime_UTC_ISO8601(datetime)
                unixtime = DateTime.parse(datetime).to_time.to_i
                Network::setUnixtime(id, unixtime)
            })

            mx.item("link".yellow, lambda { 
                idx = Network::architect()
                return if idx.nil?
                Network::link(id, idx)
            })

            mx.item("unlink".yellow, lambda {
                idx = LucilleCore::selectEntityFromListOfEntitiesOrNull("Asteroid", Network::connected2(id), lambda{|idx| Network::description(idx) })
                return if idx.nil?
                Network::unlink(id, idx)
            })

            mx.item("relocate (move a selection of connected points somewhere else)".yellow, lambda {
                puts "(1) target selection ; (2) moving points selection"
                id1 = Network::architect()
                return if id1.nil?

                selected, unselected = LucilleCore::selectZeroOrMore("Asteroids", [], Network::connected2(id), lambda{|idx| Network::description(idx) })
                selected.each{|idx|
                    puts "Connecting   : #{Network::description(id1)}, #{Network::description(idx)}"
                    Network::link(id1, idx)
                    puts "Disconnecting: #{Network::description(id)}, #{Network::description(idx)}"
                    Network::unlink(id, idx)
                }
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    code = SecureRandom.hex(2)
                    input = LucilleCore::askQuestionAnswerAsString("Special protocol. Enter this string: '#{code}' : ")
                    return if input != code
                    Network::destroy(id)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Network::fsck(id)
    def self.fsck(id)

        filepath = Network::filepathOrNull(id)

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

        if !["NxTag", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"].include?(nxType) then
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

        if nxType == "UniqueFileClickable" then
            if Marbles::getOrNull(filepath, "nhash").nil? then
                raise "fsck fail: no nhash found for id: #{id}"
            end
            nhash = Marbles::getOrNull(filepath, "nhash")
            operator = MarblesElizabeth.new(Network::filepathOrNull(id))
            status = AionFsck::structureCheckAionHash(operator, nhash)
            if !status then
                raise "fsck fail: Incorrect Aion Structure for nhash: #{nhash} (id: #{id})"
            end
        end

        if nxType == "FSLocation" then
            if !File.exists?("#{Network::folderpath()}/#{id}") then
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

    # Network::mx19s()
    def self.mx19s()
        Network::ids()
            .map{|id|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{Network::description(id)}",
                    "id"       => id
                }
            }
    end

    # Network::selectOneMx19OrNull()
    def self.selectOneMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Network::mx19s(), lambda{|item| item["announce"] })
    end

    # Network::selectOneAsteroidOrNull()
    def self.selectOneAsteroidOrNull()
        mx19 = Network::selectOneMx19OrNull()
        return if mx19.nil?
        mx19["id"]
    end

    # Network::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            mx19 = Network::selectOneMx19OrNull()
            break if mx19.nil? 
            Network::landing(mx19["id"])
        }
    end
end
