
# encoding: UTF-8

class NxListings

    # NxListings::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/listings.sqlite3"
    end

    # NxListings::createNewListing(uuid, description)
    def self.createNewListing(uuid, description)
        db = SQLite3::Database.new(NxListings::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _listings_ (_uuid_, _description_) values (?,?)", [uuid, description]
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

    # NxListings::interactivelyCreateNewListingNx21OrNull()
    def self.interactivelyCreateNewListingNx21OrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxListings::createNewListing(uuid, description)
        {
            "uuid"        => uuid,
            "description" => description,
        }
    end

    # NxListings::listings(): Array[Nx21]
    def self.listings()
        db = SQLite3::Database.new(NxListings::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _listings_" , [] ) do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
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
                "uuid"        => row["_uuid_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxListings::ids()
    def self.ids()
        NxListings::listings().map{|item| item["uuid"] }
    end

    # NxListings::toString(nx21)
    def self.toString(nx21)
        "[listing] #{nx21["description"]}"
    end

    # NxListings::selectOneListingNx21OrNull()
    def self.selectOneListingNx21OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(NxListings::listings(), lambda{|nx21| nx21["description"] })
    end

    # NxListings::landing(nx21)
    def self.landing(nx21)
        loop {
            nx21 = NxListings::getListingByIdOrNull(nx21["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx21.nil?
            system("clear")
            puts NxListings::toString(nx21).green
            puts ""
            mx = LCoreMenuItemsNX1.new()
            Nx27s::getEntriesForListingOrdered(nx21["uuid"]).each{|nx27|
                mx.item(Nx27s::toString(nx27), lambda {
                    Nx27s::landing(nx27)
                })
            }
            puts ""
            mx.item("add entry".yellow, lambda {
                Nx27s::interactivelyCreateNewEntryOrNullGivenListing(nx21)
            })
            mx.item("remove entry".yellow, lambda {
                nx27 = LucilleCore::selectEntityFromListOfEntitiesOrNull("entry", Nx27s::getEntriesForListingOrdered(nx21["uuid"]), lambda{|nx27| nx27["description"] })
                return if nx27.nil?
                Nx27s::destroyEntry(nx27["recorduuid"])
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
        NxListings::listings().map{|nx21|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} [listing] #{nx21["description"]}",
                "type"     => "NxListing",
                "payload"  => nx21
            }
        }
    end
end
