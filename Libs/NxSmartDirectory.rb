
# encoding: UTF-8

# CREATE TABLE _smartdirectories1_ (_uuid_ text, _datetime_ text, _description_ text, _importId_ text);

class NxSmartDirectory

    # NxSmartDirectory::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/smartdirectories.sqlite3"
    end

    # NxSmartDirectory::register(uuid, datetime, description, importId)
    def self.register(uuid, datetime, description, importId)
        db = SQLite3::Database.new(NxSmartDirectory::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _smartdirectories1_ (_uuid_, _datetime_, _description_, _importId_) values (?, ?, ?, ?)", [uuid, datetime, description, importId]
        db.close
    end

    # NxSmartDirectory::nxSmartDirectories(): Array[NxSmartDirectory]
    def self.nxSmartDirectories()
        db = SQLite3::Database.new(NxSmartDirectory::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _smartdirectories1_" , [] ) do |row|
            answer << {
                "entityType"  => "NxSmartDirectory",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"]
            }
        end
        db.close
        answer
    end

    # NxSmartDirectory::getNxSmartDirectoryByIdOrNull(id): null or NxSmartDirectory
    def self.getNxSmartDirectoryByIdOrNull(id)
        db = SQLite3::Database.new(NxSmartDirectory::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _smartdirectories1_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "entityType"  => "NxSmartDirectory",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"]
            }
        end
        db.close
        answer
    end

    # NxSmartDirectory::destroyRecordsByImportId(importId)
    def self.destroyRecordsByImportId(importId)
        db = SQLite3::Database.new(NxSmartDirectory::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _smartdirectories1_ where _importId_!=?", [importId]
        db.close
    end

    # NxSmartDirectory::smartDirectoriesImportScan(verbose)
    def self.smartDirectoriesImportScan(verbose)

        smartDirectoriesLocationEnumerator = (lambda{
            Enumerator.new do |filepaths|
                Find.find("/Users/pascal/Galaxy/Documents") do |path|
                    next if File.file?(path)
                    next if path[-3, 3] != "[s]"
                    filepaths << path
                end
            end
        }).call()

        importId = SecureRandom.uuid

        smartDirectoriesLocationEnumerator.each{|folderpath|
            puts "registering: #{folderpath}" if verbose
            uuidfile = "#{folderpath}/.NxSD1-3945d937"
            if !File.exists?(uuidfile) then
                File.open(uuidfile, "w"){|f| f.write(SecureRandom.uuid) }
            end
            uuid = IO.read(uuidfile).strip
            description = File.basename(folderpath)
            NxSmartDirectory::register(uuid, Time.new.utc.iso8601, description, importId)
        }

        NxSmartDirectory::destroyRecordsByImportId(importId)

        NxSmartDirectory::nxSmartDirectories().each{|nxsd|
            NxSmartDirectory::nxsdToNxFSPermaPointsFromDisk(nxsd)
        }
    end

    # ----------------------------------------------------------------------

    # NxSmartDirectory::nxsdToNxFSPermaPointsFromDisk(nxsd): Array[NxFSPoint]
    def self.nxsdToNxFSPermaPointsFromDisk(nxsd)
        folderpath = NxSmartDirectory::getDirectoryFolderpathOrNull(nxsd["uuid"])
        return [] if folderpath.nil?
        LucilleCore::locationsAtFolder(folderpath)
            .select{|location|
                File.basename(location) != ".NxSD1-3945d937"
            }
            .map{|location| NxFSPermaPoint::locationToNxFSPermaPoint(location)}
    end

    # NxSmartDirectory::getDirectoryFolderpathOrNull(uuid)
    def self.getDirectoryFolderpathOrNull(uuid)
        filepath = `btlas-nyx-smart-directories #{uuid}`.strip
        return File.dirname(filepath) if filepath
        nil
    end

    # ----------------------------------------------------------------------

    # NxSmartDirectory::toString(nxsd)
    def self.toString(nxsd)
        "[smart directory] #{nxsd["description"]}"
    end

    # NxSmartDirectory::selectOneNxSmartDirectoryOrNull()
    def self.selectOneNxSmartDirectoryOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxSmartDirectory::nxSmartDirectories(), lambda{|nxsd| nxsd["description"] })
    end

    # NxSmartDirectory::landing(nxsd)
    def self.landing(nxsd)
        loop {
            nxsd = NxSmartDirectory::getNxSmartDirectoryByIdOrNull(nxsd["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxsd.nil?
            system("clear")

            puts NxSmartDirectory::toString(nxsd).gsub("[smart directory]", "[smrd]").green

            puts "uuid: #{nxsd["uuid"]}"
            puts "directory: #{NxSmartDirectory::getDirectoryFolderpathOrNull(nxsd["uuid"])}"

            puts ""

            connected = []

            Links::entities(nxsd["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| 
                    connected << entity
                    puts "[#{indx}] [linked] #{NxEntity::toString(entity)}"
                }

            puts ""

            NxSmartDirectory::nxsdToNxFSPermaPointsFromDisk(nxsd).each_with_index{|point, indx|
                connected << point
                puts "[#{indx}] #{NxFSPermaPoint::toString(point).gsub("[fs perma point]", "[fspp]")}"
            }

            puts ""

            puts "<index> | connect | disconnect".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = connected[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nxsd)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nxsd)
            end
        }
    end

    # NxSmartDirectory::nx19s()
    def self.nx19s()
        NxSmartDirectory::nxSmartDirectories()
            .map{|nxsd|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NxSmartDirectory::toString(nxsd)}",
                    "type"     => "NxSmartDirectory",
                    "payload"  => nxsd
                }
            }
    end
end
