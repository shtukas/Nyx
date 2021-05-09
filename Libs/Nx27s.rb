
# encoding: UTF-8

class Nx27s

    # Nx27s::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/Nx27s.sqlite3"
    end

    # Nx27s::insertNewNx27(uuid, datetime, type, payload1, payload2)
    def self.insertNewNx27(uuid, datetime, type, payload1, payload2)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx27s_ (_uuid_, _datetime_, _type_, _payload1_, _payload2_) values (?,?,?,?,?)", [uuid, datetime, type, payload1, payload2]
        db.close
    end

    # Nx27s::destroyNx27(uuid)
    def self.destroyNx27(uuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx27s_ where _uuid_=?", [uuid]
        db.close
    end

    # Nx27s::tableHashRowToNx27(row)
    def self.tableHashRowToNx27(row)
        if row["_type_"] == "unique-string" then
            return {
                "uuid"         => row["_uuid_"],
                "entityType"   => "Nx27",
                "datetime"     => row["_datetime_"],
                "type"         => "unique-string",
                "description"  => row["_payload1_"],
                "uniquestring" => row["_payload2_"],
            }
        end
        if row["_type_"] == "url" then
            return {
                "uuid"         => row["_uuid_"],
                "entityType"   => "Nx27",
                "datetime"     => row["_datetime_"],
                "type"         => "url",
                "description"  => row["_payload1_"],
                "url"          => row["_payload2_"],
            }
        end
        raise "46ef7497-2d20-48e2-99d7-85b23fe5eaf2"
    end

    # Nx27s::getNx27ByIdOrNull(uuid): null or Nx21
    def self.getNx27ByIdOrNull(uuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx27s_ where _uuid_=?" , [uuid] ) do |row|
            answer = Nx27s::tableHashRowToNx27(row)
        end
        db.close
        answer
    end

    # Nx27s::interactivelyCreateNewNx27OrNull()
    def self.interactivelyCreateNewNx27OrNull()
        uuid = SecureRandom.uuid

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["unique-string", "url"])
        return nil if type.nil?

        if type == "unique-string" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return nil if uniquestring == ""
            datetime = Time.new.utc.iso8601
            Nx27s::insertNewNx27(uuid, datetime, "unique-string", description, uniquestring)
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add it to a listing ? ") then
                nx21 = NxListings::architectOneListingNx21OrNull()
                if nx21 then
                    ListingEntityMapping::add(nx21["uuid"], uuid)
                end
            end
            return Nx27s::getNx27ByIdOrNull(uuid)
        end
        if type == "url" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            datetime = Time.new.utc.iso8601
            Nx27s::insertNewNx27(uuid, datetime, "url", description, url)
            if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add it to a listing ? ") then
                nx21 = NxListings::architectOneListingNx21OrNull()
                if nx21 then
                    ListingEntityMapping::add(nx21["uuid"], uuid)
                end
            end
            return Nx27s::getNx27ByIdOrNull(uuid)
        end
    end

    # Nx27s::nx27s(): Array[Nx27]
    def self.nx27s()
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx27s_" , [] ) do |row|
            answer << Nx27s::tableHashRowToNx27(row)
        end
        db.close
        answer
    end

    # Nx27s::getNx27sForListingOrdered(listinguuid): Array[Nx21]
    def self.getNx27sForListingOrdered(listinguuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx27s_ where _listinguuid_=? order by _datetime_" , [listinguuid] ) do |row|
            answer << Nx27s::tableHashRowToNx27(row)
        end
        db.close
        answer
    end



    # Nx27s::updateNx27TypeUniqueStringDescription(uuid, description)
    def self.updateNx27TypeUniqueStringDescription(uuid, description)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx27s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # ----------------------------------------------------------------------

    # Nx27s::toString(nx27)
    def self.toString(nx27)
        "[entry  ] #{nx27["description"]} (#{nx27["type"]})"
    end

    # Nx27s::access(nx27)
    def self.access(nx27)
        type = nx27["type"]
        if type == "unique-string" then
            uniquestring = nx27["uniquestring"]
            puts "Looking for location..."
            location = Utils::locationByUniqueStringOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                if LucilleCore::askQuestionAnswerAsBoolean("access ? ") then
                    system("open '#{location}'")
                end
            else
                puts "I could not determine the location for uniquestring: '#{uniquestring}'"
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx27s::destroyNx27(nx27["uuid"])
                end
            end
        end
        if type == "url" then
            system("open '#{nx27["url"]}'")
        end
    end

    # Nx27s::landing(nxs7)
    def self.landing(nx27)
        loop {
            nx27 = Nx27s::getNx27ByIdOrNull(nx27["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx27.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts Nx27s::toString(nx27).green
            puts ""
            ListingEntityMapping::listings(nx27["uuid"]).each{|listing|
                mx.item(NxListings::toString(listing), lambda {
                    NxListings::landing(listing)
                })
            }
            puts ""
            mx.item("access".yellow, lambda {
                Nx27s::access(nx27)
            })
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(nx27["description"]).strip
                return if description == ""
                Nx27s::updateNx27TypeUniqueStringDescription(nx27["uuid"], description)
            })
            mx.item("add to listing".yellow, lambda {
                listing = NxListings::architectOneListingNx21OrNull()
                return if listing.nil?
                ListingEntityMapping::add(listing["uuid"], nx27["uuid"])
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx27s::destroyNx27(nx27["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Nx27s::nx19s()
    def self.nx19s()
        Nx27s::nx27s().map{|nx27|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{Nx27s::toString(nx27)}",
                "type"     => "Nx27",
                "payload"  => nx27
            }
        }
    end
end
