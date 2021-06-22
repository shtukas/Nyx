
# encoding: UTF-8

class NxTimelinePoint

    # -- Database Operations ----------------------------------------------------------------------------------

    # NxTimelinePoint::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/timelime.sqlite3"
    end

    # NxTimelinePoint::insertNewTimelinePoint(uuid, datetime, description, pdate, pdatetime, pointType, contentType, payload)
    def self.insertNewTimelinePoint(uuid, datetime, description, pdate, pdatetime, pointType, contentType, payload)
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _timeline_ (_uuid_, _datetime_, _description_, _pdate_, _pdatetime_, _pointType_, _contentType_, _payload_) values (?, ?, ?, ?, ?, ?, ?, ?)", [uuid, datetime, description, pdate, pdatetime, pointType, contentType, payload]
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

    # NxTimelinePoint::databaseRowToPoint(row)
    def self.databaseRowToPoint(row)
        {
            "uuid"        => row["_uuid_"],
            "entityType"  => "NxTimelinePoint",
            "datetime"    => row["_datetime_"],
            "description" => row["_description_"],
            "pdate"       => row["_pdate_"],
            "pdatetime"   => row["_pdatetime_"],
            "pointType"   => row["_pointType_"],
            "contentType" => row["_contentType_"],
            "payload"     => row["_payload_"],
        }
    end

    # NxTimelinePoint::getNxTimelinePointByIdOrNull(id): null or NxTimelinePoint
    def self.getNxTimelinePointByIdOrNull(id)
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _timeline_ where _uuid_=?" , [id] ) do |row|
            answer = NxTimelinePoint::databaseRowToPoint(row)
        end
        db.close
        answer
    end

    # NxTimelinePoint::points(): Array[NxTimelinePoint]
    def self.points()
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _timeline_" , [] ) do |row|
            answer << NxTimelinePoint::databaseRowToPoint(row)
        end
        db.close
        answer
    end

    # NxTimelinePoint::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxTimelinePoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _timeline_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # ------------------------------------------------------------------------------------

    # NxTimelinePoint::pointTypes()
    def self.pointTypes()
        ["NxDiaryEntry", "NxAppointment", "NxPrivateEvent", "NxPublicEvent", "NxTravelAndEntertainmentDocuments", "NxTodoOnDate"]
    end

    # NxTimelinePoint::selectTimePointTypeOrNull()
    def self.selectTimePointTypeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", NxTimelinePoint::pointTypes())
    end

    # NxTimelinePoint::interactivelyCreateNewPointOrNull()
    def self.interactivelyCreateNewPointOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        date = LucilleCore::askQuestionAnswerAsString("date YYYY-MM-DD (empty to abort): ") # TODO: have something to validate dates
        return nil if date == ""
        datetime = LucilleCore::askQuestionAnswerAsString("dateime DateTime Iso 8601 UTC Zulu (empty for missing): ") # TODO: have something to validate Iso 8601 UTC Zulu
        pointType = NxTimelinePoint::selectTimePointTypeOrNull()
        return nil if pointType.nil?
        coordinates = Nx102::interactivelyIssueNewCoordinatesOrNull()
        return nil if coordinates.nil?
        NxTimelinePoint::insertNewTimelinePoint(uuid, Time.new.to_i, description, date, datetime, pointType, coordinates[0], coordinates[1])
        NxTimelinePoint::getNxTimelinePointByIdOrNull(uuid)
    end

    # ----------------------------------------------------------------------

    # NxTimelinePoint::toString(point)
    def self.toString(point)
        "[timeline point] [#{point["pointType"]}] #{point["description"]}"
    end

    # NxTimelinePoint::selectOnePointOrNull()
    def self.selectOnePointOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxTimelinePoint::points(), lambda{|point| NxTimelinePoint::toString(point) })
    end

    # NxTimelinePoint::architectOnePointOrNull()
    def self.architectOnePointOrNull()
        point = NxTimelinePoint::selectOnePointOrNull()
        return point if point
        NxTimelinePoint::interactivelyCreateNewPointOrNull()
    end

    # NxTimelinePoint::landing(point)
    def self.landing(point)
        loop {
            point = NxTimelinePoint::getNxTimelinePointByIdOrNull(point["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if point.nil?
            system("clear")

            puts NxTimelinePoint::toString(point).green
            puts ""

            entities = Links::entities(point["uuid"])

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
                description = Utils::editTextSynchronously(point["description"]).strip
                return if description == ""
                NxTimelinePoint::updateDescription(point["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(point)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(point)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxTimelinePoint::destroyEntry(point["uuid"])
                end
            end
        }
    end

    # NxTimelinePoint::nx19s()
    def self.nx19s()
        NxTimelinePoint::points().map{|point|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxTimelinePoint::toString(point)}",
                "type"     => "NxTimelinePoint",
                "payload"  => point
            }
        }
    end

end
