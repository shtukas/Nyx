
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
            object["inode"] = object["_1_"]
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

    # --------------------------------------------------------

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

    # NxFSPermaPoint::getOneByIdOrNull(uuid)
    def self.getOneByIdOrNull(uuid)
        BTreeSets::getOrNull(nil, "c68f25ea-f1e5-4724-9e62-27e9cc925536", uuid)
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

    # NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(point)
    def self.updatePointToBeFullyConformingNoCommit(point)
        location = point["location"]
        if point["type"] == "directory" then
            point["description"] = File.basename(location)
            uuidfile = "#{location}/.NxSD1-3945d937"
            if File.exists?(uuidfile) then
                point["mark"] = IO.read(uuidfile).strip
            else
                mark = SecureRandom.hex
                File.open(uuidfile, "w"){|f| f.write(mark) }
                point["mark"] = mark
            end
            return point
        end
        if point["type"] == "file" then
            point["description"] = File.basename(location)
            point["inode"] = File.stat(location).ino
            point["sha256"] = Digest::SHA256.file(location).hexdigest
            return point
        end
        raise "d3a66dc4-0d1a-4d5a-8772-248f2d7f933a: #{point}"
    end

    # NxFSPermaPoint::locationToExistingPossiblyUpdatedNxFSPermaPointIfAnyOrNull(location)
    def self.locationToExistingPossiblyUpdatedNxFSPermaPointIfAnyOrNull(location)
        NxFSPermaPoint::getAll().select{|point| point["location"] == location }.first
    end

    # NxFSPermaPoint::locationToNxFSPermaPoint(location)
    def self.locationToNxFSPermaPoint(location)
        point = NxFSPermaPoint::locationToExistingPossiblyUpdatedNxFSPermaPointIfAnyOrNull(location)
        if point then
            point = NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(point)
            NxFSPermaPoint::commit(point)
            return point
        end
        NxFSPermaPoint::issueNewNxFSPermaPoint(location)
    end

    # ---------------------------------------------------------

    # NxFSPermaPoint::toString(point)
    def self.toString(point)
        "[poin] #{point["description"]}"
    end

    # NxFSPermaPoint::landing(point)
    def self.landing(point)
        location = point["location"]
        if location.nil? then
            puts "Interesting, I could not land on"
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

    # NxFSPermaPoint::garbageCollection()
    def self.garbageCollection()

    end
end
