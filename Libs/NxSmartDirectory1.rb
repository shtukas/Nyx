
# encoding: UTF-8

class NxSMDir1Auto

    # NxSMDir1Auto::register(uuid, datetime, importId)
    def self.register(uuid, datetime, importId)
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _smartdirectories1_ (_uuid_, _datetime_, _importId_) values (?, ?, ?)", [uuid, datetime, importId]
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
            NxSMDir1Auto::register(uuid, Time.new.utc.iso8601, importId)
        }

        NxSMDir1Auto::destroyRecordsByImportId(importId)
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
            }
        end
        db.close
        answer
    end

    # NxSmartDirectory1::styles()
    def self.styles()
        ["NoPrefix", "100", "YYYY-MM", "YYYY-MM-DD"]
    end

    # NxSmartDirectory1::updateMark(uuid, mark)
    def self.updateMark(uuid, mark)
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _smartdirectories1_ set _mark_=? where _uuid_=?", [mark, uuid]
        db.close
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
                "datetime"    => row["_datetime_"]
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxSmartDirectory1::getDirectoryFolderpathOrNull(mark)
    def self.getDirectoryFolderpathOrNull(mark)
        filepath = `btlas-nyx-smart-directories #{mark}`.strip
        return File.dirname(filepath) if filepath
        nil
    end

    # NxSmartDirectory1::getDescription(mark)
    def self.getDescription(mark)
        File.basename(NxSmartDirectory1::getDirectoryFolderpathOrNull(mark))
    end

    # NxSmartDirectory1::toString(nxSmartD1)
    def self.toString(nxSmartD1)
        "[smartD1] #{NxSmartDirectory1::getDescription(nxSmartD1["uuid"])}"
    end

    # NxSmartDirectory1::displayName(filename)
    def self.displayName(filename)
        filename
    end

    # ----------------------------------------------------------------------

    # NxSmartDirectory1::getNxSD1Elements(nxSmartD1)
    def self.getNxSD1Elements(nxSmartD1)
        folderpath = NxSmartDirectory1::getDirectoryFolderpathOrNull(nxSmartD1["uuid"])
        return [] if folderpath.nil?
        locationToNxSD1ElementOrNull = lambda{|location|
            return nil if File.basename(location).start_with?('.')
            basename = File.basename(location)
            {
                "entityType"       => "NxSD1Element",
                "parentId"         => nxSmartD1["uuid"],
                "locationName"     => basename,
                "displayName"      => NxSmartDirectory1::displayName(basename)
            }
        }
        LucilleCore::locationsAtFolder(folderpath)
            .map{|location| locationToNxSD1ElementOrNull.call(location)}
            .compact
    end

    # ----------------------------------------------------------------------

    # NxSmartDirectory1::selectOneNxSmartDirectoryOrNull()
    def self.selectOneNxSmartDirectoryOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxSmartDirectory1::nxSmartDirectories(), lambda{|nxSmartD1| NxSmartDirectory1::getDescription(nxSmartD1["uuid"]) })
    end

    # NxSmartDirectory1::landing(nxSmartD1)
    def self.landing(nxSmartD1)
        loop {
            nxSmartD1 = NxSmartDirectory1::getNxSmartDirectory1ByIdOrNull(nxSmartD1["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxSmartD1.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxSmartDirectory1::toString(nxSmartD1).green
            puts "uuid: #{nxSmartD1["uuid"]}"
            puts "directory: #{NxSmartDirectory1::getDirectoryFolderpathOrNull(nxSmartD1["uuid"])}"
            puts ""
            Arrows::parents(nxSmartD1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[parent ] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            Links::entities(nxSmartD1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[related] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            Arrows::children(nxSmartD1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[child  ] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            NxSmartDirectory1::getNxSD1Elements(nxSmartD1).each{|element|
                mx.item(NxSD1Element::toString(element), lambda {
                    NxSD1Element::landing(element)
                })
            }
            puts ""
            mx.item("connect to other".yellow, lambda {
                NxEntities::connectToOtherArchitectured(nxSmartD1)
            })
            mx.item("disconnect from other".yellow, lambda {
                NxEntities::disconnectFromOther(nxSmartD1)
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxSmartDirectory1::nx19s()
    def self.nx19s()
        NxSmartDirectory1::nxSmartDirectories()
            .map{|nxSmartD1|
                volatileuuid = SecureRandom.hex[0, 8]
                p1 = {
                    "announce" => "#{volatileuuid} #{NxSmartDirectory1::toString(nxSmartD1)}",
                    "type"     => "NxSmartDirectory",
                    "payload"  => nxSmartD1
                }
                [p1] + NxSD1Element::nx19s(nxSmartD1)
            }
            .flatten
    end
end
