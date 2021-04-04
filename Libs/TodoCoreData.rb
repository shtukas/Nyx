

class TodoCoreData

    # TodoCoreData::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/NS-Core-Objects.sqlite3"
    end

    # TodoCoreData::getAllObjects()
    def self.getAllObjects()
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from table2" , [] ) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # TodoCoreData::put(object)
    def self.put(object)
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into table2 (_setuuid_, _objectuuid_, _object_) values (?,?,?)", [object["nyxNxSet"], object["uuid"], JSON.generate(object)]
        db.commit 
        db.close
    end

    # TodoCoreData::getOrNull(uuid)
    def self.getOrNull(uuid)
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from table2 where _objectuuid_=?" , [uuid] ) do |row|
            answer = JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # TodoCoreData::getSet(setid)
    def self.getSet(setid)
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from table2 where _setuuid_=?" , [setid]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # TodoCoreData::destroy(object)
    def self.destroy(object)
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.close

        message = object["uuid"]
        Mercury::postValue("0437d73d-9cde-4b96-99c5-5bd44671d267", message)
    end
end
