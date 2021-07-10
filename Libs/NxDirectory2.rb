
# encoding: UTF-8

# create table _directories_ (_directoryId_ text);

class NxDirectory2

    # NxDirectory2::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx-directories-v2.sqlite3"
    end

    # NxDirectory2::register(directoryId)
    def self.register(directoryId)
        db = SQLite3::Database.new(NxDirectory2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _directories_ (_directoryId_) values (?)", [directoryId]
        db.close
    end

    # NxDirectory2::directories(): Array[NxDirectory2]
    def self.directories()
        db = SQLite3::Database.new(NxDirectory2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        directoryIds = []
        db.execute( "select * from _directories_" , [] ) do |row|
            directoryIds << row["_directoryId_"]
        end
        db.close
        directoryIds.map{|id| NxDirectory2::directoryIdToNxDirectory2(id) }
    end

    # NxDirectory2::getNxDirectory2ByIdOrNull(id): null or NxDirectory2
    def self.getNxDirectory2ByIdOrNull(id)
        db = SQLite3::Database.new(NxDirectory2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        directoryId = nil
        db.execute( "select * from _directories_" , [] ) do |row|
            directoryId = row["_directoryId_"]
        end
        db.close
        return nil if directoryId.nil?
        NxDirectory2::directoryIdToNxDirectory2(directoryId)
    end

    # NxDirectory2::directoryIdToNxDirectory2(directoryId)
    def self.directoryIdToNxDirectory2(directoryId)
        {
            "uuid"        => directoryId,
            "entityType"  => "NxDirectory2",
            "datetime"    => Time.new.utc.iso8601,
            "description" => directoryId
        }
    end

    # NxDirectory2::interactivelyRegisterNewNxDirectoryOrNull()
    def self.interactivelyRegisterNewNxDirectoryOrNull()
        directoryId = LucilleCore::askQuestionAnswerAsString("directoryId (empty to abort): ")
        return nil if directoryId == ""
        NxDirectory2::register(directoryId)
        NxDirectory2::getNxDirectory2ByIdOrNull(directoryId)
    end

    # ----------------------------------------------------------------------

    # NxDirectory2::toString(object)
    def self.toString(object)
        "[Directory2] #{object["description"]}"
    end

    # NxDirectory2::selectOneNxDirectory2OrNull()
    def self.selectOneNxDirectory2OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxDirectory2::directories(), lambda{|obj| obj["description"] })
    end

    # NxDirectory2::landing(obj)
    def self.landing(obj)
        loop {
            obj = NxDirectory2::getNxDirectory2ByIdOrNull(obj["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if obj.nil?
            system("clear")

            puts NxDirectory2::toString(obj).gsub("[smart directory]", "[smrd]").green

            puts "uuid: #{obj["uuid"]}"
            #puts "directory: #{NxDirectory2::getDirectoryFolderpathOrNull(obj["uuid"])}"

            puts ""

            connected = []

            Links::entities(obj["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| 
                    connected << entity
                    puts "[#{indx}] [linked] #{NxEntity::toString(entity)}"
                }

            puts ""

            #NxDirectory2::objToNxFSPermaPointsFromDisk(obj).each_with_index{|point, indx|
            #    connected << point
            #    puts "[#{indx}] #{NxFSPermaPoint::toString(point).gsub("[fs perma point]", "[fspp]")}"
            #}

            puts ""

            puts "connect | disconnect".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = connected[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(obj)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(obj)
            end
        }
    end

    # NxDirectory2::nx19s()
    def self.nx19s()
        NxDirectory2::directories()
            .map{|object|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NxDirectory2::toString(object)}",
                    "type"     => "NxDirectory2",
                    "payload"  => object
                }
            }
    end
end
