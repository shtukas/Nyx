
# encoding: UTF-8

class Nx10

    # Nx10::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx10s.sqlite3"
    end

    # Nx10::insertNewNx10(uuid, datetime, description)
    def self.insertNewNx10(uuid, datetime, description)
        db = SQLite3::Database.new(Nx10::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx10s_ (_uuid_, _datetime_, _description_) values (?,?,?)", [uuid, datetime, description]
        db.close
    end

    # Nx10::destroyNx10(uuid)
    def self.destroyNx10(uuid)
        db = SQLite3::Database.new(Nx10::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx10s_ where _uuid_=?", [uuid]
        db.close
    end

    # Nx10::getNx10ByIdOrNull(id): null or Nx10
    def self.getNx10ByIdOrNull(id)
        db = SQLite3::Database.new(Nx10::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx10s_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx10",
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # Nx10::interactivelyCreateNewNx10OrNull()
    def self.interactivelyCreateNewNx10OrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Nx10::insertNewNx10(uuid, Time.new.utc.iso8601, description)
        Nx10::getNx10ByIdOrNull(uuid)
    end

    # Nx10::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Nx10::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # Nx10::nx10s(): Array[Nx10]
    def self.nx10s()
        db = SQLite3::Database.new(Nx10::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx10s_" , [] ) do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx10",
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # Nx10::toString(nx10)
    def self.toString(nx10)
        "[node] #{nx10["description"]}"
    end

    # Nx10::selectOneNx10OrNull()
    def self.selectOneNx10OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Nx10::nx10s(), lambda{|nx10| Nx10::toString(nx10) })
    end

    # Nx10::architectOneNx10OrNull()
    def self.architectOneNx10OrNull()
        nx10 = Nx10::selectOneNx10OrNull()
        return nx10 if nx10
        Nx10::interactivelyCreateNewNx10OrNull()
    end

    # Nx10::landing(nx10)
    def self.landing(nx10)
        loop {
            nx10 = Nx10::getNx10ByIdOrNull(nx10["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx10.nil?
            system("clear")

            puts Nx10::toString(nx10).green
            puts ""

            entities = Links::entities(nx10["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "<index> | update description | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx10["description"]).strip
                return if description == ""
                Nx10::updateDescription(nx10["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx10)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx10)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    Nx10::destroyNx10(nx10["uuid"])
                end
            end
        }
    end

    # Nx10::nx19s()
    def self.nx19s()
        Nx10::nx10s().map{|nx10|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{Nx10::toString(nx10)}",
                "type"     => "Nx10",
                "payload"  => nx10
            }
        }
    end
end
