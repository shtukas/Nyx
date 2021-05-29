
# encoding: UTF-8

class NxEvent

    # NxEvent::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/events.sqlite3"
    end

    # NxEvent::createNewEvent(uuid, datetime, date, description)
    def self.createNewEvent(uuid, datetime, date, description)
        db = SQLite3::Database.new(NxEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _events1_ (_uuid_, _datetime_, _date_, _description_) values (?,?,?,?)", [uuid, datetime, date, description]
        db.close
    end

    # NxEvent::destroyEvent(uuid)
    def self.destroyEvent(uuid)
        db = SQLite3::Database.new(NxEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _events1_ where _uuid_=?", [uuid]
        db.close
    end

    # NxEvent::getNxEventByIdOrNull(id): null or NxEvent
    def self.getNxEventByIdOrNull(id)
        db = SQLite3::Database.new(NxEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _events1_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "NxEvent",
                "datetime"    => row["_datetime_"],
                "date"        => row["_date_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # NxEvent::interactivelyCreateNewNxEventOrNull()
    def self.interactivelyCreateNewNxEventOrNull()
        uuid = SecureRandom.uuid
        date = LucilleCore::askQuestionAnswerAsString("date (empty to abort): ")
        return nil if date == ""
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxEvent::createNewEvent(uuid, Time.new.utc.iso8601, date, description)
        NxEvent::getNxEventByIdOrNull(uuid)
    end

    # NxEvent::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _events1_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxEvent::events(): Array[NxEvent]
    def self.events()
        db = SQLite3::Database.new(NxEvent::databaseFilepath())
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

    # NxEvent::toString(event)
    def self.toString(event)
        "[evnt] #{event["description"]}"
    end

    # NxEvent::selectOneNxEventOrNull()
    def self.selectOneNxEventOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxEvent::events(), lambda{|event| event["description"] })
    end

    # NxEvent::architectOneNxEventOrNull()
    def self.architectOneNxEventOrNull()
        event = NxEvent::selectOneNxEventOrNull()
        return event if event
        NxEvent::interactivelyCreateNewNxEventOrNull()
    end

    # NxEvent::landing(event)
    def self.landing(event)
        loop {
            event = NxEvent::getNxEventByIdOrNull(event["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if event.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxEvent::toString(event).green
            puts ""
            Links::entities(event["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[linked] #{NxEntity::toString(entity)}", lambda {
                        NxEntity::landing(entity)
                    })
                }
            puts ""
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(event["description"]).strip
                return if description == ""
                NxEvent::updateDescription(event["uuid"], description)
            })
            mx.item("connect".yellow, lambda {
                NxEntity::linkToOtherArchitectured(event)
            })
            mx.item("disconnect".yellow, lambda {
                NxEntity::unlinkFromOther(event)
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxEvent::destroyEvent(event["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxEvent::nx19s()
    def self.nx19s()
        NxEvent::events().map{|event|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxEvent::toString(event)}",
                "type"     => "NxEvent",
                "payload"  => event
            }
        }
    end
end
