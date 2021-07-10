
# encoding: UTF-8

class Nx27USR

    # Nx27USR::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx27s.sqlite3"
    end

    # Nx27USR::insertNewNx27(uuid, datetime, description, uniquestring)
    def self.insertNewNx27(uuid, datetime, description, uniquestring)
        db = SQLite3::Database.new(Nx27USR::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx27s_ (_uuid_, _datetime_, _description_, _payload1_) values (?,?,?,?,?)", [uuid, datetime, description, uniquestring]
        db.close
    end

    # Nx27USR::destroyNx27(uuid)
    def self.destroyNx27(uuid)
        db = SQLite3::Database.new(Nx27USR::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx27s_ where _uuid_=?", [uuid]
        db.close
    end

    # Nx27USR::tableHashRowToNx27(row)
    def self.tableHashRowToNx27(row)
        return {
            "uuid"         => row["_uuid_"],
            "entityType"   => "Nx27",
            "datetime"     => row["_datetime_"],
            "description"  => row["_description_"],
            "uniquestring" => row["_payload1_"],
        }
    end

    # Nx27USR::getNx27ByIdOrNull(uuid): null or Nx27
    def self.getNx27ByIdOrNull(uuid)
        db = SQLite3::Database.new(Nx27USR::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx27s_ where _uuid_=?" , [uuid] ) do |row|
            answer = Nx27USR::tableHashRowToNx27(row)
        end
        db.close
        answer
    end

    # Nx27USR::interactivelyCreateNewUniqueStringOrNull()
    def self.interactivelyCreateNewUniqueStringOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
        return nil if uniquestring == ""
        Nx27USR::insertNewNx27(uuid, Time.new.utc.iso8601, description, uniquestring)
        Nx27USR::getNx27ByIdOrNull(uuid)
    end

    # Nx27USR::nx27s(): Array[Nx27]
    def self.nx27s()
        db = SQLite3::Database.new(Nx27USR::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx27s_" , [] ) do |row|
            answer << Nx27USR::tableHashRowToNx27(row)
        end
        db.close
        answer
    end

    # Nx27USR::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Nx27USR::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx27s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # Nx27USR::updateUniqueString(uuid, payload1)
    def self.updateUniqueString(uuid, payload1)
        db = SQLite3::Database.new(Nx27USR::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx27s_ set _payload1_=? where _uuid_=?", [payload1, uuid]
        db.close
    end

    # ----------------------------------------------------------------------

    # Nx27USR::toString(nx27)
    def self.toString(nx27)
        "[ustr] #{nx27["description"]}"
    end

    # Nx27USR::access(nx27)
    def self.access(nx27)
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
                Nx27USR::destroyNx27(nx27["uuid"])
            end
        end
    end

    # Nx27USR::interactivelyUpdateUniqueString(nx27)
    def self.interactivelyUpdateUniqueString(nx27)
        puts "Editing the unique string"
        LucilleCore::pressEnterToContinue()
        uniquestring = Utils::editTextSynchronously(nx27["uniquestring"]).strip
        Nx27USR::updateUniqueString(nx27["uuid"], uniquestring)
    end

    # Nx27USR::landing(nx27)
    def self.landing(nx27)
        loop {
            nx27 = Nx27USR::getNx27ByIdOrNull(nx27["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx27.nil?
            system("clear")

            puts Nx27USR::toString(nx27).green
            puts ""

            entities = Links::entities(nx27["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "<index> | access | edit | update description | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("access", command) then
                Nx27USR::access(nx27)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx27["description"]).strip
                return if description == ""
                Nx27USR::updateDescription(nx27["uuid"], description)
            end

            if Interpreting::match("update uniquestring", command) then
                Nx27USR::interactivelyUpdateUniqueString(nx27)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx27)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx27)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx27USR::destroyNx27(nx27["uuid"])
                end
            end
        }
    end

    # Nx27USR::nx19s()
    def self.nx19s()
        Nx27USR::nx27s().map{|nx27|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{Nx27USR::toString(nx27)}",
                "type"     => "Nx27",
                "payload"  => nx27
            }
        }
    end
end
