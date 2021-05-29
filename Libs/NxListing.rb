
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
        "[list] #{nxListing["description"]}"
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
            mx = LCoreMenuItemsNX1.new()
            puts NxListing::toString(nxListing).green
            puts ""
            Links::entities(nxListing["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[linked] #{NxEntity::toString(entity)}", lambda {
                        NxEntity::landing(entity)
                    })
                }
            puts ""
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(nxListing["description"]).strip
                return if description == ""
                NxListing::updateDescription(nxListing["uuid"], description)
            })
            mx.item("connect".yellow, lambda {
                NxEntity::linkToOtherArchitectured(nxListing)
            })
            mx.item("disconnect".yellow, lambda {
                NxEntity::unlinkFromOther(nxListing)
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxListing::destroyListing(nxListing["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
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
