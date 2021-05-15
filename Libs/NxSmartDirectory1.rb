
# encoding: UTF-8

class NxSMDir1Auto

    # CREATE TABLE _smartdirectories1_ (_uuid_ text, _datetime_ text, _description_ text, _importId_ text);

    # NxSMDir1Auto::register(uuid, datetime, description, importId)
    def self.register(uuid, datetime, description, importId)
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _smartdirectories1_ (_uuid_, _datetime_, _description_, _importId_) values (?, ?, ?, ?)", [uuid, datetime, description, importId]
        db.close
    end

    # NxSMDir1Auto::destroyRecordsByImportId(importId)
    def self.destroyRecordsByImportId(importId)
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _smartdirectories1_ where _importId_!=?", [importId]
        db.close
    end

    # NxSMDir1Auto::smartDirectoriesImportScan(verbose)
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
            NxSMDir1Auto::register(uuid, Time.new.utc.iso8601, description, importId)
        }

        NxSMDir1Auto::destroyRecordsByImportId(importId)

        NxSmartDirectory1::nxSmartDirectories().each{|nxSmartDirectory1|
            NxSD1Element::nxSmartDirectory1ToNxSD1ElementsFromDisk(nxSmartDirectory1).each{|element|
                puts "registering: NxSD1Element: #{element["description"]}" if verbose
                NxSD1Element::register(nxSmartDirectory1["uuid"], element["locationName"], element["description"], importId)
            }
        }

        NxSD1Element::destroyRecordsByImportId(importId)
    end
end

class NxSmartDirectory1

    # NxSmartDirectory1::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/smartdirectories1.sqlite3"
    end

    # NxSmartDirectory1::getNxSmartDirectory1ByIdOrNull(id): null or NxSmartDirectory
    def self.getNxSmartDirectory1ByIdOrNull(id)
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
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

    # NxSmartDirectory1::styles()
    def self.styles()
        ["NoPrefix", "100", "YYYY-MM", "YYYY-MM-DD"]
    end

    # NxSmartDirectory1::nxSmartDirectories(): Array[NxSmartDirectory]
    def self.nxSmartDirectories()
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
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

    # ----------------------------------------------------------------------

    # NxSmartDirectory1::getDirectoryFolderpathOrNull(uuid)
    def self.getDirectoryFolderpathOrNull(uuid)
        filepath = `btlas-nyx-smart-directories #{uuid}`.strip
        return File.dirname(filepath) if filepath
        nil
    end

    # NxSmartDirectory1::toString(nxSmartDirectory1)
    def self.toString(nxSmartDirectory1)
        "[smartD1] #{nxSmartDirectory1["description"]}"
    end

    # ----------------------------------------------------------------------

    # NxSmartDirectory1::selectOneNxSmartDirectoryOrNull()
    def self.selectOneNxSmartDirectoryOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxSmartDirectory1::nxSmartDirectories(), lambda{|nxSmartDirectory1| nxSmartDirectory1["description"] })
    end

    # NxSmartDirectory1::landing(nxSmartDirectory1)
    def self.landing(nxSmartDirectory1)
        loop {
            nxSmartDirectory1 = NxSmartDirectory1::getNxSmartDirectory1ByIdOrNull(nxSmartDirectory1["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxSmartDirectory1.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxSmartDirectory1::toString(nxSmartDirectory1).green
            puts "uuid: #{nxSmartDirectory1["uuid"]}"
            puts "directory: #{NxSmartDirectory1::getDirectoryFolderpathOrNull(nxSmartDirectory1["uuid"])}"
            puts ""
            Arrows::parents(nxSmartDirectory1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[parent ] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            Links::entities(nxSmartDirectory1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[related] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            Arrows::children(nxSmartDirectory1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[child  ] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            NxSD1Element::nxSmartDirectory1ToNxSD1ElementsFromDisk(nxSmartDirectory1).each{|element|
                mx.item(NxSD1Element::toString(element), lambda {
                    NxSD1Element::landing(element)
                })
            }
            puts ""
            mx.item("add tag".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                return if description == ""
                uuid = SecureRandom.uuid
                NxTag::insertTag(uuid, description)
                Links::insert(nxSmartDirectory1["uuid"], uuid)
            })
            mx.item("connect to other".yellow, lambda {
                NxEntities::connectToOtherArchitectured(nxSmartDirectory1)
            })
            mx.item("disconnect from other".yellow, lambda {
                NxEntities::disconnectFromOther(nxSmartDirectory1)
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxSmartDirectory1::nx19s()
    def self.nx19s()
        NxSmartDirectory1::nxSmartDirectories()
            .map{|nxSmartDirectory1|
                volatileuuid = SecureRandom.hex[0, 8]
                p1 = {
                    "announce" => "#{volatileuuid} #{NxSmartDirectory1::toString(nxSmartDirectory1)}",
                    "type"     => "NxSmartDirectory",
                    "payload"  => nxSmartDirectory1
                }
                [p1] + NxSD1Element::nx19s(nxSmartDirectory1)
            }
            .flatten
    end
end
