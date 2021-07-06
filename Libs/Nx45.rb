
# encoding: UTF-8

class Nx45

    # Nx45::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx45s-asteroids.sqlite3"
    end

    # Nx45::insertNewNx45(uuid, datetime, asteroidId, description)
    def self.insertNewNx45(uuid, datetime, asteroidId, description)
        db = SQLite3::Database.new(Nx45::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx45s_ where _uuid_=?", [uuid]
        db.execute "delete from _nx45s_ where _asteroidId_=?", [asteroidId]
        db.execute "insert into _nx45s_ (_uuid_, _datetime_, _asteroidId_, _description_) values (?,?,?,?)", [uuid, datetime, asteroidId, description]
        db.close
    end

    # Nx45::destroyNx45(uuid)
    def self.destroyNx45(uuid)
        db = SQLite3::Database.new(Nx45::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx45s_ where _uuid_=?", [uuid]
        db.close
    end

    # Nx45::getNx45ByIdOrNull(id): null or Nx45
    def self.getNx45ByIdOrNull(id)
        db = SQLite3::Database.new(Nx45::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx45s_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx45",
                "datetime"    => row["_datetime_"],
                "asteroidId"  => row["_asteroidId_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # Nx45::getNx45ByAsteroidIdOrNull(asteroidId): null or Nx45
    def self.getNx45ByAsteroidIdOrNull(asteroidId)
        db = SQLite3::Database.new(Nx45::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx45s_ where _asteroidId_=?" , [asteroidId] ) do |row|
            answer = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx45",
                "datetime"    => row["_datetime_"],
                "asteroidId"  => row["_asteroidId_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # Nx45::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Nx45::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx45s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # Nx45::nx45s(): Array[Nx45]
    def self.nx45s()
        db = SQLite3::Database.new(Nx45::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx45s_" , [] ) do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx45",
                "datetime"    => row["_datetime_"],
                "asteroidId"  => row["_asteroidId_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # Nx45::interactivelyCreateNewNx45OrNull()
    def self.interactivelyCreateNewNx45OrNull()
        puts "Nx45::interactivelyCreateNewNx45OrNull() is not implemented yet"
        LucilleCore::pressEnterToContinue()
        nil
    end

    # ----------------------------------------------------------------------

    # Nx45::toString(nx45)
    def self.toString(nx45)
        "[asteroid] #{nx45["description"]}"
    end

    # Nx45::selectOneNx45OrNull()
    def self.selectOneNx45OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Nx45::nx45s(), lambda{|nx45| Nx45::toString(nx45) })
    end

    # Nx45::architectOneNx45OrNull()
    def self.architectOneNx45OrNull()
        # nx45 = Nx45::selectOneNx45OrNull()
        #return nx45 if nx45
        puts "Nx45::architectOneNx45OrNull() has not been implemented yet"
        LucilleCore::pressEnterToContinue()
        nil
    end

    # Nx45::landing(nx45)
    def self.landing(nx45)
        loop {
            nx45 = Nx45::getNx45ByIdOrNull(nx45["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx45.nil?
            system("clear")

            puts Nx45::toString(nx45).green
            puts ""

            entities = Links::entities(nx45["uuid"])

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
                description = Utils::editTextSynchronously(nx45["description"]).strip
                return if description == ""
                Nx45::updateDescription(nx45["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx45)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx45)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    Nx45::destroyNx45(nx45["uuid"])
                end
            end
        }
    end

    # Nx45::nx19s()
    def self.nx19s()
        Nx45::nx45s().map{|nx45|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{Nx45::toString(nx45)}",
                "type"     => "Nx45",
                "payload"  => nx45
            }
        }
    end
end
