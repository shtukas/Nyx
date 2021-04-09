
# encoding: UTF-8

class Classification

    # Classification::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Classification.sqlite3"
    end

    # Classification::insertRecord(recordId, pointuuid, classificationValue)
    def self.insertRecord(recordId, pointuuid, classificationValue)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _recordId_=?", [recordId]
        db.execute "insert into _classifiers_ (_recordId_, _pointuuid_, _classificationValue_) values (?,?,?)", [recordId, pointuuid, classificationValue]
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
                "classificationValue" => row['_classificationValue_'],
            }
        end
        db.close
        answer
    end

    # Classification::getPointUUIDsPerClassificationValue(classificationValue)
    def self.getPointUUIDsPerClassificationValue(classificationValue)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_ where _classificationValue_=? ", [classificationValue]) do |row|
            answer << row['_pointuuid_']
        end
        db.close
        answer
    end

    # Classification::getPointsPerClassificationValue(classificationValue)
    def self.getPointsPerClassificationValue(classificationValue)
        Classification::getPointUUIDsPerClassificationValue(classificationValue)
            .map{|uuid| Elements::getElementOrNull(uuid) }
            .compact
    end

    # Classification::getDistinctClassificationValues()
    def self.getDistinctClassificationValues()
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select distinct(_classificationValue_) as _classificationValue_ from _classifiers_", []) do |row|
            answer << row['_classificationValue_']
        end
        db.close
        answer
    end

    # Classification::landing(classificationValue)
    def self.landing(classificationValue)

        loop {

            puts "-- Classification Value --------------------------"

            mx = LCoreMenuItemsNX1.new()
            
            puts classificationValue.green

            puts ""

            Classification::getPointsPerClassificationValue(classificationValue).each{|node|
                mx.item(Elements::toString(node["uuid"]), lambda { 
                    Elements::landing(node)
                })
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Classification::nx19s()
    def self.nx19s()
        Classification::getDistinctClassificationValues()
            .map{|classificationValue|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{classificationValue}",
                    "nx15"  => {
                        "type"    => "classificationValue",
                        "payload" => classificationValue
                    }
                }
            }
    end
end
