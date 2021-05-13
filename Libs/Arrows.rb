
# encoding: UTF-8

class Arrows

    # Arrows::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/arrows.sqlite3"
    end

    # Arrows::insert(sourceuuid, targetuuid)
    def self.insert(sourceuuid, targetuuid)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _arrows_ where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.execute "insert into _arrows_ (_sourceuuid_, _targetuuid_) values (?, ?)", [sourceuuid, targetuuid]
        db.close
    end

    # Arrows::delete(sourceuuid, targetuuid)
    def self.delete(sourceuuid, targetuuid)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _arrows_ where _sourceuuid_=? and _targetuuid_=?", [sourceuuid, targetuuid]
        db.close
    end

    # Arrows::targetsuuids(sourceuuid)
    def self.targetsuuids(sourceuuid)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _arrows_ where _sourceuuid_=?" , [sourceuuid] ) do |row|
            answer << row["_targetuuid_"]
        end
        db.close
        answer.uniq
    end

    # Arrows::sourcesuuids(targetuuid)
    def self.sourcesuuids(targetuuid)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _arrows_ where _targetuuid_=?" , [targetuuid] ) do |row|
            answer << row["_sourceuuid_"]
        end
        db.close
        answer.uniq
    end

    # Arrows::childrenEntities(parentuuid)
    def self.childrenEntities(parentuuid)
        Arrows::targetsuuids(parentuuid)
            .map{|uuid| NxEntities::getEntityByIdOrNull(uuid) }
            .compact
    end

    # Arrows::parentsEntities(childuuid)
    def self.parentsEntities(childuuid)
        Arrows::sourcesuuids(childuuid)
            .map{|uuid| NxEntities::getEntityByIdOrNull(uuid) }
            .compact
    end
end
