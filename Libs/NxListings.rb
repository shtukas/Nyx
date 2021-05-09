
# encoding: UTF-8

class NxListings

    # NxListings::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/listings.sqlite3"
    end

    # NxListings::createNewListing(uuid, datetime, description)
    def self.createNewListing(uuid, datetime, description)
        db = SQLite3::Database.new(NxListings::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _listings_ (_uuid_, _datetime_, _description_) values (?,?,?)", [uuid, datetime, description]
        db.close
    end

    # NxListings::destroyListing(uuid)
    def self.destroyListing(uuid)
        db = SQLite3::Database.new(NxListings::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _listings_ where _uuid_=?", [uuid]
        db.close
    end

    # NxListings::getListingByIdOrNull(id): null or Nx21
    def self.getListingByIdOrNull(id)
        db = SQLite3::Database.new(NxListings::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _listings_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "entityType"  => "Nx21",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # NxListings::interactivelyCreateNewListingNx21OrNull()
    def self.interactivelyCreateNewListingNx21OrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxListings::createNewListing(uuid, Time.new.utc.iso8601, description)
        NxListings::getListingByIdOrNull(uuid)
    end

    # NxListings::nx21s(): Array[Nx21]
    def self.nx21s()
        db = SQLite3::Database.new(NxListings::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _listings_" , [] ) do |row|
            answer << {
                "entityType"  => "Nx21",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxListings::toString(nx21)
    def self.toString(nx21)
        "[listing] #{nx21["description"]}"
    end

    # NxListings::selectOneListingNx21OrNull()
    def self.selectOneListingNx21OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxListings::nx21s(), lambda{|nx21| nx21["description"] })
    end

    # NxListings::architectOneListingNx21OrNull()
    def self.architectOneListingNx21OrNull()
        nx21 = NxListings::selectOneListingNx21OrNull()
        return nx21 if nx21
        NxListings::interactivelyCreateNewListingNx21OrNull()
    end

    # NxListings::landing(nx21)
    def self.landing(nx21)
        loop {
            nx21 = NxListings::getListingByIdOrNull(nx21["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx21.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxListings::toString(nx21).green
            puts ""
            ListingEntityMapping::entities(nx21["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item(NxEntities::toString(entity), lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            mx.item("add entity".yellow, lambda {
                entity = NxEntities::architectEntityOrNull()
                return if entity.nil?
                ListingEntityMapping::add(nx21["uuid"], entity["uuid"])
            })
            mx.item("remove entity".yellow, lambda {
                entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity", ListingEntityMapping::entities(nx21["uuid"]), lambda{|entity| NxEntities::toString(entity) })
                return if entity.nil?
                ListingEntityMapping::remove(nx21["uuid"], entity["uuid"])
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxListings::destroyListing(nx21["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxListings::nx19s()
    def self.nx19s()
        NxListings::nx21s().map{|nx21|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxListings::toString(nx21)}",
                "type"     => "Nx21",
                "payload"  => nx21
            }
        }
    end
end
