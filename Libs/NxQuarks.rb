# encoding: UTF-8

class NxQuarks

    # -------------------------------------------------------
    # Config

    # NxQuarks::nxQuarkFolderpath()
    def self.nxQuarkFolderpath()
        "#{Config::nyxFolderPath()}/NxQuarks"
    end

    # NxQuarks::nxQuarkTypes()
    def self.nxQuarkTypes()
        ["NxTag", "Url", "Text", "AionPoint", "FSUniqueString", "NxSmartDirectory"] 
    end

    # -------------------------------------------------------
    # Ids (eg: 024677747775-07)

    # NxQuarks::randomDigit()
    def self.randomDigit()
        (0..9).to_a.sample
    end

    # NxQuarks::randomId(length)
    def self.randomId(length)
        (1..length).map{|i| NxQuarks::randomDigit() }.join()
    end

    # NxQuarks::forgeNewId()
    def self.forgeNewId()
        raise "ed679236-713a-41e9-bed0-b19d4b65986d" if !NxQuarks::nxQuarkTypes()
        "#{NxQuarks::randomId(12)}-#{NxQuarks::randomId(2)}"
    end

    # NxQuarks::ids()
    def self.ids()
        LucilleCore::locationsAtFolder(NxQuarks::nxQuarkFolderpath())
            .map{|location| File.basename(location) }
            .select{|s| s[-7, 7] == ".marble" }
            .map{|s| s[0, 15] }
    end

    # NxQuarks::issueNewId()
    def self.issueNewId()
        loop {
            id = NxQuarks::forgeNewId()
            next if NxQuarks::exists?(id)
            return id
        }
    end

    # -------------------------------------------------------
    # NxQuarks General

    # NxQuarks::nxQuarksFilepaths()
    def self.nxQuarksFilepaths()
        LucilleCore::locationsAtFolder(NxQuarks::nxQuarkFolderpath())
            .map{|location| File.basename(location)}
            .select{|s| s[-7, 7] == ".marble"}
    end

    # NxQuarks::networkIds()
    def self.networkIds()
        NxQuarks::nxQuarksFilepaths().map{|filepath| File.basename(filepath)[0, 15] }
    end

    # NxQuarks::makeNewFSUniqueStringNxQuark(description, uniquestring)
    def self.makeNewFSUniqueStringNxQuark(description, uniquestring)
        id = NxQuarks::issueNewId()
        filepath = "#{NxQuarks::nxQuarkFolderpath()}/#{id}.marble"
        Marbles::issueNewEmptyMarbleFile(filepath)
        Marbles::set(filepath, "uuid", id)
        Marbles::set(filepath, "unixtime", Time.new.to_i)
        Marbles::set(filepath, "description", description)
        Marbles::set(filepath, "nxType", "FSUniqueString")
        Marbles::set(filepath, "uniquestring", uniquestring)
        id
    end

    # NxQuarks::interactivelyMakeNewNxQuarkReturnIdOrNull()
    def self.interactivelyMakeNewNxQuarkReturnIdOrNull()
        id = NxQuarks::issueNewId()

        filepath = "#{NxQuarks::nxQuarkFolderpath()}/#{id}.marble"

        Marbles::issueNewEmptyMarbleFile(filepath)

        Marbles::set(filepath, "uuid", id)
        Marbles::set(filepath, "unixtime", Time.new.to_i)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            NxQuarks::destroy(id)
            return nil 
        end
        Marbles::set(filepath, "description", description)

        nxType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["NxTag", "Url", "Text", "AionPoint", "FSUniqueString", "NxSmartDirectory"])

        if nxType.nil? then
            NxQuarks::destroy(id)
            return nil
        end

        Marbles::set(filepath, "nxType", nxType)

        if nxType == "NxTag" then
            return id
        end

        if nxType == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            if url == "" then
                NxQuarks::destroy(id)
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
        if nxType == "AionPoint" then
            filename = LucilleCore::askQuestionAnswerAsString("filename (on Desktop) (empty to abort): ")
            if filename == "" then
                NxQuarks::destroy(id)
                return nil
            end
            fp1 = "/Users/pascal/Desktop/#{filename}"
            if !File.exists?(fp1) then
                NxQuarks::destroy(id)
                return nil
            end
            operator = MarblesElizabeth.new(filepath)
            nhash = AionCore::commitLocationReturnHash(operator, fp1)
            Marbles::set(filepath, "nhash", nhash)
            return id
        end
        if nxType == "FSUniqueString" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            if uniquestring == "" then
                NxQuarks::destroy(id)
                return nil
            end
            Marbles::set(filepath, "uniquestring", uniquestring)
        end

        if nxType == "NxSmartDirectory" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            if uniquestring == "" then
                NxQuarks::destroy(id)
                return nil
            end
            Marbles::set(filepath, "uniquestring", uniquestring) 
        end

        nil
    end

    # NxQuarks::architectId()
    def self.architectId()
        id = NxQuarks::selectOneNxQuarkIdOrNull()
        return id if id
        NxQuarks::interactivelyMakeNewNxQuarkReturnIdOrNull()
    end

    # -------------------------------------------------------
    # NxQuarks Instrospection

    # NxQuarks::filepathOrNull(id)
    def self.filepathOrNull(id)
        filepath = "#{NxQuarks::nxQuarkFolderpath()}/#{id}.marble"
        return nil if !File.exists?(filepath)
        filepath
    end

    # NxQuarks::exists?(id)
    def self.exists?(id)
        File.exists?("#{NxQuarks::nxQuarkFolderpath()}/#{id}.marble")
    end

    # NxQuarks::destroy(id)
    def self.destroy(id)
        filepath = "#{NxQuarks::nxQuarkFolderpath()}/#{id}.marble"
        if File.exists?(filepath) then
            LucilleCore::removeFileSystemLocation(filepath)
        end
    end

    # NxQuarks::description(id)
    def self.description(id)
        filepath = NxQuarks::filepathOrNull(id)
        raise "dcfa2f7b-80e0-4930-9b37-9d41e15acd9c" if filepath.nil?
        Marbles::get(filepath, "description")
    end

    # NxQuarks::nxType(id)
    def self.nxType(id)
        filepath = NxQuarks::filepathOrNull(id)
        raise "ebde87c8-1fa8-44b6-b56e-0812ca779c0f" if filepath.nil?
        Marbles::get(filepath, "nxType")
    end

    # NxQuarks::unixtime(id)
    def self.unixtime(id)
        filepath = NxQuarks::filepathOrNull(id)
        raise "60583265-18d3-4ec9-87dc-36c27036630a" if filepath.nil?
        Marbles::get(filepath, "unixtime").to_i
    end

    # NxQuarks::datetime(id)
    def self.datetime(id)
        Time.at(NxQuarks::unixtime(id)).utc.iso8601
    end

    # NxQuarks::toString(id)
    def self.toString(id)
        type = NxQuarks::nxType(id)
        padding = NxQuarks::nxQuarkTypes().map{|t| t.size}.max
        "[#{type.ljust(padding)}] #{NxQuarks::description(id)}"
    end

    # -------------------------------------------------------
    # NxQuarks Metadata update

    # NxQuarks::setDescription(id, description)
    def self.setDescription(id, description)
        filepath = NxQuarks::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # NxQuarks::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        filepath = NxQuarks::filepathOrNull(id)
        raise "e61c8efd-41a1-4c8e-b981-740f2f80db95" if filepath.nil?
        Marbles::set(filepath, "description", description)
    end

    # -------------------------------------------------------
    # NxQuarks Notes

    # NxQuarks::interactivelyIssueNoteOrNothing(id)
    def self.interactivelyIssueNoteOrNothing(id)
        filepath = NxQuarks::filepathOrNull(id)
        return if filepath.nil?
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", ["line", "url", "aion-point"])
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line (empty for abort): ")
            return if line == ""
            note = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "type"        => "line",
                "description" => line
            }
        end
        if type == "url" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
            return if description == ""
            url = LucilleCore::askQuestionAnswerAsString("url (empty for abort): ")
            return if url == ""
            note = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "type"        => "url",
                "description" => description,
                "data"        => url
            }
        end
        if type == "aion-point" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
            return if description == ""
            location = LucilleCore::askQuestionAnswerAsString("location on desktop (empty for abort): ")
            return if location == ""
            operator = MarblesElizabeth.new(filepath)
            nhash = AionCore::commitLocationReturnHash(operator, location)
            note = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "type"        => "url",
                "description" => description,
                "data"        => nhash
            }
        end
        Marbles::addSetData(filepath, "notes:d39ca9d6644694abc4235e105a64a59b", note["uuid"], JSON.generate(note))
    end

    # NxQuarks::notes(id)
    def self.notes(id)
        filepath = NxQuarks::filepathOrNull(id)
        raise "78b404cf-d825-4557-afd1-3b699dbe7a70" if filepath.nil?
        Marbles::getSet(filepath, "notes:d39ca9d6644694abc4235e105a64a59b").map{|note| JSON.parse(note) }
    end

    # NxQuarks::nxQuarksToString(note)
    def self.nxQuarksToString(note)
        note.to_s
    end

    # NxQuarks::accessNote(note)
    def self.accessNote(note)
        puts note.to_s
        LucilleCore::pressEnterToContinue()
    end

    # -------------------------------------------------------
    # NxQuarks Ops

    # NxQuarks::access(id)
    def self.access(id)

        accessUniqueString = lambda {|uniquestring|
            location = Utils::locationByUniqueStringOrNull(uniquestring)
            if location.nil? then
                puts "Could not locate unique string #{uniquestring}"
                LucilleCore::pressEnterToContinue()
                return
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
        }

        if NxQuarks::nxType(id) == "NxTag" then
            puts "line: #{NxQuarks::description(id)}"
            LucilleCore::pressEnterToContinue()
        end

        if NxQuarks::nxType(id) == "Url" then
            puts "description: #{NxQuarks::description(id)}"
            url = Marbles::get(NxQuarks::filepathOrNull(id), "url")
            puts "url: #{url}"
            Utils::openUrl(url)
        end

        if NxQuarks::nxType(id) == "Text" then
            text = Marbles::get(NxQuarks::filepathOrNull(id), "text")
            puts "text:\n#{text}"
            LucilleCore::pressEnterToContinue()
        end

        if NxQuarks::nxType(id) == "AionPoint" then
            puts "description: #{NxQuarks::description(id)}"
            nhash = Marbles::get(NxQuarks::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(NxQuarks::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
        end

        if NxQuarks::nxType(id) == "FSUniqueString" then
            puts "description: #{NxQuarks::description(id)}"
            uniquestring = Marbles::get(NxQuarks::filepathOrNull(id), "uniquestring")
            accessUniqueString.call(uniquestring)
        end

        if NxQuarks::nxType(id) == "NxSmartDirectory" then
            puts "description: #{NxQuarks::description(id)}"
            uniquestring = Marbles::get(NxQuarks::filepathOrNull(id), "uniquestring")
            accessUniqueString.call(uniquestring)
        end
    end

    # NxQuarks::edit(id)
    def self.edit(id)

        if NxQuarks::nxType(id) == "NxTag" then
            puts "line: #{NxQuarks::description(id)}"
            # Update Description
            description = Utils::editTextSynchronously(NxQuarks::description(id))
            if description != "" then
                NxQuarks::setDescription(id, description)
            end
        end

        if NxQuarks::nxType(id) == "Url" then
            puts "description: #{NxQuarks::description(id)}"
            url = Marbles::get(NxQuarks::filepathOrNull(id), "url")
            puts "url: #{url}"
            url = Utils::editTextSynchronously(url)
            Marbles::set(NxQuarks::filepathOrNull(id), "url", url)
        end

        if NxQuarks::nxType(id) == "Text" then
            puts "description: #{NxQuarks::description(id)}"
            text = Marbles::get(NxQuarks::filepathOrNull(id), "text")
            text = Utils::editTextSynchronously(text)
            Marbles::set(NxQuarks::filepathOrNull(id), "text", text)
        end

        if NxQuarks::nxType(id) == "AionPoint" then
            puts "description: #{NxQuarks::description(id)}"
            nhash = Marbles::get(NxQuarks::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(NxQuarks::filepathOrNull(id))
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")
            # Write the line to open the file.
            LucilleCore::pressEnterToContinue()
            if LucilleCore::askQuestionAnswerAsBoolean("edit file ? : ", false) then
                # Write the line to edit the file.
            end
        end

        if NxQuarks::nxType(id) == "FSUniqueString" then
            puts "description: #{NxQuarks::description(id)}"
            uniquestring = Marbles::get(NxQuarks::filepathOrNull(id), "uniquestring")
            uniquestring = Utils::editTextSynchronously(uniquestring)
            Marbles::set(NxQuarks::filepathOrNull(id), "uniquestring", uniquestring)
        end

        if NxQuarks::nxType(id) == "NxSmartDirectory" then
            puts "description: #{NxQuarks::description(id)}"
            uniquestring = Marbles::get(NxQuarks::filepathOrNull(id), "uniquestring")
            uniquestring = Utils::editTextSynchronously(uniquestring)
            Marbles::set(NxQuarks::filepathOrNull(id), "uniquestring", uniquestring)
        end
    end

    # NxQuarks::transmuteOrNothing(id, targetType)
    def self.transmuteOrNothing(id, targetType)
        type1 = NxQuarks::nxType(id)

        if type1 == "NxTag" and targetType == "NxSmartDirectory" then
            puts "NxTag to NxSmartDirectory."
            puts "I need to transform the tag into a uniquestring (root of the NxSmartDirectory)"
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return if uniquestring == ""
            filepath = NxQuarks::filepathOrNull(id)
            return if filepath.nil?
            Marbles::set(filepath, "nxType", "NxSmartDirectory")
            Marbles::set(filepath, "uniquestring", uniquestring) 
            return
        end

        if type1 == "AionPoint" and targetType == "FSUniqueString" then
            puts "AionPoint to FSUniqueString"

            filepath = NxQuarks::filepathOrNull(id)

            puts "First, let's make sure the data is exported"
            nhash = Marbles::get(NxQuarks::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(filepath)
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")

            uniquestring = SecureRandom.hex(6)
            puts "AionPoint has been exported on the Desktop. Please move the folder and give it the uniquename: [#{uniquestring}]"
            LucilleCore::pressEnterToContinue()

            puts "Now transforming the AionPoint into a FSUniqueString"

            Marbles::set(filepath, "uniquestring", uniquestring) 
            Marbles::set(filepath, "nxType", "FSUniqueString")

            puts "Running garbage collection"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _elizabeth_", []
            db.execute "vacuum", []
            db.close

            return
        end

        if type1 == "AionPoint" and targetType == "NxSmartDirectory" then
            puts "AionPoint to NxSmartDirectory."

            filepath = NxQuarks::filepathOrNull(id)

            puts "First, let's make sure the data is exported"
            nhash = Marbles::get(NxQuarks::filepathOrNull(id), "nhash")
            operator = MarblesElizabeth.new(filepath)
            AionCore::exportHashAtFolder(operator, nhash, "/Users/pascal/Desktop")

            uniquestring = SecureRandom.hex(6)
            puts "AionPoint has been exported on the Desktop. Please move the folder and give it the uniquename: [#{uniquestring}]"
            LucilleCore::pressEnterToContinue()

            puts "Now transforming the AionPoint into a NxSmartDirectory"

            Marbles::set(filepath, "uniquestring", uniquestring) 
            Marbles::set(filepath, "nxType", "NxSmartDirectory")

            puts "Running garbage collection"
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _elizabeth_", []
            db.execute "vacuum", []
            db.close

            return
        end

        puts "I do not know how to transmute #{type1} into #{targetType}"
        LucilleCore::pressEnterToContinue()
    end

    # NxQuarks::landing(id)
    def self.landing(id)

        filepath = NxQuarks::filepathOrNull(id)

        if NxQuarks::nxType(id) == "NxSmartDirectory" then
            NxSmartDirectory::smartDirectorySync(id, filepath)
        end

        loop {
            system("clear")

            return if !NxQuarks::exists?(id)

            # If I land on a smart directory, then I need to make sure that all the elements in the folder are children of the quark.

            puts NxQuarks::description(id)
            puts "#{NxQuarks::nxType(id)}, id: #{id}, datetime: #{NxQuarks::datetime(id)}"
            if NxQuarks::nxType(id) == "Url" then
                puts "url: #{Marbles::get(NxQuarks::filepathOrNull(id), "url")}"
            end
            if ["FSUniqueString", "NxSmartDirectory"].include?(NxQuarks::nxType(id)) then
                puts "uniquestring: #{Marbles::get(filepath, "uniquestring")}"
            end

            mx = LCoreMenuItemsNX1.new()

            NxQuarks::notes(id).each{|note|
                mx.item("note: #{NxQuarks::nxQuarksToString(note)}", lambda {
                    NxQuarks::accessNote(note)
                })
            }

            puts ""

            Links::linkedIds2(id).each{|idx|
                mx.item("related: #{NxQuarks::toString(idx)}", lambda {
                    NxQuarks::landing(idx)
                })
            }

            puts ""

            Arrows::parentsIds2(id)
                .sort{|idx1, idx2| NxQuarks::unixtime(idx1) <=> NxQuarks::unixtime(idx2) }
                .each{|idx|
                    mx.item("parent: #{NxQuarks::toString(idx)}", lambda {
                        NxQuarks::landing(idx)
                    })
                }

            puts ""

            Arrows::childrenIds2(id)
                .sort{|idx1, idx2| NxQuarks::unixtime(idx1) <=> NxQuarks::unixtime(idx2) }
                .each{|idx|
                    mx.item("child : #{NxQuarks::toString(idx)}", lambda {
                        NxQuarks::landing(idx)
                    })
                }

            puts ""

            mx.item("access".yellow, lambda {
                NxQuarks::access(id)
            })

            mx.item("edit".yellow, lambda {
                NxQuarks::edit(id)
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(NxQuarks::description(id))
                return if description == ""
                NxQuarks::setDescription(id, description)
            })

            mx.item("edit datetime".yellow, lambda {
                datetime = Utils::editTextSynchronously(NxQuarks::datetime(id))
                return if !Utils::isDateTime_UTC_ISO8601(datetime)
                unixtime = DateTime.parse(datetime).to_time.to_i
                NxQuarks::setUnixtime(id, unixtime)
            })

            mx.item("add note".yellow, lambda {
                NxQuarks::interactivelyIssueNoteOrNothing(id)
            })

            mx.item("remove note".yellow, lambda {
                filepath = NxQuarks::filepathOrNull(id)
                note = LucilleCore::selectEntityFromListOfEntitiesOrNull("note", NxQuarks::notes(id), lambda{|note| NxQuarks::nxQuarksToString(note) })
                return if note.nil?
                Marbles::removeSetData(filepath, "notes:d39ca9d6644694abc4235e105a64a59b", note["uuid"])
            })

            mx.item("transmute".yellow, lambda {
                targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("targetType", NxQuarks::nxQuarkTypes())
                return if targetType.nil?
                NxQuarks::transmuteOrNothing(id, targetType)
            })

            mx.item("architecture parent".yellow, lambda { 
                idx = NxQuarks::architectId()
                return if idx.nil?
                Arrows::link(idx, id)
            })

            mx.item("architecture related".yellow, lambda { 
                idx = NxQuarks::architectId()
                return if idx.nil?
                Links::link(id, idx)
            })

            mx.item("architecture child".yellow, lambda {
                if NxQuarks::nxType(id) == "NxSmartDirectory" then
                    puts "Operation not permited on a smart directory"
                    return
                end
                idx = NxQuarks::architectId()
                return if idx.nil?
                Arrows::link(id, idx)
            })

            mx.item("remove parents".yellow, lambda {
                idxs, _ = LucilleCore::selectZeroOrMore("parents", [], Arrows::parentsIds2(id), lambda{|idx| NxQuarks::description(idx) })
                idxs.each{|idx|
                    Arrows::unlink(idx, id)
                }
            })

            mx.item("remove related".yellow, lambda {
                idxs, _ = LucilleCore::selectZeroOrMore("related", [], Links::linkedIds2(id), lambda{|idx| NxQuarks::description(idx) })
                idxs.each{|idx|
                    Links::unlink(id, idx)
                }
            })

            mx.item("remove childrens".yellow, lambda {
                if NxQuarks::nxType(id) == "NxSmartDirectory" then
                    puts "Operation not permited on a smart directory"
                    return
                end
                idxs, _ = LucilleCore::selectZeroOrMore("childrens", [], Arrows::childrenIds2(id), lambda{|idx| NxQuarks::description(idx) })
                idxs.each{|idx|
                    Arrows::unlink(id, idx)
                }
            })

            mx.item("recast children data carriers as unique strings at folder".yellow, lambda {
                if NxQuarks::nxType(id) == "NxSmartDirectory" then
                    puts "Operation not permited on a smart directory"
                    return
                end
                targetfolder = LucilleCore::askQuestionAnswerAsString("target folder: ")
                return if !File.exists?(targetfolder)
                return if !File.directory?(targetfolder)
                Arrows::childrenIds2(id)
                    .each{|idx|
                        puts "recasting: #{NxQuarks::toString(idx)}"
                        if NxQuarks::nxType(idx) == "AionPoint" then
                            nhash = Marbles::get(NxQuarks::filepathOrNull(idx), "nhash")
                            operator = MarblesElizabeth.new(NxQuarks::filepathOrNull(idx))
                            descriptionx = NxQuarks::description(idx)
                            uniquestring = SecureRandom.hex(6)
                            targetFolderpath = "#{targetfolder}/#{descriptionx} [#{uniquestring}]"
                            FileUtils.mkdir(targetFolderpath)
                            AionCore::exportHashAtFolder(operator, nhash, targetFolderpath)
                            Marbles::set(NxQuarks::filepathOrNull(idx), "nxType", "FSUniqueString")
                            Marbles::set(NxQuarks::filepathOrNull(idx), "uniquestring", uniquestring)
                        end
                    }

            })

            mx.item("relocate (move a selection of children somewhere else)".yellow, lambda {
                if NxQuarks::nxType(id) == "NxSmartDirectory" then
                    puts "Operation not permited on a smart directory"
                    return
                end
                puts "(1) new parent selection ; (2) moving children selection"
                id1 = NxQuarks::architectId()
                return if id1.nil?

                selected, unselected = LucilleCore::selectZeroOrMore("NxQuarks", [], Arrows::childrenIds2(id), lambda{|idx| NxQuarks::description(idx) })
                selected.each{|idx|
                    puts "Connecting   : #{NxQuarks::description(id1)}, #{NxQuarks::description(idx)}"
                    Arrows::link(id1, idx)
                    puts "Disconnecting: #{NxQuarks::description(id)}, #{NxQuarks::description(idx)}"
                    Arrows::unlink(id, idx)
                }
            })

            mx.item("garbage collection".yellow, lambda { 
                # This is mostly to flush data on quarks that used to be AionPoints but have been transmuted
                # into "FSUniqueString" or "NxSmartDirectory"
                return if !["FSUniqueString", "NxSmartDirectory"].include?(NxQuarks::nxType(id))

                # Here we use priviledge knowledge from Marbles
                filepath = NxQuarks::filepathOrNull(id)
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.execute "delete from _elizabeth_", []
                db.execute "vacuum", []
                db.close
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    code = SecureRandom.hex(2)
                    input = LucilleCore::askQuestionAnswerAsString("Special protocol. Enter this string: '#{code}' : ")
                    return if input != code
                    NxQuarks::destroy(id)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # ---------------------------------------------------
    # Special Circumstances

    # NxQuarks::mx19s()
    def self.mx19s()
        NxQuarks::ids()
            .map{|id|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NxQuarks::toString(id)}",
                    "type"     => "quark",
                    "id"       => id
                }
            }
    end

    # NxQuarks::mx20s()
    def self.mx20s()
        NxQuarks::ids()
            .map{|id|
                volatileuuid = SecureRandom.hex[0, 8]
                tostring = NxQuarks::toString(id)
                {
                    "announce"         => "#{volatileuuid} #{tostring}",
                    "deep-searcheable" => tostring,
                    "type"             => "quark",
                    "id"               => id
                }
            }
    end

    # NxQuarks::selectOneNxQuarkMx19OrNull()
    def self.selectOneNxQuarkMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(NxQuarks::mx19s(), lambda{|item| item["announce"] })
    end

    # NxQuarks::selectOneNxQuarkIdOrNull()
    def self.selectOneNxQuarkIdOrNull()
        mx19 = NxQuarks::selectOneNxQuarkMx19OrNull()
        return if mx19.nil?
        mx19["id"]
    end

    # NxQuarks::fsck(id)
    def self.fsck(id)

        filepath = NxQuarks::filepathOrNull(id)

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

        if !["NxTag", "Url", "Text", "AionPoint", "FSUniqueString", "NxSmartDirectory"].include?(nxType) then
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

        if nxType == "AionPoint" then
            if Marbles::getOrNull(filepath, "nhash").nil? then
                raise "fsck fail: no nhash found for id: #{id}"
            end
            nhash = Marbles::getOrNull(filepath, "nhash")
            operator = MarblesElizabeth.new(NxQuarks::filepathOrNull(id))
            status = AionFsck::structureCheckAionHash(operator, nhash)
            if !status then
                raise "fsck fail: Incorrect Aion Structure for nhash: #{nhash} (id: #{id})"
            end
        end

        if nxType == "FSUniqueString" then
            if Marbles::getOrNull(filepath, "uniquestring").nil? then
                raise "fsck fail: no uniquestring found for FSUniqueString id: #{id}"
            end
        end

        if nxType == "NxSmartDirectory" then
            if Marbles::getOrNull(filepath, "uniquestring").nil? then
                raise "fsck fail: no uniquestring found for NxSmartDirectory id: #{id}"
            end

            Arrows::childrenIds2(id).each{|idx|
                filepathx = NxQuarks::filepathOrNull(idx)
                if !["FSUniqueString", "NxSmartDirectory"].include?(Marbles::get(filepathx, "nxType")) then
                    puts "NxSmartDirectory '#{Marbles::getOrNull(filepathx, "description")}' has a child that is not a FSUniqueString or a NxSmartDirectory"
                    puts "We are going to land on it"
                    LucilleCore::pressEnterToContinue()
                    NxQuarks::landing(id)
                end
            }
        end
    end
end
