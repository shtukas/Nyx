
# encoding: UTF-8

class NxAsteroid

    # NxAsteroid::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx45s-asteroids.sqlite3"
    end

    # NxAsteroid::insertNewNx45(uuid, datetime, asteroidId, description)
    def self.insertNewNx45(uuid, datetime, asteroidId, description)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx45s_ where _uuid_=?", [uuid]
        db.execute "delete from _nx45s_ where _asteroidId_=?", [asteroidId]
        db.execute "insert into _nx45s_ (_uuid_, _datetime_, _asteroidId_, _description_) values (?,?,?,?)", [uuid, datetime, asteroidId, description]
        db.close
    end

    # NxAsteroid::destroyNx45(uuid)
    def self.destroyNx45(uuid)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx45s_ where _uuid_=?", [uuid]
        db.close
    end

    # NxAsteroid::getNx45ByIdOrNull(id): null or Nx45
    def self.getNx45ByIdOrNull(id)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
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

    # NxAsteroid::getNx45ByAsteroidIdOrNull(asteroidId): null or Nx45
    def self.getNx45ByAsteroidIdOrNull(asteroidId)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
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

    # NxAsteroid::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx45s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxAsteroid::nx45s(): Array[Nx45]
    def self.nx45s()
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
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

    # NxAsteroid::interactivelyCreateNewNx45OrNull()
    def self.interactivelyCreateNewNx45OrNull()
        puts "NxAsteroid::interactivelyCreateNewNx45OrNull() is not implemented yet"
        LucilleCore::pressEnterToContinue()
        nil
    end

    # ----------------------------------------------------------------------

    # NxAsteroid::sanitizeDescriptionForUseAsFilename(description)
    def self.sanitizeDescriptionForUseAsFilename(description)
        description
            .gsub(":", "-")
            .gsub("/", "-")
            .gsub("'", "-")
    end

    # NxAsteroid::asteroidExportFolder()
    def self.asteroidExportFolder()
        path = "/Users/pascal/Galaxy/Asteroid-Belt/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}"
        if !File.exists?(path) then
            FileUtils.mkpath(path)
        end
        path
    end

    # NxAsteroid::issueOSURLFile(filepath, url)
    def self.issueOSURLFile(filepath, url)
        contents = [
            "[InternetShortcut]",
            "URL=#{url}",
            ""
        ].join("\n")
        File.open(filepath, "w"){|f| f.puts(contents) }
    end

    # NxAsteroid::issueNewAsteroidId()
    def self.issueNewAsteroidId()
        primaryId = SecureRandom.uuid
        instanceId = SecureRandom.hex[0, 8]
        "asteroid|#{primaryId}|#{instanceId}"
    end

    # NxAsteroid::interactivelyCreateNewUrlOrNull()
    def self.interactivelyCreateNewUrlOrNull()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
        return nil if url == ""

        asteroidId = NxAsteroid::issueNewAsteroidId()

        filename = "#{NxAsteroid::sanitizeDescriptionForUseAsFilename(description)} (#{asteroidId}).url"
        filepath = "#{NxAsteroid::asteroidExportFolder()}/#{filename}"
        NxAsteroid::issueOSURLFile(filepath, url)

        NxAsteroid::insertNewNx45(uuid, Time.new.utc.iso8601, asteroidId, description)
        NxAsteroid::getNx45ByIdOrNull(uuid)
    end

    # NxAsteroid::interactivelyCreateNewTextOrNull()
    def self.interactivelyCreateNewTextOrNull()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        text = Utils::editTextSynchronously("")
        return nil if text == ""

        asteroidId = NxAsteroid::issueNewAsteroidId()

        filename = "#{NxAsteroid::sanitizeDescriptionForUseAsFilename(description)} (#{asteroidId}).txt"
        filepath = "#{NxAsteroid::asteroidExportFolder()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(text) }

        NxAsteroid::insertNewNx45(uuid, Time.new.utc.iso8601, asteroidId, description)
        NxAsteroid::getNx45ByIdOrNull(uuid)
    end

    # NxAsteroid::interactivelyCreateNewAionPointOrNull()
    def self.interactivelyCreateNewAionPointOrNull()

        uuid = SecureRandom.uuid

        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        filename = LucilleCore::askQuestionAnswerAsString("filename on Desktop (empty to abort) : ")
        return nil if filename == ""
        location = "/Users/pascal/Desktop/#{filename}"
        return nil if !File.exists?(location)

        asteroidId = NxAsteroid::issueNewAsteroidId()

        name2 = "#{NxAsteroid::sanitizeDescriptionForUseAsFilename(description)} (#{asteroidId})"
        path2 = "#{NxAsteroid::asteroidExportFolder()}/#{name2}"
        FileUtils.mkpath(path2)

        LucilleCore::copyFileSystemLocation(location, path2)

        NxAsteroid::insertNewNx45(uuid, Time.new.utc.iso8601, asteroidId, description)
        NxAsteroid::getNx45ByIdOrNull(uuid)
    end

    # ----------------------------------------------------------------------

    # NxAsteroid::toString(nx45)
    def self.toString(nx45)
        "[asteroid] #{nx45["description"]}"
    end

    # NxAsteroid::selectOneNx45OrNull()
    def self.selectOneNx45OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxAsteroid::nx45s(), lambda{|nx45| NxAsteroid::toString(nx45) })
    end

    # NxAsteroid::architectOneNx45OrNull()
    def self.architectOneNx45OrNull()
        # nx45 = NxAsteroid::selectOneNx45OrNull()
        #return nx45 if nx45
        puts "NxAsteroid::architectOneNx45OrNull() has not been implemented yet"
        LucilleCore::pressEnterToContinue()
        nil
    end

    # NxAsteroid::landing(nx45)
    def self.landing(nx45)
        loop {
            nx45 = NxAsteroid::getNx45ByIdOrNull(nx45["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx45.nil?
            system("clear")

            puts NxAsteroid::toString(nx45).green
            puts ""

            entities = Links::entities(nx45["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "update description | connect | disconnect | destroy".yellow

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
                NxAsteroid::updateDescription(nx45["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx45)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx45)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy asteroid reference ? : ") then
                    NxAsteroid::destroyNx45(nx45["uuid"])
                end
            end
        }
    end

    # NxAsteroid::nx19s()
    def self.nx19s()
        NxAsteroid::nx45s().map{|nx45|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxAsteroid::toString(nx45)}",
                "type"     => "Nx45",
                "payload"  => nx45
            }
        }
    end
end
