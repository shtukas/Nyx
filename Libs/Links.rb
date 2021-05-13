
# encoding: UTF-8

class Links

    # Links::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/links.sqlite3"
    end

    # Links::insert(uuid1, uuid2)
    def self.insert(uuid1, uuid2)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
        db.execute "delete from _links_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
        db.execute "insert into _links_ (_uuid1_, _uuid2_) values (?, ?)", [uuid1, uuid2]
        db.close
    end

    # Links::delete(uuid1, uuid2)
    def self.delete(uuid1, uuid2)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _uuid1_=? and _uuid2_=?", [uuid1, uuid2]
        db.execute "delete from _links_ where _uuid1_=? and _uuid2_=?", [uuid2, uuid1]
        db.close
    end

    # Links::uuids(uuid)
    def self.uuids(uuid)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _links_ where _uuid1_=?" , [uuid] ) do |row|
            answer << row["_uuid2_"]
        end
        db.execute( "select * from _links_ where _uuid2_=?" , [uuid] ) do |row|
            answer << row["_uuid1_"]
        end
        db.close
        answer.uniq
    end

    # Links::entities(uuid)
    def self.entities(uuid)
        Links::uuids(uuid)
            .map{|uuid| NxEntities::getEntityByIdOrNull(uuid) }
            .compact
    end
end
