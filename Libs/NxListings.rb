
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

    # NxListings::getListingByIdOrNull(id): null or NxListing
    def self.getListingByIdOrNull(id)
        db = SQLite3::Database.new(NxListings::databaseFilepath())
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

    # NxListings::interactivelyCreateNewNxListingOrNull()
    def self.interactivelyCreateNewNxListingOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxListings::createNewListing(uuid, Time.new.utc.iso8601, description)
        NxListings::getListingByIdOrNull(uuid)
    end

    # NxListings::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxListings::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _listings_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxListings::nxListings(): Array[NxListing]
    def self.nxListings()
        db = SQLite3::Database.new(NxListings::databaseFilepath())
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

    # NxListings::toString(nxListing)
    def self.toString(nxListing)
        "[listing] #{nxListing["description"]}"
    end

    # NxListings::selectOneNxListingOrNull()
    def self.selectOneNxListingOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxListings::nxListings(), lambda{|nxListing| nxListing["description"] })
    end

    # NxListings::architectOneNxListingOrNull()
    def self.architectOneNxListingOrNull()
        nxListing = NxListings::selectOneNxListingOrNull()
        return nxListing if nxListing
        NxListings::interactivelyCreateNewNxListingOrNull()
    end

    # NxListings::landing(nxListing)
    def self.landing(nxListing)
        loop {
            nxListing = NxListings::getListingByIdOrNull(nxListing["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxListing.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxListings::toString(nxListing).green
            puts ""
            Links::entities(nxListing["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[related] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(nxListing["description"]).strip
                return if description == ""
                NxListings::updateDescription(nxListing["uuid"], description)
            })
            mx.item("add tag".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                return if description == ""
                uuid = SecureRandom.uuid
                NxTag::insertTag(uuid, description)
                Links::insert(nxListing["uuid"], uuid)
            })
            mx.item("connect to other".yellow, lambda {
                NxEntities::linkToOtherArchitectured(nxListing)
            })
            mx.item("unlink from other".yellow, lambda {
                NxEntities::unlinkFromOther(nxListing)
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxListings::destroyListing(nxListing["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxListings::nx19s()
    def self.nx19s()
        NxListings::nxListings().map{|nxListing|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxListings::toString(nxListing)}",
                "type"     => "NxListing",
                "payload"  => nxListing
            }
        }
    end
end
