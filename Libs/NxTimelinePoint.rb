
# encoding: UTF-8

class NxTimelinePoint


    # NxTimelinePoint::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/timelime.sqlite3"
    end

    # NxTimelinePoint::insertNewTimelinePoint(uuid, unixtime, description, date, datetime, pointType, contentType, payload)
    def self.insertNewTimelinePoint(uuid, unixtime, description, date, datetime, pointType, contentType, payload)
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _timeline_ (_uuid_, _unixtime_, _description_, _date_, _datetime_, _pointType_, _contentType_, _payload_) values (?, ?, ?, ?, ?, ?, ?, ?)", [uuid, unixtime, description, date, datetime, pointType, contentType, payload]
        db.close
    end

    # NxTimelinePoint::destroyEntry(uuid)
    def self.destroyEntry(uuid)
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _timeline_ where _uuid_=?", [uuid]
        db.close
    end

    # NxTimelinePoint::getNxTimelinePointByIdOrNull(id): null or NxTimelinePoint
    def self.getNxTimelinePointByIdOrNull(id)
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _timeline_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "NxTimelinePoint",
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "date"        => row["_date_"],
                "datetime"    => row["_datetime_"],
                "pointType"   => row["_pointType_"],
                "contentType" => row["_contentType_"],
                "payload"     => row["_payload_"],
            }
        end
        db.close
        answer
    end

    # NxTimelinePoint::types()
    def self.types()
        ["NxDiaryEntry", "NxAppointment", "NxPrivateEvent", "NxPublicEvent", "NxTravelAndEntertainmentDocuments", "NxTodoOnDate"]
    end

    # NxTimelinePoint::selectTimePointTypeOrNull()
    def self.selectTimePointTypeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", NxTimelinePoint::types())
    end

    # NxTimelinePoint::interactivelyCreateNewPointOrNull()
    def self.interactivelyCreateNewPointOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        date = LucilleCore::askQuestionAnswerAsString("date YYYY-MM-DD (empty to abort): ")
        return nil if date == ""
        datetime = LucilleCore::askQuestionAnswerAsString("dateime DateTime Iso 8601 UTC Zulu (empty for missing): ")
        pointType = NxTimelinePoint::selectTimePointTypeOrNull()
        return nil if pointType.nil?
        coordinates = Nx102::interactivelyIssueNewCoordinatesOrNull()
        return nil if coordinates.nil?
        NxTimelinePoint::insertNewTimelinePoint(uuid, Time.new.to_i, description, date, datetime, pointType, coordinates[0], coordinates[1])
        NxTimelinePoint::getNxTimelinePointByIdOrNull(uuid)
    end

    # NxTimelinePoint::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _timeline_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxTimelinePoint::nx10s(): Array[Nx10]
    def self.nx10s()
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _timeline_" , [] ) do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx10",
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxTimelinePoint::toString(nx10)
    def self.toString(nx10)
        "[node] #{nx10["description"]}"
    end

    # NxTimelinePoint::selectOneNx10OrNull()
    def self.selectOneNx10OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxTimelinePoint::nx10s(), lambda{|nx10| NxTimelinePoint::toString(nx10) })
    end

    # NxTimelinePoint::architectOneNx10OrNull()
    def self.architectOneNx10OrNull()
        nx10 = NxTimelinePoint::selectOneNx10OrNull()
        return nx10 if nx10
        NxTimelinePoint::interactivelyCreateNewPointOrNull()
    end

    # NxTimelinePoint::landing(nx10)
    def self.landing(nx10)
        loop {
            nx10 = NxTimelinePoint::getNxTimelinePointByIdOrNull(nx10["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx10.nil?
            system("clear")

            puts NxTimelinePoint::toString(nx10).green
            puts ""

            entities = Links::entities(nx10["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "<index> | update description | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx10["description"]).strip
                return if description == ""
                NxTimelinePoint::updateDescription(nx10["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nx10)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nx10)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxTimelinePoint::destroyEntry(nx10["uuid"])
                end
            end
        }
    end

    # NxTimelinePoint::nx19s()
    def self.nx19s()
        NxTimelinePoint::nx10s().map{|nx10|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxTimelinePoint::toString(nx10)}",
                "type"     => "Nx10",
                "payload"  => nx10
            }
        }
    end

end
