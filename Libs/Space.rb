
# encoding: UTF-8

class Space

    # -------------------------------------------------------
    # Config

    # Space::spaceFolderpath()
    def self.spaceFolderpath()
        "/Users/pascal/Galaxy/Documents/NyxSpace"
    end

    # Space::asteroidTypes()
    def self.asteroidTypes()
        ["NxNav", "Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"] 
    end

    # -------------------------------------------------------
    # Ids (eg: 024677747775-07)

    # Space::randomDigit()
    def self.randomDigit()
        (0..9).to_a.sample
    end

    # Space::randomId(length)
    def self.randomId(length)
        (1..length).map{|i| Space::randomDigit() }.join()
    end

    # Space::forgeNewId()
    def self.forgeNewId()
        raise "ed679236-713a-41e9-bed0-b19d4b65986d" if !Space::asteroidTypes()
        "#{Space::randomId(12)}-#{Space::randomId(2)}"
    end

    # Space::ids()
    def self.ids()
        LucilleCore::locationsAtFolder(Space::spaceFolderpath())
            .map{|location| File.basename(location) }
            .select{|s| s[-7, 7] == ".marble" }
            .map{|s| s[0, 15] }
    end

    # Space::issueNewId()
    def self.issueNewId()
        loop {
            id = Space::forgeNewId()
            next if Space::exists?(id)
            return id
        }
    end

    # -------------------------------------------------------
    # Space General

    # Space::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Space::spaceFolderpath())
            .map{|location| File.basename(location)}
            .select{|s| s[-7, 7] == ".marble"}
    end

    # Space::asteroidsIds()
    def self.asteroidsIds()
        Space::filepaths().map{|filepath| File.basename(filepath)[0, 15] }
    end

    # Space::link(id1, id2)
    def self.link(id1, id2)
        return if Space::filepathOrNull(id1).nil?
        return if Space::filepathOrNull(id2).nil?
        Marbles::addSetData(Space::filepathOrNull(id1), "links:b645d07ddd5", id2, id2)
        Marbles::addSetData(Space::filepathOrNull(id2), "links:b645d07ddd5", id1, id1)
    end

    # Space::unlink(id1, id2)
    def self.unlink(id1, id2)
        return if Space::filepathOrNull(id1).nil?
        return if Space::filepathOrNull(id2).nil?
        Marbles::removeSetData(Space::filepathOrNull(id1), "links:b645d07ddd5", id2, id2)
        Marbles::removeSetData(Space::filepathOrNull(id2), "links:b645d07ddd5", id1, id1)
    end

    # Space::interactivelyMakeNewAsteroidOrNull()
    def self.interactivelyMakeNewAsteroidOrNull()
        id = Space::issueNewId()

        filepath = "#{Space::spaceFolderpath()}/#{id}.marble"

        Marbles::issueNewEmptyMarbleFile(filepath)

        Marbles::set(filepath, "uuid", id)
        Marbles::set(filepath, "unixtime", Time.new.to_i)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            Space::destroy(id)
            return nil 
        end
        Marbles::set(filepath, "description", description)

        nxType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"])

        if nxType.nil? then
            Space::destroy(id)
            return nil
        end

        Marbles::set(filepath, "nxType", nxType)

        if nxType == "Line" then
            return id
        end

        if nxType == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            if url == "" then
                Space::destroy(id)
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
                Space::destroy(id)
                return nil
            end
            filepath = "/Users/pascal/Desktop/#{filename}"
            if !File.exists?(filepath) then
                Space::destroy(id)
                return nil
            end
            operator = MarblesElizabeth.new(Space::filepathOrNull(id))
            nhash = AionCore::commitLocationReturnHash(operator, filepath)
            Marbles::set(filepath, "nhash", nhash)
            return id
        end
        if nxType == "FSLocation" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name (on Desktop) (empty to abort): ")
            if locationname == "" then
                Space::destroy(id)
                return nil
            end
            location = "/Users/pascal/Desktop/#{locationname}"
            if !File.exists?(location) then
                Space::destroy(id)
                return nil
            end

            folderpath2 = "#{Space::spaceFolderpath()}/#{id}"

            FileUtils.mkdir(folderpath2) # We always create a folder regardless of whether it was a file or a directory 
            FileUtils.mv(location, folderpath2) # We always move the thing (file or directory) into the folder

            return id
        end
        if nxType == "FSUniqueString" then
            unique = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            if unique == "" then
                Space::destroy(id)
                return nil
            end
            Marbles::set(filepath, "uniquestring", uniquestring)
        end
        nil
    end

    # Space::architect()
    def self.architect()
        filepath = Space::selectOneAsteroidOrNull()
        return filepath if filepath
        Space::interactivelyMakeNewAsteroidOrNull()
    end

    # -------------------------------------------------------
    # Asteroids

    # Space::filepathOrNull(id)
    def self.filepathOrNull(id)
        filepath = "#{Space::spaceFolderpath()}/#{id}.marble"
        return nil if !File.exists?(filepath)
        filepath
    end

    # Space::exists?(id)
    def self.exists?(id)
        File.exists?("#{Space::spaceFolderpath()}/#{id}.marble")
    end

    # Space::destroy(id)
    def self.destroy(id)
        filepath = "#{Space::spaceFolderpath()}/#{id}.marble"
        folderpath = "#{Space::spaceFolderpath()}/#{id}"
        if File.exists?(filepath) then
            LucilleCore::removeFileSystemLocation(filepath)
        end
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
    end

    # Space::description(id)
    def self.description(id)
        filepath = Space::filepathOrNull(id)
        raise "dcfa2f7b-80e0-4930-9b37-9d41e15acd9c" if filepath.nil?
        Marbles::get(filepath, "description")
    end

    # Space::setDescription(id, description)
    def self.setDescription(id, description)
        filepath = Space::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # Space::nxType(id)
    def self.nxType(id)
        filepath = Space::filepathOrNull(id)
        raise "ebde87c8-1fa8-44b6-b56e-0812ca779c0f" if filepath.nil?
        Marbles::get(filepath, "nxType")
    end

    # Space::unixtime(id)
    def self.unixtime(id)
        filepath = Space::filepathOrNull(id)
        raise "60583265-18d3-4ec9-87dc-36c27036630a" if filepath.nil?
        Marbles::get(filepath, "unixtime").to_i
    end

    # Space::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        filepath = Space::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # Space::datetime(id)
    def self.datetime(id)
        Time.at(Space::unixtime(id)).utc.iso8601
    end

    # Space::connected(id)
    def self.connected(id)
        filepath = Space::filepathOrNull(id)
        raise "a6bb1f94-e1c4-439e-9196-03b5742a142c" if filepath.nil?
        Marbles::getSet(filepath, "links:b645d07ddd5")
    end

    # Space::connected2(id)
    def self.connected2(id)
        Space::connected(id)
            .select{|id| Space::exists?(id) }
    end

    # -------------------------------------------------------
    # Asteroid Ops

    # Space::access(id)
    def self.access(id)

        if Space::nxType(id) == "Line" then
            puts "line: #{Space::description(id)}"
            LucilleCore::pressEnterToContinue()
        end

        if Space::nxType(id) == "Url" then
            puts "description: #{Space::description(id)}"
            url = Marbles::get(Space::filepathOrNull(id), "url")
            puts "url: #{url}"
            Utils::openUrl(url)
        end

        if Space::nxType(id) == "Text" then
            text = Marbles::get(Space::filepathOrNull(id), "text")
            puts "text:\n#{text}"
            LucilleCore::pressEnterToContinue()
        end

        if Space::nxType(id) == "UniqueFileClickable" then
            puts "description: #{Space::description(id)}"
            nhash = Marbles::get(Space::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(Space::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
        end

        if Space::nxType(id) == "FSLocation" then
            puts "description: #{Space::description(id)}"
            system("open '#{Space::spaceFolderpath()}/#{id}'")
            LucilleCore::pressEnterToContinue()
        end

        if Space::nxType(id) == "FSUniqueString" then
            puts "description: #{Space::description(id)}"
            uniquestring = Marbles::get(Space::filepathOrNull(id), "uniquestring")
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

    # Space::edit(id)
    def self.edit(id)

        if Space::nxType(id) == "Line" then
            puts "line: #{Space::description(id)}"
            # Update Description
            description = Utils::editTextSynchronously(Space::description(id))
            if description != "" then
                Space::setDescription(id, description)
            end
        end

        if Space::nxType(id) == "Url" then
            puts "description: #{Space::description(id)}"
            url = Marbles::get(Space::filepathOrNull(id), "url")
            puts "url: #{url}"
            url = Utils::editTextSynchronously(url)
            Marbles::set(Space::filepathOrNull(id), "url", url)
        end

        if Space::nxType(id) == "Text" then
            puts "description: #{Space::description(id)}"
            text = Marbles::get(Space::filepathOrNull(id), "text")
            text = Utils::editTextSynchronously(text)
            Marbles::set(Space::filepathOrNull(id), "text", text)
        end

        if Space::nxType(id) == "UniqueFileClickable" then
            puts "description: #{Space::description(id)}"
            nhash = Marbles::get(Space::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(Space::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
            if LucilleCore::askQuestionAnswerAsBoolean("edit file ? : ", false) then
                # Write the line to edit the file.
            end
        end

        if Space::nxType(id) == "FSLocation" then
            puts "description: #{Space::description(id)}"
            system("open '#{Space::spaceFolderpath()}/#{id}'")
            LucilleCore::pressEnterToContinue()
        end

        if Space::nxType(id) == "FSUniqueString" then
            puts "description: #{Space::description(id)}"
            uniquestring = Marbles::get(Space::filepathOrNull(id), "uniquestring")
            uniquestring = Utils::editTextSynchronously(uniquestring)
            Marbles::set(Space::filepathOrNull(id), "uniquestring", uniquestring)
        end
    end

    # Space::landing(id)
    def self.landing(id)

        filepath = Space::filepathOrNull(id)

        loop {
            system("clear")

            return if !Space::exists?(id)

            puts "-- #{Space::nxType(id)} -----------------------------"

            puts "#{Space::description(id).green}"
            puts "(id: #{id}, datetime: #{Space::datetime(id)})"
            puts ""

            mx = LCoreMenuItemsNX1.new()

            Space::connected2(id)
                .sort{|idx1, idx2| Space::unixtime(idx1) <=> Space::unixtime(idx2) }
                .each{|idx|
                    mx.item(Space::description(idx), lambda {
                        Space::landing(idx)
                    })
                }

            puts ""

            mx.item("access".yellow, lambda {
                Space::access(id)
            })
            mx.item("edit".yellow, lambda {
                Space::edit(id)
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(Space::description(id))
                return if description == ""
                Space::setDescription(id, description)
            })

            mx.item("edit datetime".yellow, lambda {
                datetime = Utils::editTextSynchronously(Space::datetime(id))
                return if !Utils::isDateTime_UTC_ISO8601(datetime)
                unixtime = DateTime.parse(datetime).to_time.to_i
                Space::setUnixtime(id, unixtime)
            })

            mx.item("attach".yellow, lambda { 
                idx = Space::architect()
                return if idx.nil?
                Space::link(id, idx)
            })

            mx.item("detach".yellow, lambda {
                idx = LucilleCore::selectEntityFromListOfEntitiesOrNull("Asteroid", Space::connected2(id), lambda{|idx| Space::description(idx) })
                return if idx.nil?
                Space::unlink(id, idx)
            })

            mx.item("relocate (move a selection of connected points somewhere else)".yellow, lambda {
                puts "(1) target selection ; (2) moving points selection"
                id1 = Space::architect()
                return if id1.nil?

                selected, unselected = LucilleCore::selectZeroOrMore("Asteroids", [], Space::connected2(id), lambda{|idx| Space::description(idx) })
                selected.each{|idx|
                    puts "Connecting   : #{Space::description(id1)}, #{Space::description(idx)}"
                    Space::link(id1, idx)
                    puts "Disconnecting: #{Space::description(id)}, #{Space::description(idx)}"
                    Space::unlink(id, idx)
                }
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    code = SecureRandom.hex(2)
                    input = LucilleCore::askQuestionAnswerAsString("Special protocol. Enter this string: '#{code}' : ")
                    return if input != code
                    Space::destroy(id)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Space::fsck(id)
    def self.fsck(id)

        filepath = Space::filepathOrNull(id)

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

        if !["NxNav", "Line", "Url", "Text", "UniqueFileClickable", "FSLocation", "FSUniqueString"].include?(nxType) then
            raise "fsck unsupported nxType for id: #{id} (found: #{nxType})"
        end

        if nxType == "NxNav" then
            # Nothing
        end

        if nxType == "Line" then
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
            operator = MarblesElizabeth.new(Space::filepathOrNull(id))
            status = AionFsck::structureCheckAionHash(operator, nhash)
            if !status then
                raise "fsck fail: Incorrect Aion Structure for nhash: #{nhash} (id: #{id})"
            end
        end

        if nxType == "FSLocation" then
            if !File.exists?("#{Space::spaceFolderpath()}/#{id}") then
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

    # Space::mx19s()
    def self.mx19s()
        Space::ids()
            .map{|id|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{Space::description(id)}",
                    "id"       => id
                }
            }
    end

    # Space::selectOneMx19OrNull()
    def self.selectOneMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Space::mx19s(), lambda{|item| item["announce"] })
    end

    # Space::selectOneAsteroidOrNull()
    def self.selectOneAsteroidOrNull()
        mx19 = Space::selectOneMx19OrNull()
        return if mx19.nil?
        mx19["id"]
    end

    # Space::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            mx19 = Space::selectOneMx19OrNull()
            break if mx19.nil? 
            Space::landing(mx19["id"])
        }
    end
end
