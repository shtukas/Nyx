
# encoding: UTF-8

class Nx27s

    # Nx27s::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/Nx27s.sqlite3"
    end

    # Nx27s::createNewNx27TypeUniqueString(recorduuid, listinguuid, datetime, description, uniquestring)
    def self.createNewNx27TypeUniqueString(recorduuid, listinguuid, datetime, description, uniquestring)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx27s_ (_recorduuid_, _listinguuid_, _datetime_, _type_, _payload1_, _payload2_) values (?,?,?,?,?,?)", [recorduuid, listinguuid, datetime, "unique-string", description, uniquestring]
        db.close
    end

    # Nx27s::createNewNx27TypeListing(recorduuid, listinguuid, datetime, luuid)
    def self.createNewNx27TypeListing(recorduuid, listinguuid, datetime, luuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx27s_ (_recorduuid_, _listinguuid_, _datetime_, _type_, _payload1_) values (?,?,?,?,?)", [recorduuid, listinguuid, datetime, "listing", luuid]
        db.close
    end

    # Nx27s::destroyNx27(recorduuid)
    def self.destroyNx27(recorduuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx27s_ where _recorduuid_=?", [recorduuid]
        db.close
    end

    # Nx27s::interactivelyCreateNewNx27OrNull()
    def self.interactivelyCreateNewNx27OrNull()
        recorduuid = SecureRandom.uuid

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["unique-string", "listing"])
        return nil if type.nil?

        if type == "unique-string" then
            nx21 = NxListings::architectOneListingNx21OrNull()
            return nil if nx21.nil?
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return nil if uniquestring == ""
            datetime = Time.new.utc.iso8601
            Nx27s::createNewNx27TypeUniqueString(recorduuid, nx21["uuid"], datetime, description, uniquestring)
            return {
                "recorduuid"   => recorduuid,
                "listinguuid"  => nx21["uuid"],
                "datetime"     => datetime,
                "type"         => "unique-string",
                "description"  => description,
                "uniquestring" => uniquestring,
            }
        end
        if type == "listing" then
            puts "We are going to architect the parent listing and then the child one"
            nx21p = NxListings::architectOneListingNx21OrNull()
            return nil if nx21p.nil?
            nx21c = NxListings::architectOneListingNx21OrNull()
            return nil if nx21c.nil?
            datetime = Time.new.utc.iso8601
            Nx27s::createNewNx27TypeListing(recorduuid, nx21p["uuid"], datetime, nx21c["uuid"])
            return {
                "recorduuid"   => recorduuid,
                "listinguuid"  => nx21p["uuid"],
                "datetime"     => datetime,
                "type"         => "listing",
                "luuid"        => nx21c["uuid"],
            }
        end
    end

    # Nx27s::interactivelyCreateNewNx27GivenParentListingOrNull(nx21)
    def self.interactivelyCreateNewNx27GivenParentListingOrNull(nx21)
        recorduuid = SecureRandom.uuid

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["unique-string", "listing"])
        return nil if type.nil?

        if type == "unique-string" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
            return nil if uniquestring == ""
            datetime = Time.new.utc.iso8601
            Nx27s::createNewNx27TypeUniqueString(recorduuid, nx21["uuid"], datetime, description, uniquestring)
            return {
                "recorduuid"   => recorduuid,
                "listinguuid"  => nx21["uuid"],
                "datetime"     => datetime,
                "type"         => "unique-string",
                "description"  => description,
                "uniquestring" => uniquestring,
            }
        end
        if type == "listing" then
            nx21c = NxListings::architectOneListingNx21OrNull()
            return nil if nx21c.nil?
            datetime = Time.new.utc.iso8601
            Nx27s::createNewNx27TypeListing(recorduuid, nx21["uuid"], datetime, nx21c["uuid"])
            return {
                "recorduuid"   => recorduuid,
                "listinguuid"  => nx21["uuid"],
                "datetime"     => datetime,
                "type"         => "listing",
                "luuid"        => nx21c["uuid"],
            }
        end
    end

    # Nx27s::entries(): Array[Nx27]
    def self.entries()
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx27s_" , [] ) do |row|
            if row["_type_"] == "unique-string" then
                answer << {
                    "recorduuid"   => row["_recorduuid_"],
                    "listinguuid"  => row["_listinguuid_"],
                    "datetime"     => row["_datetime_"],
                    "type"         => "unique-string",
                    "description"  => row["_payload1_"],
                    "uniquestring" => row["_payload2_"],
                }
            end
            if row["_type_"] == "listing" then
                answer << {
                    "recorduuid"   => row["_recorduuid_"],
                    "listinguuid"  => row["_listinguuid_"],
                    "datetime"     => row["_datetime_"],
                    "type"         => "listing",
                    "luuid"        => row["_payload1_"],
                }
            end
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
            if row["_type_"] == "unique-string" then
                answer << {
                    "recorduuid"   => row["_recorduuid_"],
                    "listinguuid"  => row["_listinguuid_"],
                    "datetime"     => row["_datetime_"],
                    "type"         => "unique-string",
                    "description"  => row["_payload1_"],
                    "uniquestring" => row["_payload2_"],
                }
            end
            if row["_type_"] == "listing" then
                answer << {
                    "recorduuid"   => row["_recorduuid_"],
                    "listinguuid"  => row["_listinguuid_"],
                    "datetime"     => row["_datetime_"],
                    "type"         => "listing",
                    "luuid"        => row["_payload1_"],
                }
            end
        end
        db.close
        answer
    end

    # Nx27s::getNx27ByRecordIdOrNull(recorduuid): null or Nx21
    def self.getNx27ByRecordIdOrNull(recorduuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx27s_ where _recorduuid_=?" , [recorduuid] ) do |row|
            if row["_type_"] == "unique-string" then
                answer = {
                    "recorduuid"   => row["_recorduuid_"],
                    "listinguuid"  => row["_listinguuid_"],
                    "datetime"     => row["_datetime_"],
                    "type"         => "unique-string",
                    "description"  => row["_payload1_"],
                    "uniquestring" => row["_payload2_"],
                }
            end
            if row["_type_"] == "listing" then
                answer = {
                    "recorduuid"   => row["_recorduuid_"],
                    "listinguuid"  => row["_listinguuid_"],
                    "datetime"     => row["_datetime_"],
                    "type"         => "listing",
                    "luuid"        => row["_payload1_"],
                }
            end
        end
        db.close
        answer
    end

    # Nx27s::updateNx27TypeUniqueStringDescription(recorduuid, description)
    def self.updateNx27TypeUniqueStringDescription(recorduuid, description)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx27s_ set _description_=? where _recorduuid_=?", [description, recorduuid]
        db.close
    end

    # ----------------------------------------------------------------------

    # Nx27s::recordIds()
    def self.recordIds()
        Nx27s::entries().map{|item| item["recorduuid"] }
    end

    # Nx27s::toString(nx27)
    def self.toString(nx27)
        if nx27["type"] == "unique-string" then
            return "[entry  ] #{nx27["description"]}"
        end
        if nx27["type"] == "listing" then
            luuid = nx27["luuid"]
            nx21 = NxListings::getListingByIdOrNull(luuid)
            if nx21 then
                return "[listing] #{nx21["description"]}"
            else
                return "[listing] no listing found for luuid: #{luuid}"
            end
        end
    end

    # Nx27s::landing(nxs7)
    def self.landing(nx27)
        loop {
            nx27 = Nx27s::getNx27ByRecordIdOrNull(nx27["recorduuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx27.nil?
            system("clear")
            puts Nx27s::toString(nx27).green
            puts ""
            mx = LCoreMenuItemsNX1.new()
            mx.item("access".yellow, lambda {
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
                        Nx27s::destroyNx27(nx27["recorduuid"])
                    end
                end
            })
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(nx27["description"]).strip
                return if description == ""
                Nx27s::updateNx27TypeUniqueStringDescription(nx27["recorduuid"], description)
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx27s::destroyNx27(nx27["recorduuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Nx27s::nx19s()
    def self.nx19s()
        Nx27s::entries().map{|nx27|
            volatileuuid = SecureRandom.hex[0, 8]
            if nx27["type"] == "unique-string" then
                nx19 = {
                    "announce" => "#{volatileuuid} [entry] #{nx27["description"]}",
                    "type"     => "Nx27",
                    "payload"  => nx27
                }
            end
            if nx27["type"] == "listing" then
                luuid = nx27["luuid"]
                nx21 = NxListings::getListingByIdOrNull(luuid)
                if nx21 then
                    nx19 = {
                        "announce" => "#{volatileuuid} [listing] #{nx21["description"]}",
                        "type"     => "NxListing",
                        "payload"  => nx21
                    }
                else
                    nx19 = nil
                end
            end

            nx19
        }.compact
    end
end
