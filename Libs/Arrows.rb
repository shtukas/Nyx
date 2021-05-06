
# encoding: UTF-8

class Arrows
    # Arrows::databaseFilepath()
    def self.databaseFilepath()
        "#{Nodes::nyxFolderpath()}/arrows.sqlite3"
    end

    # Arrows::link(sourceId, targetId)
    def self.link(sourceId, targetId)
        raise "7bfcd6fa-a644-46c1-b6c8-03b428c6d0e8" if (sourceId == targetId)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _arrows_ where _sourceId_=? and _targetId_=?", [sourceId, targetId]
        db.execute "insert into _arrows_ (_sourceId_, _targetId_) values (?,?)", [sourceId, targetId]
        db.close
    end

    # Arrows::unlink(sourceId, targetId)
    def self.unlink(sourceId, targetId)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _arrows_ where _sourceId_=? and _targetId_=?", [sourceId, targetId]
        db.close
    end

    # -----------------------------------------

    # Arrows::parentsIds(targetId)
    def self.parentsIds(targetId)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _arrows_ where _targetId_=?" , [targetId] ) do |row|
            answer << row["_sourceId_"]
        end
        db.close
        answer.uniq
    end

    # Arrows::childrenIds(sourceId)
    def self.childrenIds(sourceId)
        db = SQLite3::Database.new(Arrows::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _arrows_ where _sourceId_=?" , [sourceId] ) do |row|
            answer << row["_targetId_"]
        end
        db.close
        answer.uniq
    end

    # -----------------------------------------

    # Arrows::parentsIds2(targetId)
    def self.parentsIds2(targetId)
        Arrows::parentsIds(targetId)
            .select{|id| Nodes::exists?(id) }
    end

    # Arrows::childrenIds2(sourceId)
    def self.childrenIds2(sourceId)
        Arrows::childrenIds(sourceId)
            .select{|id| Nodes::exists?(id) }
    end
end
