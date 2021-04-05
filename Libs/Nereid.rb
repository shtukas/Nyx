# require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/Nereid.rb"
=begin
    NereidInterface::interactivelyIssueNewElementOrNull()
    NereidInterface::insertElement(element)
    NereidInterface::toString(input) # input: uuid: String , element Element
    NereidInterface::getElementOrNull(uuid)
    NereidInterface::getElements()
    NereidInterface::landing(input) # input: uuid: String , element Element
    NereidInterface::access(input)
    NereidInterface::edit(input): # new element with same uuid, or null
    NereidInterface::transmuteOrNull(element): # new element with same uuid, or null
    NereidInterface::destroyElement(uuid) # Boolean # Indicates if the destroy was logically successful.
=end

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

class NereidGalaxyFinder

    # NereidGalaxyFinder::locationIsUnisonTmp(location)
    def self.locationIsUnisonTmp(location)
        mark = ".unison.tmp"
        location[-mark.size, mark.size] == mark
    end

    # NereidGalaxyFinder::scanroots()
    def self.scanroots()
        [
            "/Users/pascal/Desktop",
            "/Users/pascal/Galaxy"
        ]
    end

    # NereidGalaxyFinder::forbiddenPaths()
    def self.forbiddenPaths()
        [
            "/Users/pascal/Galaxy/Software"
        ]
    end

    # NereidGalaxyFinder::locationIsTarget(location, uniquestring)
    def self.locationIsTarget(location, uniquestring)
        return false if NereidGalaxyFinder::locationIsUnisonTmp(location)
        File.basename(location).include?(uniquestring)
    end

    # NereidGalaxyFinder::locationEnumerator(roots)
    def self.locationEnumerator(roots)
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exists?(root) then
                    begin
                        Find.find(root) do |path|
                            prune if NereidGalaxyFinder::forbiddenPaths().include?(path)
                            filepaths << path
                        end
                    rescue
                    end
                end
            }
        end
    end

    # NereidGalaxyFinder::extractNX141MarkerFromFilenameOrNull(filename)
    def self.extractNX141MarkerFromFilenameOrNull(filename)
        # From the convention
        # NX141-[*], where [*] is a string of unspecified length with no space and no dot.
        correction = lambda {|str|
            if str.include?(' ') then
                return correction.call(str[0, str.size-1])
            end
            if str.include?('.') then
                return correction.call(str[0, str.size-1])
            end
            str
        }
        if filename.include?('NX141-') then
            extraction = filename[filename.index('NX141-'), filename.size]
            return correction.call(extraction)
        end
        nil
    end

    # NereidGalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
    def self.uniqueStringToLocationOrNullUseTheForce(uniquestring)
        NereidGalaxyFinder::locationEnumerator(NereidGalaxyFinder::scanroots())
            .each{|location|
                next if NereidGalaxyFinder::locationIsUnisonTmp(location)
                if ( mark = NereidGalaxyFinder::extractNX141MarkerFromFilenameOrNull(File.basename(location)) ) then
                    KeyValueStore::set(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{mark}", location)
                end
                if NereidGalaxyFinder::locationIsTarget(location, uniquestring) then
                    KeyValueStore::set(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{uniquestring}", location)
                    return location
                end
            }
        nil
    end

    # NereidGalaxyFinder::uniqueStringToLocationOrNull(uniquestring)
    def self.uniqueStringToLocationOrNull(uniquestring)
        maybefilepath = KeyValueStore::getOrNull(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{uniquestring}")
        if maybefilepath and File.exists?(maybefilepath) and File.basename(maybefilepath).include?(uniquestring) then
            return maybefilepath
        end
        maybefilepath = NereidGalaxyFinder::uniqueStringToLocationOrNullUseTheForce(uniquestring)
        if maybefilepath then
            KeyValueStore::set(nil, "3ecadb11-dfd5-4d02-be89-4565a67e9891:#{uniquestring}", maybefilepath)
        end
        maybefilepath
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

class NereidDatabase
    # NereidDatabase::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Elements.sqlite3"
    end
end

class NereidDatabaseDataCarriers

    # NereidDatabaseDataCarriers::insertElementComponents(uuid, unixtime, description, type, payload)
    def self.insertElementComponents(uuid, unixtime, description, type, payload)
        db = SQLite3::Database.new(NereidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.execute "insert into _datacarrier_ (_uuid_, _unixtime_, _description_, _type_, _payload_) values (?,?,?,?,?)", [uuid, unixtime, description, type, payload]
        db.commit 
        db.close
    end

    # NereidDatabaseDataCarriers::insertElement(element)
    def self.insertElement(element)
        uuid        = element["uuid"]
        unixtime    = element["unixtime"]
        description = element["description"]
        type        = element["type"]
        payload     = element["payload"]
        NereidDatabaseDataCarriers::insertElementComponents(uuid, unixtime, description, type, payload)
    end

    # NereidDatabaseDataCarriers::getElementOrNull(uuid)
    def self.getElementOrNull(uuid)
        db = SQLite3::Database.new(NereidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _datacarrier_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"        => row['_uuid_'], 
                "unixtime"    => row['_unixtime_'],
                "description" => row['_description_'],
                "type"        => row['_type_'],
                "payload"     => row['_payload_']
            }
        end
        db.close
        answer
    end

    # NereidDatabaseDataCarriers::getElements()
    def self.getElements()
        db = SQLite3::Database.new(NereidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _datacarrier_", []) do |row|
            answer << {
                "uuid"        => row['_uuid_'], 
                "unixtime"    => row['_unixtime_'],
                "description" => row['_description_'],
                "type"        => row['_type_'],
                "payload"     => row['_payload_']
            }
        end
        db.close
        answer
    end

    # NereidDatabaseDataCarriers::destroyElement(uuid)
    def self.destroyElement(uuid)
        db = SQLite3::Database.new(NereidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end
end

class NereidElizabeth

    def initialize()
    end

    def commitBlob(blob)
        NereidBinaryBlobsService::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        NereidBinaryBlobsService::filepathToContentHash(filepath)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = NereidBinaryBlobsService::getBlobOrNull(nhash)
        raise "[NereidElizabeth error: 2400b1c6-42ff-49d0-b37c-fbd37f179e01]" if blob.nil?
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

#AionCore::commitLocationReturnHash(operator, location)
#AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
#AionFsck::structureCheckAionHash(operator, nhash)

class NereidInterface

    # NereidInterface::getElementOrNull(uuid)
    def self.getElementOrNull(uuid)
        NereidDatabaseDataCarriers::getElementOrNull(uuid)
    end

    # NereidInterface::getElements()
    def self.getElements()
        NereidDatabaseDataCarriers::getElements()
    end

    # NereidInterface::toStringFromElement(element)
    def self.toStringFromElement(element)
        if element["type"] == "Line" then
            description = element["description"]
            # -------------------------------------------------
            # Correction of a mistake resulting from bad data transfer
            if (description.size % 2 == 0) and (description[0, description.size/2] == description[description.size/2, description.size]) then
                description = description[0, description.size/2]
            end
            # -------------------------------------------------
            return "[nereid] [line] #{description}"    
        end
        if element["type"] == "Url" and element["description"] == element["payload"] then
            return "[nereid] [url] #{element["payload"]}"    
        end
        if element["type"] == "AionPoint" then
            return "[nereid] [#{element["type"].downcase}] #{element["description"]}"  
        end
        "[nereid] [#{element["type"].downcase}] #{element["description"]} | #{element["payload"]}"
    end

    # NereidInterface::toString(input) # input: uuid: String , element Element
    def self.toString(input)
        if input.class.to_s == "String" then
            element = NereidInterface::getElementOrNull(input)
            if element.nil? then
                return "[nereid] no element found for input: #{input}"
            end
            return NereidInterface::toStringFromElement(element)
        end
        NereidInterface::toStringFromElement(input)
    end

    # NereidInterface::insertElement(element)
    def self.insertElement(element)
        NereidDatabaseDataCarriers::insertElement(element)
    end

    # NereidInterface::interactivelyIssueNewElementOrNull()
    def self.interactivelyIssueNewElementOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])
        return nil if type.nil?
        if type == "Line" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            payload = ""
            NereidDatabaseDataCarriers::insertElementComponents(uuid, unixtime, description, "Line", payload)
            return NereidDatabaseDataCarriers::getElementOrNull(uuid)
        end
        if type == "Url" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url == ""
            payload = url
            description = LucilleCore::askQuestionAnswerAsString("description (optional): ")
            if description == "" then
                description = payload
            end
            NereidDatabaseDataCarriers::insertElementComponents(uuid, unixtime, description, "Url", payload)
            return NereidDatabaseDataCarriers::getElementOrNull(uuid)
        end
        if type == "Text" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            text = CatalystUtils::editTextSynchronously("")
            payload = NereidBinaryBlobsService::putBlob(text)
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            NereidDatabaseDataCarriers::insertElementComponents(uuid, unixtime, description, "Text", payload)
            return NereidDatabaseDataCarriers::getElementOrNull(uuid)
        end
        if type == "ClickableType" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            return nil if !File.exists?(filepath)

            nhash = NereidBinaryBlobsService::putBlob(IO.read(filepath))
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"

            description = LucilleCore::askQuestionAnswerAsString("description (optional): ")
            if description == "" then
                description = payload
            end

            NereidDatabaseDataCarriers::insertElementComponents(uuid, unixtime, description, "ClickableType", payload)
            return NereidDatabaseDataCarriers::getElementOrNull(uuid)
        end
        if type == "AionPoint" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            return nil if !File.exists?(location)

            payload = AionCore::commitLocationReturnHash(NereidElizabeth.new(), location)

            description = LucilleCore::askQuestionAnswerAsString("description (optional): ")
            if description == "" then
                description = payload
            end

            NereidDatabaseDataCarriers::insertElementComponents(uuid, unixtime, description, "AionPoint", payload)
            return NereidDatabaseDataCarriers::getElementOrNull(uuid)
        end
        nil
    end

    # NereidInterface::inputToElementOrNull(input, operationName)
    def self.inputToElementOrNull(input, operationName)
        if input.class.to_s == "String" then
            element = NereidInterface::getElementOrNull(input)
            if element.nil? then
                return nil if operationName == "postAccessCleanUpTodoListingEdition"
                puts "I could not find an element for input '#{input}'. #{operationName} aborted."
                LucilleCore::pressEnterToContinue()
                return nil
            end
            return element
        else
            return input
        end
    end

    # NereidInterface::landing(input) # input: uuid: String , element Element
    def self.landing(input)

        element = NereidInterface::inputToElementOrNull(input, "landing")
        return if element.nil?

        loop {

            return if NereidInterface::getElementOrNull(element["uuid"]).nil?
            element = NereidInterface::getElementOrNull(element["uuid"]) # could have been transmuted in the previous loop

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts NereidInterface::toString(element)
            puts "uuid: #{element["uuid"]}".yellow

            puts ""

            mx.item("access".yellow,lambda { 
                NereidInterface::access(element) 
            })

            mx.item("set/update description".yellow, lambda {
                description = NereidUtils::editTextSynchronously(element["description"])
                return if description == ""
                element["description"] = description
                NereidDatabaseDataCarriers::insertElement(element)
            })

            mx.item("edit".yellow, lambda { NereidInterface::edit(element) })

            mx.item("transmute".yellow, lambda { 
                NereidInterface::transmuteOrNull(element)
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(element)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this element ? ") then
                    NereidInterface::destroyElement(element["uuid"])
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NereidInterface::access(input)
    def self.access(input)

        element = NereidInterface::inputToElementOrNull(input, "access")
        return if element.nil?

        if element["type"] == "Line" then
            puts element["description"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if element["type"] == "Url" then
            puts "opening '#{element["payload"]}'"
            NereidUtils::openUrl(element["payload"])
            LucilleCore::pressEnterToContinue()
            return
        end
        if element["type"] == "Text" then
            puts "opening text '#{element["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            return if type.nil?
            if type == "read-only" then
                text = NereidBinaryBlobsService::getBlobOrNull(element["payload"])
                filepath = "/Users/pascal/Desktop/#{element["uuid"]}.txt"
                File.open(filepath, "w"){|f| f.write(text) }
                puts "I have exported the file at '#{filepath}'"
                LucilleCore::pressEnterToContinue()
            end
            if type == "read-write" then
                text = NereidBinaryBlobsService::getBlobOrNull(element["payload"])
                text = NereidUtils::editTextSynchronously(text)
                element["payload"] = NereidBinaryBlobsService::putBlob(text)
                NereidDatabaseDataCarriers::insertElement(element)
            end
            return
        end
        if element["type"] == "ClickableType" then
            puts "opening file '#{element["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            return if type.nil?
            if type == "read-only" then
                blobuuid, extension = element["payload"].split("|")
                filepath = "/Users/pascal/Desktop/#{element["uuid"]}#{extension}"
                blob = NereidBinaryBlobsService::getBlobOrNull(blobuuid)
                File.open(filepath, "w"){|f| f.write(blob) }
                puts "I have exported the file at '#{filepath}'"
                LucilleCore::pressEnterToContinue()
            end
            if type == "read-write" then
                blobuuid, extension = element["payload"].split("|")
                filepath = "/Users/pascal/Desktop/#{element["uuid"]}#{extension}"
                blob = NereidBinaryBlobsService::getBlobOrNull(blobuuid)
                File.open(filepath, "w"){|f| f.write(blob) }
                puts "I have exported the file at '#{filepath}'"
                puts "When done, you will enter the filename of the replacement"
                LucilleCore::pressEnterToContinue()
                filename = LucilleCore::askQuestionAnswerAsString("desktop filename (empty to abort): ")
                return if filename == ""
                filepath = "/Users/pascal/Desktop/#{filename}"
                return nil if !File.exists?(filepath)

                nhash = NereidBinaryBlobsService::putBlob(IO.read(filepath))
                dottedExtension = File.extname(filename)
                payload = "#{nhash}|#{dottedExtension}"

                element["payload"] = payload
                NereidDatabaseDataCarriers::insertElement(element)
            end
            return
        end
        if element["type"] == "AionPoint" then
            puts "opening aion point '#{element["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            return if type.nil?
            if type == "read-only" then
                nhash = element["payload"]
                targetReconstructionFolderpath = "/Users/pascal/Desktop"
                AionCore::exportHashAtFolder(NereidElizabeth.new(), nhash, targetReconstructionFolderpath)
                puts "Export completed"
                LucilleCore::pressEnterToContinue()
            end
            if type == "read-write" then
                nhash = element["payload"]
                targetReconstructionFolderpath = "/Users/pascal/Desktop"
                AionCore::exportHashAtFolder(NereidElizabeth.new(), nhash, targetReconstructionFolderpath)
                puts "Export completed"
                puts "When done, you will enter the location name of the replacement"
                LucilleCore::pressEnterToContinue()
                locationname = LucilleCore::askQuestionAnswerAsString("desktop location name (empty to abort): ")
                return if locationname == ""
                location = "/Users/pascal/Desktop/#{locationname}"
                return nil if !File.exists?(location)
                payload = AionCore::commitLocationReturnHash(NereidElizabeth.new(), location)
                element["payload"] = payload
                NereidDatabaseDataCarriers::insertElement(element)
            end
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # NereidInterface::accessTodoListingEdition(input)
    def self.accessTodoListingEdition(input)

        element = NereidInterface::inputToElementOrNull(input, "access")
        return if element.nil?

        if element["type"] == "Line" then
            puts element["description"]
            return
        end
        if element["type"] == "Url" then
            puts "opening '#{element["payload"]}'"
            NereidUtils::openUrl(element["payload"])
            return
        end
        if element["type"] == "Text" then
            puts "opening text '#{element["payload"]}'"
            text = NereidBinaryBlobsService::getBlobOrNull(element["payload"])
            text = NereidUtils::editTextSynchronously(text)
            element["payload"] = NereidBinaryBlobsService::putBlob(text)
            NereidDatabaseDataCarriers::insertElement(element)
            return
        end
        if element["type"] == "ClickableType" then
            puts "opening file '#{element["payload"]}'"
            blobuuid, extension = element["payload"].split("|")
            filepath = "/Users/pascal/Desktop/#{element["uuid"]}#{extension}"
            blob = NereidBinaryBlobsService::getBlobOrNull(blobuuid)
            File.open(filepath, "w"){|f| f.write(blob) }
            puts "I have exported the file at '#{filepath}'"
            system("open '#{filepath}'")
            return
        end
        if element["type"] == "AionPoint" then
            puts "opening aion point '#{element["payload"]}'"
            nhash = element["payload"]
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(NereidElizabeth.new(), nhash, targetReconstructionFolderpath)
            puts "Export completed"

            aionObject = AionCore::getAionObjectByHash(NereidElizabeth.new(), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"

            if location[-7, 7] == ".webloc" then
                system("open '#{location}'")
            end
            if [".png", ".pdf"].include?(location[-4, 4]) then
                system("open '#{location}'")
            end
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # NereidInterface::postAccessCleanUpTodoListingEdition(input)
    def self.postAccessCleanUpTodoListingEdition(input)

        element = NereidInterface::inputToElementOrNull(input, "postAccessCleanUpTodoListingEdition")
        return if element.nil?

        if element["type"] == "Line" then
            return
        end
        if element["type"] == "Url" then
            return
        end
        if element["type"] == "Text" then
            return
        end
        if element["type"] == "ClickableType" then
            puts "cleaning file '#{element["payload"]}'"
            blobuuid, extension = element["payload"].split("|")
            filepath = "/Users/pascal/Desktop/#{element["uuid"]}#{extension}"
            return if !File.exists?(filepath)
            LucilleCore::removeFileSystemLocation(filepath)
            return
        end
        if element["type"] == "AionPoint" then
            puts "cleaning aion point '#{element["payload"]}'"
            nhash = element["payload"]
            aionObject = AionCore::getAionObjectByHash(NereidElizabeth.new(), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"
            return if !File.exists?(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # NereidInterface::edit(input): # new element with same uuid, or null
    def self.edit(input)

        element = NereidInterface::inputToElementOrNull(input, "transmutation")
        return if element.nil?

        if element["type"] == "Line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line == ""
            element["description"] = line
            element["payload"] = ""
            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if element["type"] == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            if url != "" then
                element["payload"] = url
            end

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end        

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if element["type"] == "Text" then
            text = NereidBinaryBlobsService::getBlobOrNull(element["payload"])
            text = CatalystUtils::editTextSynchronously(text)
            element["payload"] = NereidBinaryBlobsService::putBlob(text)

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if element["type"] == "ClickableType" then
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if File.exists?(filepath) then
                nhash = NereidBinaryBlobsService::putBlob(IO.read(filepath))
                dottedExtension = File.extname(filenameOnTheDesktop)
                payload = "#{nhash}|#{dottedExtension}"
                element["payload"] = payload
            end

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if element["type"] == "AionPoint" then
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if File.exists?(location) then
                payload = AionCore::commitLocationReturnHash(NereidElizabeth.new(), location)
                element["payload"] = payload
            end

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        raise "[error: 707CAFD7-46CF-489B-B829-5F4816C4911D]"
    end

    # NereidInterface::transmuteOrNull(input): # new element with same uuid, or null
    def self.transmuteOrNull(input)

        element = NereidInterface::inputToElementOrNull(input, "transmutation")
        return if element.nil?

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])
        return nil if type.nil?
        if type == "Line" then
            element["type"] = "Line"
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            element["description"] = description
            element["payload"] = ""
            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if type == "Url" then
            element["type"] = "Url"

            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url == ""
            element["payload"] = url

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end 

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if type == "Text" then
            element["type"] = "Text"
            text = CatalystUtils::editTextSynchronously("")
            element["payload"] = NereidBinaryBlobsService::putBlob(text)

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end 

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if type == "ClickableType" then
            element["type"] = "ClickableType"

            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            return nil if !File.exists?(filepath)

            nhash = NereidBinaryBlobsService::putBlob(IO.read(filepath))
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"
            element["payload"] = payload

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end 

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
        if type == "AionPoint" then
            element["type"] = "AionPoint"

            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            return nil if !File.exists?(location)

            payload = AionCore::commitLocationReturnHash(NereidElizabeth.new(), location)
            element["payload"] = payload

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                element["description"] = description
            end 

            NereidDatabaseDataCarriers::insertElement(element)
            return element
        end
    end

    # NereidInterface::destroyElement(uuid)
    def self.destroyElement(uuid)
        NereidDatabaseDataCarriers::destroyElement(uuid)
        true
    end
end

class NereidFsck

    # NereidFsck::checkElement(element)
    def self.checkElement(element)
        if element["type"] == "Line" then
            puts "checking #{element["type"]}"
            return
        end
        if element["type"] == "Url" then
            puts "checking #{element["type"]}"
            return
        end  
        if element["type"] == "Text" then
            blob = NereidBinaryBlobsService::getBlobOrNull(element["payload"])
            if blob.nil? then
                puts "Could not extract Text blob payload: #{element["payload"]}".red
                exit
            end
            return
        end
        if element["type"] == "ClickableType" then
            blob = NereidBinaryBlobsService::getBlobOrNull(element["payload"].split("|").first)
            if blob.nil? then
                puts "Could not extract ClickableType blob payload: #{element["payload"]}".red
                exit
            end
            return
        end 
        if element["type"] == "AionPoint" then
            puts "checking AionPoint: #{element["payload"]}"
            status = AionFsck::structureCheckAionHash(NereidElizabeth.new(), element["payload"])
            if !status then
                puts "Could not validate payload: #{element["payload"]}".red
                exit
            end
            return
        end
        puts element
        raise "cfe763bb-013b-4ae6-a611-935dca16260b"
    end

    # NereidFsck::check()
    def self.check()
        NereidInterface::getElements()
            .each{|element| checkElement(element) }
    end
end

