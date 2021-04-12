
# encoding: UTF-8

class Tags

    # -------------------------------------------------------------------------

    # Tags::databasePath()
    def self.databasePath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Tags.sqlite3"
    end

    # Tags::commitRecord(recordId, pointuuid, tag)
    def self.commitRecord(recordId, pointuuid, tag)
        db = SQLite3::Database.new(Tags::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _recordId_=?", [recordId]
        db.execute "insert into _classifiers_ (_recordId_, _pointuuid_, _classificationValue_) values (?,?,?)", [recordId, pointuuid, tag]
        db.commit 
        db.close
    end

    # Tags::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new(Tags::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_", []) do |row|
            answer << {
                "recordId"       => row['_recordId_'],
                "pointuuid"      => row['_pointuuid_'],
                "tag" => row['_classificationValue_'],
            }
        end
        db.close
        answer
    end

    # Tags::getDistinctTags()
    def self.getDistinctTags()
        db = SQLite3::Database.new(Tags::databasePath())
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

    # Tags::deleteRecordsByPointUUIDAndTag(pointuuid, tag)
    def self.deleteRecordsByPointUUIDAndTag(pointuuid, tag)
        db = SQLite3::Database.new(Tags::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _classifiers_ where _pointuuid_=? and _classificationValue_=?", [pointuuid, tag]
        db.commit 
        db.close
    end

    # -------------------------------------------------------------------------

    # Tags::tagToPointUUIDs(tag)
    def self.tagToPointUUIDs(tag)
        db = SQLite3::Database.new(Tags::databasePath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _classifiers_ where _classificationValue_=? ", [tag]) do |row|
            answer << row['_pointuuid_']
        end
        db.close
        answer
    end

    # Tags::tagToNxPods(tag)
    def self.tagToNxPods(tag)
        Tags::tagToPointUUIDs(tag)
            .map{|uuid| NxPods::getNxPodOrNull(uuid) }
            .compact
    end

    # Tags::pointUUIDToTags(pointuuid)
    def self.pointUUIDToTags(pointuuid)
        db = SQLite3::Database.new(Tags::databasePath())
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

    # Tags::selectExistingTagOrNull()
    def self.selectExistingTagOrNull()
        Utils::selectLineOrNullUsingInteractiveInterface(Tags::getDistinctTags())
    end

    # Tags::architectureTagOrNull()
    def self.architectureTagOrNull()
        value = Tags::selectExistingTagOrNull()
        return value if value

        value = LucilleCore::askQuestionAnswerAsString("new classification value: ")
        return value if value

        nil
    end

    # TagselectExistingTagOrNulls::renameTag(oldvalue, newvalue)
    def self.renameTag(oldvalue, newvalue)
        Tags::getRecords()
            .select{|record|
                record["tag"] == oldvalue
            }
            .each{|record|
                Tags::commitRecord(record["recordId"], record["pointuuid"], newvalue)
            }
    end

    # -------------------------------------------------------------------------

    # Tags::landing(tag)
    def self.landing(tag)

        loop {

            puts "-- Classification Value --------------------------"

            mx = LCoreMenuItemsNX1.new()
            
            puts tag.green

            puts ""

            mx.item("rename".yellow, lambda {
                newvalue = Utils::editTextSynchronously(tag)
                return if newvalue == ""
                Tags::renameTag(tag, newvalue)
            })

            puts ""

            Tags::tagToNxPods(tag).each{|nxpod|
                mx.item(NxPods::toString(nxpod), lambda { 
                    NxPods::landing(nxpod)
                })
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Tags::sx19s()
    def self.sx19s()
        Tags::getDistinctTags()
            .map{|tag|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} [***] #{tag}",
                    "sx15"  => {
                        "type"    => "tag",
                        "payload" => tag
                    }
                }
            }
    end
end
