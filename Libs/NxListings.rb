
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

    # NxListings::interactivelyCreateNewListingOrNull()
    def self.interactivelyCreateNewListingOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxListings::createNewListing(uuid, description)
        uuid
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

    # NxListings::landing(id)
    def self.landing(id)
        puts "Landing on a Listing [not yet implemented]"
        LucilleCore::pressEnterToContinue()
    end

    # NxListings::nx19s()
    def self.nx19s()
        NxListings::listings().map{|nx21|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} [listing] #{nx21["description"]}",
                "type"     => "NxListing",
                "id"       => nx21["uuid"]
            }
        }
    end
end
