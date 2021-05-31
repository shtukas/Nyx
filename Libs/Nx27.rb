
# encoding: UTF-8

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

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        BinaryBlobsService::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = BinaryBlobsService::getBlobOrNull(nhash)
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

class Nx27

    # Nx27::types()
    def self.types()
        ["url", "text", "aion-point", "unique-string"]
    end

    # Nx27::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx27s.sqlite3"
    end

    # Nx27::insertNewNx27(uuid, datetime, type, description, payload1)
    def self.insertNewNx27(uuid, datetime, type, description, payload1)
        db = SQLite3::Database.new(Nx27::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx27s_ (_uuid_, _datetime_, _type_, _description_, _payload1_) values (?,?,?,?,?)", [uuid, datetime, type, description, payload1]
        db.close
    end

    # Nx27::destroyNx27(uuid)
    def self.destroyNx27(uuid)
        db = SQLite3::Database.new(Nx27::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx27s_ where _uuid_=?", [uuid]
        db.close
    end

    # Nx27::tableHashRowToNx27(row)
    def self.tableHashRowToNx27(row)
        if row["_type_"] == "unique-string" then
            return {
                "uuid"         => row["_uuid_"],
                "entityType"   => "Nx27",
                "datetime"     => row["_datetime_"],
                "type"         => row["_type_"],
                "description"  => row["_description_"],
                "uniquestring" => row["_payload1_"],
            }
        end
        if row["_type_"] == "url" then
            return {
                "uuid"         => row["_uuid_"],
                "entityType"   => "Nx27",
                "datetime"     => row["_datetime_"],
                "type"         => row["_type_"],
                "description"  => row["_description_"],
                "url"          => row["_payload1_"],
            }
        end
        if row["_type_"] == "text" then
            return {
                "uuid"         => row["_uuid_"],
                "entityType"   => "Nx27",
                "datetime"     => row["_datetime_"],
                "type"         => row["_type_"],
                "description"  => row["_description_"],
                "nhash"        => row["_payload1_"],
            }
        end
        if row["_type_"] == "aion-point" then
            return {
                "uuid"         => row["_uuid_"],
                "entityType"   => "Nx27",
                "datetime"     => row["_datetime_"],
                "type"         => row["_type_"],
                "description"  => row["_description_"],
                "nhash"        => row["_payload1_"],
            }
        end
        raise "46ef7497-2d20-48e2-99d7-85b23fe5eaf2"
    end

    # Nx27::getNx27ByIdOrNull(uuid): null or Nx27
    def self.getNx27ByIdOrNull(uuid)
        db = SQLite3::Database.new(Nx27::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx27s_ where _uuid_=?" , [uuid] ) do |row|
            answer = Nx27::tableHashRowToNx27(row)
        end
        db.close
        answer
    end

    # Nx27::interactivelyCreateNewUrlOrNull()
    def self.interactivelyCreateNewUrlOrNull()
        uuid = SecureRandom.uuid
        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
        return nil if url == ""
        Nx27::insertNewNx27(uuid, datetime, "url", description, url)
        Nx27::getNx27ByIdOrNull(uuid)
    end

    # Nx27::interactivelyCreateNewTextOrNull()
    def self.interactivelyCreateNewTextOrNull()
        uuid = SecureRandom.uuid
        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        text = Utils::editTextSynchronously("")
        return nil if text == ""
        nhash = BinaryBlobsService::putBlob(text)
        Nx27::insertNewNx27(uuid, datetime, "text", description, nhash)
        Nx27::getNx27ByIdOrNull(uuid)
    end

    # Nx27::interactivelyCreateNewAionPointOrNull()
    def self.interactivelyCreateNewAionPointOrNull()
        uuid = SecureRandom.uuid
        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        filename = LucilleCore::askQuestionAnswerAsString("filename on Desktop (empty to abort) : ")
        return nil if filename == ""
        location = "/Users/pascal/Desktop/#{filename}"
        return nil if !File.exists?(location)
        nhash = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
        Nx27::insertNewNx27(uuid, datetime, "aion-point", description, nhash)
        Nx27::getNx27ByIdOrNull(uuid)
    end

    # Nx27::interactivelyCreateNewUniqueStringOrNull()
    def self.interactivelyCreateNewUniqueStringOrNull()
        uuid = SecureRandom.uuid
        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
        return nil if uniquestring == ""
        Nx27::insertNewNx27(uuid, datetime, "unique-string", description, uniquestring)
        Nx27::getNx27ByIdOrNull(uuid)
    end

    # Nx27::interactivelyCreateNewNx27OrNull()
    def self.interactivelyCreateNewNx27OrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", Nx27::types())
        return nil if type.nil?
        if type == "url" then
            return Nx27::interactivelyCreateNewUrlOrNull()
        end
        if type == "text" then
            return Nx27::interactivelyCreateNewTextOrNull()
        end
        if type == "aion-point" then
            return Nx27::interactivelyCreateNewAionPointOrNull()
        end
        if type == "unique-string" then
            return Nx27::interactivelyCreateNewUniqueStringOrNull()
        end
    end

    # Nx27::nx27s(): Array[Nx27]
    def self.nx27s()
        db = SQLite3::Database.new(Nx27::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx27s_" , [] ) do |row|
            answer << Nx27::tableHashRowToNx27(row)
        end
        db.close
        answer
    end

    # Nx27::updateType(uuid, type)
    def self.updateType(uuid, type)
        if !Nx27::types().include?(type) then
            raise "a2b7274e-9b68-4463-8a6c-ac1777654c82: '#{type}'"
        end
        db = SQLite3::Database.new(Nx27::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx27s_ set _type_=? where _uuid_=?", [type, uuid]
        db.close
    end

    # Nx27::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Nx27::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx27s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # Nx27::updatePayload1(uuid, payload1)
    def self.updatePayload1(uuid, payload1)
        db = SQLite3::Database.new(Nx27::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx27s_ set _payload1_=? where _uuid_=?", [payload1, uuid]
        db.close
    end

    # ----------------------------------------------------------------------

    # Nx27::toString(nx27)
    def self.toString(nx27)
        "[data] #{nx27["description"]} {#{nx27["type"]}}"
    end

    # Nx27::access(nx27)
    def self.access(nx27)
        type = nx27["type"]
        if type == "unique-string" then
            uniquestring = nx27["uniquestring"]
            puts "Looking for location..."
            location = Utils::locationByUniqueStringOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                if LucilleCore::askQuestionAnswerAsBoolean("access ? ") then
                    system("open '#{location}'")
                end
            else
                puts "I could not determine the location for uniquestring: '#{uniquestring}'"
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx27::destroyNx27(nx27["uuid"])
                end
            end
        end
        if type == "url" then
            system("open '#{nx27["url"]}'")
        end
        if type == "text" then
            nhash = nx27["nhash"]
            text = BinaryBlobsService::getBlobOrNull(nhash)
            puts ""
            puts text
            puts ""
            LucilleCore::pressEnterToContinue()
        end
        if type == "aion-point" then
            nhash = nx27["nhash"]
            AionCore::exportHashAtFolder(Elizabeth.new(), nhash, "/Users/pascal/Desktop")
            puts "Structure exported to Desktop"
            LucilleCore::pressEnterToContinue()
        end
    end

    # Nx27::edit(nx27)
    def self.edit(nx27)
        if nx27["type"] == "unique-string" then
            puts "Editing the unique string"
            LucilleCore::pressEnterToContinue()
            uniquestring = Utils::editTextSynchronously(nx27["uniquestring"]).strip
            Nx27::updatePayload1(nx27["uuid"], uniquestring)
        end
        if nx27["type"] == "url" then
            puts "Editing the url"
            LucilleCore::pressEnterToContinue()
            url = Utils::editTextSynchronously(nx27["url"]).strip
            Nx27::updatePayload1(nx27["uuid"], url)
        end
        if nx27["type"] == "text" then
            puts "Editing the text"
            LucilleCore::pressEnterToContinue()
            nhash = nx27["nhash"]
            text = BinaryBlobsService::getBlobOrNull(nhash)
            text = Utils::editTextSynchronously(text)
            nhash = BinaryBlobsService::putBlob(text)
            Nx27::updatePayload1(nx27["uuid"], nhash)
        end
        if nx27["type"] == "aion-point" then
            puts "Editing the Aion-Point"
            LucilleCore::pressEnterToContinue()
            nhash = nx27["nhash"]
            AionCore::exportHashAtFolder(Elizabeth.new(), nhash, "/Users/pascal/Desktop")
            puts "Modify the Aion-Point and press enter to continue"
            LucilleCore::pressEnterToContinue()
            filename = LucilleCore::askQuestionAnswerAsString("filename on Desktop (empty to abort) : ")
            return nil if filename == ""
            location = "/Users/pascal/Desktop/#{filename}"
            return nil if !File.exists?(location)
            nhash = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
            Nx27::updatePayload1(nx27["uuid"], nhash)
        end
    end

    # Nx27::transmute(nx27, targetType)
    def self.transmute(nx27, targetType)
        return if nx27["type"] == targetType

        if nx27["type"] == "text" and targetType == "aion-point" then
            puts "Transmuting #{nx27["description"]} of type 'text' into a aion-point"
            LucilleCore::pressEnterToContinue()
            filename = "#{SecureRandom.hex(4)}.txt"
            filepath = "/Users/pascal/Desktop/#{filename}"
            text = BinaryBlobsService::getBlobOrNull(nx27["nhash"])
            File.open(filepath, "w"){|f| f.puts(text) }
            nhash = AionCore::commitLocationReturnHash(Elizabeth.new(), filepath)
            Nx27::updatePayload1(nx27["uuid"], nhash)
            Nx27::updateType(nx27["uuid"], "aion-point")
            LucilleCore::removeFileSystemLocation(filepath)
            return
        end

        puts "I do not know how to transmute #{nx27["description"]} of type '#{nx27["type"]}' into a '#{targetType}'"
    end

    # Nx27::landing(nx27)
    def self.landing(nx27)
        loop {
            nx27 = Nx27::getNx27ByIdOrNull(nx27["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx27.nil?
            system("clear")

            puts Nx27::toString(nx27).green
            puts ""

            entities = Links::entities(nx27["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "<index> | access | edit | update description | connect | disconnect | transmute | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("access", command) then
                Nx27::access(nx27)
            end

            if Interpreting::match("edit", command) then
                Nx27::edit(nx27)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx27["description"]).strip
                return if description == ""
                Nx27::updateDescription(nx27["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx27)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx27)
            end

            if Interpreting::match("transmute", command) then
                targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", Nx27::types())
                return if targetType.nil?
                Nx27::transmute(nx27, targetType)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx27::destroyNx27(nx27["uuid"])
                end
            end
        }
    end

    # Nx27::nx19s()
    def self.nx19s()
        Nx27::nx27s().map{|nx27|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{Nx27::toString(nx27)}",
                "type"     => "Nx27",
                "payload"  => nx27
            }
        }
    end
end
