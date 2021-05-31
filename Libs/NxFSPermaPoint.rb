
# encoding: UTF-8

class NxFSPermaPoint

    # NxFSPermaPoint::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/points.sqlite3"
    end

    # NxFSPermaPoint::commitElements(uuid, description, type, location, _1_, _2_)
    def self.commitElements(uuid, description, type, location, _1_, _2_)
        db = SQLite3::Database.new(NxFSPermaPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _points_ where _uuid_=?", [uuid]
        db.execute "insert into _points_ (_uuid_, _description_, _type_, _location_, _1_, _2_) values (?,?,?,?,?,?)", [uuid, description, type, location, _1_, _2_]
        db.close
    end

    # NxFSPermaPoint::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(NxFSPermaPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _points_ where _uuid_=?", [uuid]
        db.close
    end

    # NxFSPermaPoint::databaseRowToNxFSPermaPoint(row)
    def self.databaseRowToNxFSPermaPoint(row)
        object = {
            "uuid"        => row["_uuid_"],
            "entityType"  => "NxFSPermaPoint",
            "description" => row["_description_"],
            "type"        => row["_type_"],
            "location"    => row["_location_"],
            "_1_"         => row["_1_"],
            "_2_"         => row["_2_"],
        }
        if object["type"] == "directory" then
            object["mark"] = object["_1_"]
        end
        if object["type"] == "file" then
            object["inode"] = object["_1_"].to_i
            object["sha256"] = object["_2_"]
        end
        object.delete("_1_")
        object.delete("_2_")
        object
    end

    # NxFSPermaPoint::getPointByIdOrNull(id): null or NxEvent
    def self.getPointByIdOrNull(id)
        db = SQLite3::Database.new(NxFSPermaPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _points_ where _uuid_=?" , [id] ) do |row|
            answer = NxFSPermaPoint::databaseRowToNxFSPermaPoint(row)
        end
        db.close
        answer
    end

    # NxFSPermaPoint::getAll()
    def self.getAll()
        db = SQLite3::Database.new(NxFSPermaPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _points_" , [] ) do |row|
            answer << NxFSPermaPoint::databaseRowToNxFSPermaPoint(row)
        end
        db.close
        answer
    end

    # NxFSPermaPoint::commit(point)
    def self.commit(point)
        if point["type"] == "directory" then
            NxFSPermaPoint::commitElements(point["uuid"], point["description"], point["type"], point["location"], point["mark"], nil)
            return
        end
        if point["type"] == "file" then
            NxFSPermaPoint::commitElements(point["uuid"], point["description"], point["type"], point["location"], point["inode"], point["sha256"])
            return
        end
        raise "6D0B72A0-AF1C-40EC-92D6-F767F3D73B1B"
    end

    # NxFSPermaPoint::issueNewNxFSPermaPoint(location)
    def self.issueNewNxFSPermaPoint(location)
        type = File.directory?(location) ? "directory" : "file"

        point = {}
        point["uuid"]        = SecureRandom.uuid
        point["description"] = File.basename(location)
        point["type"]        = type

        if type == "directory" then
            point["location"] = location
            uuidfile = "#{location}/.NxSD1-3945d937"
            if File.exists?(uuidfile) then
                point["mark"] = IO.read(uuidfile).strip
            else
                mark = SecureRandom.hex
                File.open(uuidfile, "w"){|f| f.write(mark) }
                point["mark"] = mark
            end
        end

        if type == "file" then
            point["location"] = location
            point["inode"]    = File.stat(location).ino
            point["sha256"]   = Digest::SHA256.file(location).hexdigest
        end

        NxFSPermaPoint::commit(point)

        point
    end

    # --------------------------------------------------------

    # When we look at a Smart Directory, we are given the location of its elements.
    # The three following functions are meant to receover the right point from that location.
    # As we do so, we update the points which need to be updated (meaning the look up from a location to a point
    # did succeed but the point was partially outdated). 

    # NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(location, point): [point: Point, hasBeenUpdated: Boolean]
    def self.updatePointToBeFullyConformingNoCommit(location, point)
        trace1 = JSON.generate(point)
        if point["type"] == "directory" then
            point["location"] = location
            point["description"] = File.basename(location)
            uuidfile = "#{location}/.NxSD1-3945d937"
            if File.exists?(uuidfile) then
                point["mark"] = IO.read(uuidfile).strip
            else
                # It could be that the .NxSD1-3945d937 file has been manually deleted or forgotten, 
                # so I should probably use the existing point["mark"], but let's use SecureRandom.hex.
                mark = SecureRandom.hex
                File.open(uuidfile, "w"){|f| f.write(mark) }
                point["mark"] = mark
            end
            trace2 = JSON.generate(point)
            return [point, trace1 != trace2]
        end
        if point["type"] == "file" then
            point["location"] = location
            point["description"] = File.basename(location)
            point["inode"] = File.stat(location).ino
            point["sha256"] = Digest::SHA256.file(location).hexdigest
            trace2 = JSON.generate(point)
            return [point, trace1 != trace2]
        end
        raise "d3a66dc4-0d1a-4d5a-8772-248f2d7f933a: #{point}"
    end

    # NxFSPermaPoint::locationToExistingNxFSPermaPointIfAnyOrNull(location)
    def self.locationToExistingNxFSPermaPointIfAnyOrNull(location)
        if File.directory?(location) then
            uuidfile = "#{location}/.NxSD1-3945d937"
            if File.exists?(uuidfile) then
                mark = IO.read(uuidfile).strip
                point = NxFSPermaPoint::getAll()
                            .select{|point| point["type"] == "directory" }
                            .select{|point| point["mark"] == mark }.first
                return point if point
            end
        else
            point = NxFSPermaPoint::getAll().select{|point| point["location"] == location }.first
            return point if point

            inode = File.stat(location).ino
            point = NxFSPermaPoint::getAll()
                        .select{|point| point["type"] == "file" }
                        .select{|point| point["inode"] == inode }.first
            return point if point

            sha256 = Digest::SHA256.file(location).hexdigest
            point = NxFSPermaPoint::getAll()
                        .select{|point| point["type"] == "file" }
                        .select{|point| point["sha256"] == sha256 }.first
            return point if point
        end

        nil
    end

    # NxFSPermaPoint::locationToNxFSPermaPoint(location)
    def self.locationToNxFSPermaPoint(location)
        point = NxFSPermaPoint::locationToExistingNxFSPermaPointIfAnyOrNull(location)
        if point then
            point, hasBeenUpdated = NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(location, point)
            if hasBeenUpdated then
                NxFSPermaPoint::commit(point)
            end
            return point
        end
        NxFSPermaPoint::issueNewNxFSPermaPoint(location)
    end

    # --------------------------------------------------------

    # Another type of job we need to do is to review the points from the database and update / garbage collect them,
    # This is done as a background thread
    # We review each point, try and identfy the correct location and then perform NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(location, point)

    # NxFSPermaPoint::dataMaintenance()
    def self.dataMaintenance()
        # As of today, 31st May, we are only doing that for the points that are directories. 
        # which are most of the children of smart directories.
        NxFSPermaPoint::getAll().each{|point|
            pretty1 = JSON.pretty_generate(point)

            if point["type"] == "directory" then
                if File.exists?(point["location"]) then
                    point, hasBeenUpdated = NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(point["location"], point)
                    if hasBeenUpdated then
                        puts "UPDATING:"
                        puts pretty1
                        puts JSON.pretty_generate(point)
                        NxFSPermaPoint::commit(point)
                    end
                else
                    # TODO: We need to look for the location by mark
                end
            end

            if point["type"] == "file" then
                if File.exists?(point["location"]) then
                    point, hasBeenUpdated = NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(point["location"], point)
                    if hasBeenUpdated then
                        puts "UPDATING:"
                        puts pretty1
                        puts JSON.pretty_generate(point)
                        NxFSPermaPoint::commit(point)
                    end
                else
                    # TODO: We need to look for the file by inode or hash
                end
            end
        }
    end

    # ---------------------------------------------------------

    # NxFSPermaPoint::toString(point)
    def self.toString(point)
        "[poin] #{point["description"]}"
    end

    # NxFSPermaPoint::access(point)
    def self.access(point)
        location = point["location"]
        if location.nil? then
            puts "Interesting, I could not land on point: #{point}"
            puts "(It could be that the file/directory has moved, but right now there is no code written to find a location from a point, might want to write that one day.)"
            puts JSON.pretty_generate(point)
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "opening: #{location}"
        if File.directory?(location) then
            system("open '#{location}'")
        end
        if File.file?(location) then
            if Utils::fileByFilenameIsSafelyOpenable(File.basename(location)) then
                system("open '#{location}'")
            else
                system("open '#{File.dirname(location)}'")
            end
        end
        LucilleCore::pressEnterToContinue()
    end

    # NxFSPermaPoint::landing(point)
    def self.landing(point)
        loop {
            system("clear")

            puts "#{NxFSPermaPoint::toString(point)} ( uuid: #{point["uuid"]} )".green

            entities = Links::entities(point["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "<index> | access | connect | disconnect".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("access", command) then
                NxFSPermaPoint::access(point)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(point)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(point)
            end
        }
    end

    # NxFSPermaPoint::nx19s()
    def self.nx19s()
        NxFSPermaPoint::getAll().map{|point|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxFSPermaPoint::toString(point)}",
                "type"     => "NxFSPermaPoint",
                "payload"  => point
            }
        }
    end
end
