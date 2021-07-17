
# encoding: UTF-8

class NxAsteroid

    # NxAsteroid::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Asteriods/asteroids.sqlite3"
    end

    # This function was taken from the Asteroid code
    # NxAsteroid::setAsteroidRecord(nyxId, location, unixtime)
    def self.setAsteroidRecord(nyxId, location, unixtime)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _asteroids_ where _nyxId_=? and _location_=?", [nyxId, location]
        db.execute "insert into _asteroids_ (_nyxId_, _location_, _unixtime_) values (?, ?, ?)", [nyxId, location, unixtime]
        db.close
    end

    # NxAsteroid::databaseRowToNxAsteroid(row): NxAsteroid
    def self.databaseRowToNxAsteroid(row)
        {
            "uuid"        => row["_nyxId_"],
            "entityType"  => "Nx45",
            "datetime"    => Time.at(row["_unixtime_"]).utc.iso8601,
            "location"    => row["_location_"]
        }
    end

    # NxAsteroid::getAsteroidByUUIDOrNull(uuid): null or NxAsteroid
    def self.getAsteroidByUUIDOrNull(uuid)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _asteroids_ where _nyxId_=?" , [uuid] ) do |row|
            answer = NxAsteroid::databaseRowToNxAsteroid(row)
        end
        db.close
        answer
    end

    # NxAsteroid::nx45s(): Array[NxAsteroid]
    def self.nx45s()
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _asteroids_" , [] ) do |row|
            answer << NxAsteroid::databaseRowToNxAsteroid(row)
        end
        db.close
        answer
            .reduce([]){|selected, item|
                if selected.none?{|obj| obj["uuid"] == item["uuid"] } then
                    selected + [item]
                else
                    selected
                end
            }
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

    # NxAsteroid::issueURLFile(filepath, url)
    def self.issueURLFile(filepath, url)
        contents = [
            "[InternetShortcut]",
            "URL=#{url}",
            ""
        ].join("\n")
        File.open(filepath, "w"){|f| f.puts(contents) }
    end

    # NxAsteroid::interactivelyCreateNewUrlOrNull()
    def self.interactivelyCreateNewUrlOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
        return nil if url == ""

        uuid = SecureRandom.uuid
        asteroidId = "Ax16-#{uuid}"

        filename = "#{NxAsteroid::sanitizeDescriptionForUseAsFilename(description)} (#{asteroidId}).url"
        filepath = "#{NxAsteroid::asteroidExportFolder()}/#{filename}"
        NxAsteroid::issueURLFile(filepath, url)

        NxAsteroid::setAsteroidRecord(uuid, filepath, Time.new.to_i)

        NxAsteroid::getAsteroidByUUIDOrNull(uuid)
    end

    # NxAsteroid::interactivelyCreateNewTextOrNull()
    def self.interactivelyCreateNewTextOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        text = Utils::editTextSynchronously("")
        return nil if text == ""

        uuid = SecureRandom.uuid
        asteroidId = "Ax16-#{uuid}"

        filename = "#{NxAsteroid::sanitizeDescriptionForUseAsFilename(description)} (#{asteroidId}).txt"
        filepath = "#{NxAsteroid::asteroidExportFolder()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(text) }

        NxAsteroid::setAsteroidRecord(uuid, filepath, Time.new.to_i)

        NxAsteroid::getAsteroidByUUIDOrNull(uuid)
    end

    # NxAsteroid::interactivelyCreateNewAionPointOrNull()
    def self.interactivelyCreateNewAionPointOrNull()

        datetime = Time.new.utc.iso8601
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        filename = LucilleCore::askQuestionAnswerAsString("filename on Desktop (empty to abort) : ")
        return nil if filename == ""
        location = "/Users/pascal/Desktop/#{filename}"
        return nil if !File.exists?(location)

        uuid = SecureRandom.uuid
        asteroidId = "Ax16-#{uuid}"

        name2 = "#{NxAsteroid::sanitizeDescriptionForUseAsFilename(description)} (#{asteroidId})"
        path2 = "#{NxAsteroid::asteroidExportFolder()}/#{name2}"
        FileUtils.mkpath(path2)

        LucilleCore::copyFileSystemLocation(location, path2)

        NxAsteroid::setAsteroidRecord(uuid, path2, Time.new.to_i)

        NxAsteroid::getAsteroidByUUIDOrNull(uuid)
    end

    # ----------------------------------------------------------------------

    # NxAsteroid::toString(nx45)
    def self.toString(nx45)
        location = nx45["location"]
        description = 
            if File.exists?(location) then
                File.basename(location)
            else
                "file not found for asteroid #{nx45["uuid"]}"
            end
        "[asteroid] #{description}"
    end

    # NxAsteroid::selectOneNx45OrNull()
    def self.selectOneNx45OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxAsteroid::nx45s(), lambda{|nx45| NxAsteroid::toString(nx45) })
    end

    # NxAsteroid::landing(nx45)
    def self.landing(nx45)
        loop {
            nx45 = NxAsteroid::getAsteroidByUUIDOrNull(nx45["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx45.nil?
            system("clear")

            puts NxAsteroid::toString(nx45).green
            puts "location: #{nx45["location"]}"
            puts ""

            entities = Links::entities(nx45["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "access | connect | disconnect".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("access", command) then
                if File.exists?(nx45["location"]) then
                    system("open '#{nx45["location"]}'")
                else
                    puts "Could not find location for asteroid: Ax16-#{nx45["uuid"]}"
                    puts "The latest known location (#{nx45["location"]}) does not exist"
                    LucilleCore::pressEnterToContinue()
                end
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx45)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx45)
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
