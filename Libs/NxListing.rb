
# encoding: UTF-8

class NxListing

    # NxListing::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/listings.sqlite3"
    end

    # NxListing::createNewListing(uuid, datetime, description)
    def self.createNewListing(uuid, datetime, description)
        db = SQLite3::Database.new(NxListing::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _listings_ (_uuid_, _datetime_, _description_) values (?,?,?)", [uuid, datetime, description]
        db.close
    end

    # NxListing::destroyListing(uuid)
    def self.destroyListing(uuid)
        db = SQLite3::Database.new(NxListing::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _listings_ where _uuid_=?", [uuid]
        db.close
    end

    # NxListing::getListingByIdOrNull(id): null or NxListing
    def self.getListingByIdOrNull(id)
        db = SQLite3::Database.new(NxListing::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _listings_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "entityType"  => "NxListing",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # NxListing::interactivelyCreateNewNxListingOrNull()
    def self.interactivelyCreateNewNxListingOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxListing::createNewListing(uuid, Time.new.utc.iso8601, description)
        NxListing::getListingByIdOrNull(uuid)
    end

    # NxListing::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxListing::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _listings_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxListing::nxListings(): Array[NxListing]
    def self.nxListings()
        db = SQLite3::Database.new(NxListing::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _listings_" , [] ) do |row|
            answer << {
                "entityType"  => "NxListing",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxListing::toString(nxListing)
    def self.toString(nxListing)
        "[listing] #{nxListing["description"]}"
    end

    # NxListing::selectOneNxListingOrNull()
    def self.selectOneNxListingOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxListing::nxListings(), lambda{|nxListing| nxListing["description"] })
    end

    # NxListing::architectOneNxListingOrNull()
    def self.architectOneNxListingOrNull()
        nxListing = NxListing::selectOneNxListingOrNull()
        return nxListing if nxListing
        NxListing::interactivelyCreateNewNxListingOrNull()
    end

    # NxListing::landing(nxListing)
    def self.landing(nxListing)
        loop {
            nxListing = NxListing::getListingByIdOrNull(nxListing["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxListing.nil?
            system("clear")

            puts NxListing::toString(nxListing).gsub("[listing]", "[list]").green
            puts ""

            entities = Links::entities(nxListing["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "update description | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nxListing["description"]).strip
                return if description == ""
                NxListing::updateDescription(nxListing["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(nxListing)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(nxListing)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxListing::destroyListing(nxListing["uuid"])
                end
            end
        }
    end

    # NxListing::nx19s()
    def self.nx19s()
        NxListing::nxListings().map{|nxListing|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxListing::toString(nxListing)}",
                "type"     => "NxListing",
                "payload"  => nxListing
            }
        }
    end
end
