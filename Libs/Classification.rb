
# encoding: UTF-8

class Classification

    # Classification::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Classification.sqlite3"
    end

    # Classification::insertRecord(recordId, pointuuid, attributeValue)
    def self.insertRecord(recordId, pointuuid, attributeValue)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _recordId_=?", [recordId]
        db.execute "insert into _classifiers_ (_recordId_, _pointuuid_, _attributeValue_) values (?,?,?)", [recordId, pointuuid, attributeValue]
        db.commit 
        db.close
    end

    # Classification::getRecordByRecordIdOrNull(recordId)
    def self.getRecordByRecordIdOrNull(recordId)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _classifiers_", []) do |row|
            answer = {
                "recordId"       => row['_recordId_'],
                "pointuuid"      => row['_pointuuid_'],
                "attributeValue" => row['_attributeValue_'],
            }
        end
        db.close
        answer
    end

    # Classification::getPointUUIDsPerAttributeValue(attributeValue)
    def self.getPointUUIDsPerAttributeValue(attributeValue)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_ where _attributeValue_=? ", [attributeValue]) do |row|
            answer << row['_pointuuid_']
        end
        db.close
        answer
    end
end
