
# encoding: UTF-8

class NxEvent1

    # NxEvent1::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/events1.sqlite3"
    end

    # NxEvent1::createNewEvent1(uuid, datetime, date, description)
    def self.createNewEvent1(uuid, datetime, date, description)
        db = SQLite3::Database.new(NxEvent1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _events1_ (_uuid_, _datetime_, _date_, _description_) values (?,?,?,?)", [uuid, datetime, date, description]
        db.close
    end

    # NxEvent1::destroyEvent1(uuid)
    def self.destroyEvent1(uuid)
        db = SQLite3::Database.new(NxEvent1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _events1_ where _uuid_=?", [uuid]
        db.close
    end

    # NxEvent1::getNxEvent1ByIdOrNull(id): null or NxEvent1
    def self.getNxEvent1ByIdOrNull(id)
        db = SQLite3::Database.new(NxEvent1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _events1_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "entityType"  => "NxEvent1",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "date"        => row["_date_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # NxEvent1::interactivelyCreateNewNxEvent1OrNull()
    def self.interactivelyCreateNewNxEvent1OrNull()
        uuid = SecureRandom.uuid
        date = LucilleCore::askQuestionAnswerAsString("date (empty to abort): ")
        return nil if date == ""
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxEvent1::createNewEvent1(uuid, Time.new.utc.iso8601, date, description)
        NxEvent1::getNxEvent1ByIdOrNull(uuid)
    end

    # NxEvent1::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxEvent1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _events1_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxEvent1::nxEvent1s(): Array[NxEvent1]
    def self.nxEvent1s()
        db = SQLite3::Database.new(NxEvent1::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _events1_" , [] ) do |row|
            answer << {
                "entityType"  => "NxListing",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "date"        => row["_date_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxEvent1::toString(nxEvent1)
    def self.toString(nxEvent1)
        "[event] #{nxEvent1["description"]}"
    end

    # NxEvent1::selectOneNxEvent1OrNull()
    def self.selectOneNxEvent1OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxEvent1::nxEvent1s(), lambda{|nxEvent1| nxEvent1["description"] })
    end

    # NxEvent1::architectOneNxEvent1OrNull()
    def self.architectOneNxEvent1OrNull()
        nxEvent1 = NxEvent1::selectOneNxEvent1OrNull()
        return nxEvent1 if nxEvent1
        NxEvent1::interactivelyCreateNewNxEvent1OrNull()
    end

    # NxEvent1::landing(nxEvent1)
    def self.landing(nxEvent1)
        loop {
            nxEvent1 = NxEvent1::getNxEvent1ByIdOrNull(nxEvent1["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxEvent1.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxEvent1::toString(nxEvent1).green
            puts ""
            Links::entities(nxEvent1["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[related] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(nxEvent1["description"]).strip
                return if description == ""
                NxEvent1::updateDescription(nxEvent1["uuid"], description)
            })
            mx.item("add tag".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                return if description == ""
                uuid = SecureRandom.uuid
                NxTag::insertTag(uuid, description)
                Links::insert(nxEvent1["uuid"], uuid)
            })
            mx.item("connect to other".yellow, lambda {
                NxEntities::linkToOtherArchitectured(nxEvent1)
            })
            mx.item("unlink from other".yellow, lambda {
                NxEntities::unlinkFromOther(nxEvent1)
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxEvent1::destroyEvent1(nxEvent1["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxEvent1::nx19s()
    def self.nx19s()
        NxEvent1::nxEvent1s().map{|nxEvent1|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxEvent1::toString(nxEvent1)}",
                "type"     => "NxEvent1",
                "payload"  => nxEvent1
            }
        }
    end
end
