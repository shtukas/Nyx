
# encoding: UTF-8

class Nx27s

    # Nx27s::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/Nx27s.sqlite3"
    end

    # Nx27s::createNewEntry(recorduuid, listinguuid, datetime, description, uniquestring)
    def self.createNewEntry(recorduuid, listinguuid, datetime, description, uniquestring)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx27s_ (_recorduuid_, _listinguuid_, _datetime_, _description_, _uniquestring_) values (?,?,?,?,?)", [recorduuid, listinguuid, datetime, description, uniquestring]
        db.close
    end

    # Nx27s::destroyEntry(recorduuid)
    def self.destroyEntry(recorduuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx27s_ where _recorduuid_=?", [recorduuid]
        db.close
    end

    # Nx27s::interactivelyCreateNewEntryOrNull()
    def self.interactivelyCreateNewEntryOrNull()
        recorduuid = SecureRandom.uuid
        nx21 = NxListings::selectOneListingNx21OrNull()
        return nil if nx21.nil?
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
        return nil if uniquestring == ""
        datetime = Time.new.utc.iso8601
        Nx27s::createNewEntry(recorduuid, nx21["uuid"], datetime, description, uniquestring)
        {
            "recorduuid"   => recorduuid,
            "listinguuid"  => nx21["uuid"],
            "datetime"     => datetime,
            "description"  => description,
            "uniquestring" => uniquestring,
        }
    end

    # Nx27s::entries(): Array[Nx27]
    def self.entries()
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx27s_" , [] ) do |row|
            answer << {
                "recorduuid"   => row["_recorduuid_"],
                "listinguuid"  => row["_listinguuid_"],
                "datetime"     => row["_datetime_"],
                "description"  => row["_description_"],
                "uniquestring" => row["_uniquestring_"],
            }
        end
        db.close
        answer
    end

    # Nx27s::getEntriesForListingOrdered(listinguuid): Array[Nx21]
    def self.getEntriesForListingOrdered(listinguuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx27s_ where _listinguuid_=? order by _datetime_" , [listinguuid] ) do |row|
            answer << {
                "recorduuid"   => row["_recorduuid_"],
                "listinguuid"  => row["_listinguuid_"],
                "datetime"     => row["_datetime_"],
                "description"  => row["_description_"],
                "uniquestring" => row["_uniquestring_"],
            }
        end
        db.close
        answer
    end

    # Nx27s::getEntryByRecordIdOrNull(recorduuid): null or Nx21
    def self.getEntryByRecordIdOrNull(recorduuid)
        db = SQLite3::Database.new(Nx27s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx27s_ where _recorduuid_=?" , [recorduuid] ) do |row|
            answer = {
                "recorduuid"   => row["_recorduuid_"],
                "listinguuid"  => row["_listinguuid_"],
                "datetime"     => row["_datetime_"],
                "description"  => row["_description_"],
                "uniquestring" => row["_uniquestring_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # Nx27s::recordIds()
    def self.recordIds()
        Nx27s::entries().map{|item| item["recorduuid"] }
    end

    # Nx27s::toString(nx27)
    def self.toString(nx27)
        "[entry] #{nx27["description"]}"
    end

    # Nx27s::landing(nxs7)
    def self.landing(nx27)
        puts "Landing on a Nx27 [not yet implemented]"
        LucilleCore::pressEnterToContinue()
    end

    # Nx27s::nx19s()
    def self.nx19s()
        Nx27s::entries().map{|nx27|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} [entry] #{nx27["description"]}",
                "type"     => "Nx27",
                "payload"  => nx27
            }
        }
    end
end
