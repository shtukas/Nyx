
# encoding: UTF-8

class Links
    # Links::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/links.sqlite3"
    end

    # Links::link(id1, id2)
    def self.link(id1, id2)
        raise "bb72559d-304e-4155-951d-272ce30315b4" if (id1 == id2)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _id1_=? and _id2_=?", [id1, id2]
        db.execute "delete from _links_ where _id1_=? and _id2_=?", [id2, id1]
        db.execute "insert into _links_ (_id1_, _id2_) values (?,?)", [id1, id2]
        db.close
    end

    # Links::unlink(id1, id2)
    def self.unlink(id1, id2)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _links_ where _id1_=? and _id2_=?", [id1, id2]
        db.execute "delete from _links_ where _id1_=? and _id2_=?", [id2, id1]
        db.close
    end

    # -----------------------------------------

    # Links::linkedIds(id)
    def self.linkedIds(id)
        db = SQLite3::Database.new(Links::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _links_ where _id2_=?" , [id] ) do |row|
            answer << row["_id1_"]
        end
        db.execute( "select * from _links_ where _id1_=?" , [id] ) do |row|
            answer << row["_id2_"]
        end
        db.close
        answer.uniq
    end

    # -----------------------------------------

    # Links::linkedIds2(id)
    def self.linkedIds2(id)
        Links::linkedIds(id)
            .select{|idx| Nodes::exists?(idx) }
    end
end
