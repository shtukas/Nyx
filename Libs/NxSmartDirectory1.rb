
# encoding: UTF-8

class NxSmartDirectory1

    # NxSmartDirectory1::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/smartdirectories1.sqlite3"
    end

    # NxSmartDirectory1::insertNewReference(uuid, datetime, mark, style)
    def self.insertNewReference(uuid, datetime, mark, style)
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _smartdirectories1_ (_uuid_, _datetime_, _mark_, _style_) values (?,?,?,?)", [uuid, datetime, mark, style]
        db.close
    end

    # NxSmartDirectory1::destroyRecord(uuid)
    def self.destroyRecord(uuid)
        db = SQLite3::Database.new(NxSmartDirectory1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _smartdirectories1_ where _uuid_=?", [uuid]
        db.close
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
                "mark"        => row["_mark_"],
                "style"       => row["_style_"],
            }
        end
        db.close
        answer
    end

    # NxSmartDirectory1::styles()
    def self.styles()
        ["NoPrefix", "100", "YYYY-MM", "YYYY-MM-DD"]
    end

    # NxSmartDirectory1::interactivelySelectStyleOrNull()
    def self.interactivelySelectStyleOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("style", NxSmartDirectory1::styles())
    end

    # NxSmartDirectory1::interactivelyCreateNewNxSmartDirectory1OrNull()
    def self.interactivelyCreateNewNxSmartDirectory1OrNull()
        uuid = SecureRandom.uuid
        mark = LucilleCore::askQuestionAnswerAsString("mark (empty to abort): ")
        return nil if mark == ""
        style = NxSmartDirectory1::interactivelySelectStyleOrNull()
        return nil if style.nil?
        NxSmartDirectory1::insertNewReference(uuid, Time.new.utc.iso8601, mark, style)
        NxSmartDirectory1::getNxSmartDirectory1ByIdOrNull(uuid)
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
                "datetime"    => row["_datetime_"],
                "mark"        => row["_mark_"],
                "style"       => row["_style_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxSmartDirectory1::getDescription(mark)
    def self.getDescription(mark)
        "Description to be extracted"
    end

    # NxSmartDirectory1::toString(nxSmartD1)
    def self.toString(nxSmartD1)
        "[smartD1] #{NxSmartDirectory1::getDescription(nxSmartD1["mark"])}"
    end

    # NxSmartDirectory1::selectOneNxSmartDirectoryOrNull()
    def self.selectOneNxSmartDirectoryOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxSmartDirectory1::nxSmartDirectories(), lambda{|nxSmartD1| NxSmartDirectory1::getDescription(nxSmartD1["mark"]) })
    end

    # NxSmartDirectory1::architectOneNxSmartDirectoryOrNull()
    def self.architectOneNxSmartDirectoryOrNull()
        nxSmartD1 = NxSmartDirectory1::selectOneNxSmartDirectoryOrNull()
        return nxSmartD1 if nxSmartD1
        NxSmartDirectory1::interactivelyCreateNewNxSmartDirectory1OrNull()
    end

    # NxSmartDirectory1::landing(nxSmartD1)
    def self.landing(nxSmartD1)
        loop {
            nxSmartD1 = NxSmartDirectory1::getNxSmartDirectory1ByIdOrNull(nxSmartD1["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxSmartD1.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxSmartDirectory1::toString(nxSmartD1).green
            puts ""
            ListingEntityMapping::entities(nxSmartD1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item(NxEntities::toString(entity), lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            mx.item("update mark".yellow, lambda {
                mark = Utils::editTextSynchronously(nxSmartD1["mark"]).strip
                return if mark == ""
                NxSmartDirectory1::updateMark(nxSmartD1["uuid"], mark)
            })
            mx.item("add entity".yellow, lambda {
                entity = NxEntities::architectEntityOrNull()
                return if entity.nil?
                ListingEntityMapping::add(nxSmartD1["uuid"], entity["uuid"])
            })
            mx.item("remove entity".yellow, lambda {
                entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity", ListingEntityMapping::entities(nxSmartD1["uuid"]), lambda{|entity| NxEntities::toString(entity) })
                return if entity.nil?
                ListingEntityMapping::remove(nxSmartD1["uuid"], entity["uuid"])
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxSmartDirectory1::destroyRecord(nxSmartD1["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxSmartDirectory1::nx19s()
    def self.nx19s()
        NxSmartDirectory1::nxSmartDirectories().map{|nxSmartD1|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxSmartDirectory1::toString(nxSmartD1)}",
                "type"     => "NxSmartDirectory",
                "payload"  => nxSmartD1
            }
        }
    end
end
