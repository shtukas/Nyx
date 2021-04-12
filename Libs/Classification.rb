
# encoding: UTF-8

class Classification

    # -------------------------------------------------------------------------

    # Classification::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Classification.sqlite3"
    end

    # Classification::commitRecord(recordId, pointuuid, classificationValue)
    def self.commitRecord(recordId, pointuuid, classificationValue)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _recordId_=?", [recordId]
        db.execute "insert into _classifiers_ (_recordId_, _pointuuid_, _classificationValue_) values (?,?,?)", [recordId, pointuuid, classificationValue]
        db.commit 
        db.close
    end

    # Classification::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_", []) do |row|
            answer << {
                "recordId"       => row['_recordId_'],
                "pointuuid"      => row['_pointuuid_'],
                "classificationValue" => row['_classificationValue_'],
            }
        end
        db.close
        answer
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

    # Classification::deleteRecordsByPointUUIDAndClassificationValue(pointuuid, classificationValue)
    def self.deleteRecordsByPointUUIDAndClassificationValue(pointuuid, classificationValue)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _pointuuid_=? and _classificationValue_=?", [pointuuid, classificationValue]
        db.commit 
        db.close
    end

    # -------------------------------------------------------------------------

    # Classification::classificationValueToPointUUIDs(classificationValue)
    def self.classificationValueToPointUUIDs(classificationValue)
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

    # Classification::classificationValueToQuarks(classificationValue)
    def self.classificationValueToQuarks(classificationValue)
        Classification::classificationValueToPointUUIDs(classificationValue)
            .map{|uuid| Quarks::getQuarkOrNull(uuid) }
            .compact
    end

    # Classification::pointUUIDToClassificationValues(pointuuid)
    def self.pointUUIDToClassificationValues(pointuuid)
        db = SQLite3::Database.new(Classification::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select distinct(_classificationValue_) as _classificationValue_ from _classifiers_ where _pointuuid_=? ", [pointuuid]) do |row|
            answer << row['_classificationValue_']
        end
        db.close
        answer
    end

    # -------------------------------------------------------------------------

    # Classification::selectClassificationValueOrNull()
    def self.selectClassificationValueOrNull()
        Utils::selectLineOrNullUsingInteractiveInterface(Classification::getDistinctClassificationValues())
    end

    # Classification::architectureClassificationValueOrNull()
    def self.architectureClassificationValueOrNull()
        value = Classification::selectClassificationValueOrNull()
        return value if value

        value = LucilleCore::askQuestionAnswerAsString("new classification value: ")
        return value if value

        nil
    end

    # Classification::renameClassificationValue(oldvalue, newvalue)
    def self.renameClassificationValue(oldvalue, newvalue)
        Classification::getRecords()
            .select{|record|
                record["classificationValue"] == oldvalue
            }
            .each{|record|
                Classification::commitRecord(record["recordId"], record["pointuuid"], newvalue)
            }
    end

    # -------------------------------------------------------------------------

    # Classification::landing(classificationValue)
    def self.landing(classificationValue)

        loop {

            puts "-- Classification Value --------------------------"

            mx = LCoreMenuItemsNX1.new()
            
            puts classificationValue.green

            puts ""

            mx.item("rename".yellow, lambda {
                newvalue = Utils::editTextSynchronously(classificationValue)
                return if newvalue == ""
                Classification::renameClassificationValue(classificationValue, newvalue)
            })

            puts ""

            Classification::classificationValueToQuarks(classificationValue).each{|quark|
                mx.item(Quarks::toString(quark), lambda { 
                    Quarks::landing(quark)
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
                    "announce" => "#{volatileuuid} [***] #{classificationValue}",
                    "nx15"  => {
                        "type"    => "classificationValue",
                        "payload" => classificationValue
                    }
                }
            }
    end
end
