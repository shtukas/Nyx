
class Calendar

    # Calendar::databaseFilepath()
    def self.databaseFilepath()
        "#{CatalystUtils::catalystDataCenterFolderpath()}/Calendar-Items.sqlite3"
    end

    # Calendar::insertRecord(uuid, date, nereiduuid)
    def self.insertRecord(uuid, date, nereiduuid)
        db = SQLite3::Database.new(Calendar::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction
        db.execute "delete from _calendaritems_ where _uuid_=?", [uuid]
        db.execute "insert into _calendaritems_ (_uuid_, _date_, _nereiduuid_) values (?,?,?)", [uuid, date, nereiduuid]
        db.commit
        db.close
        nil
    end

    # Calendar::getItemByUUID(uuid)
    def self.getItemByUUID(uuid)
        db = SQLite3::Database.new(Calendar::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _calendaritems_ where _uuid_=?", [uuid] ) do |row|
            answer = {
                "uuid"       => row['_uuid_'],
                "date"       => row['_date_'],
                "nereiduuid" => row['_nereiduuid_']
            }
        end
        db.close
        answer
    end

    # Calendar::getCalendarItems()
    def self.getCalendarItems()
        db = SQLite3::Database.new(Calendar::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _calendaritems_ order by _date_", [] ) do |row|
            answer << {
                "uuid"       => row['_uuid_'],
                "date"       => row['_date_'],
                "nereiduuid" => row['_nereiduuid_']
            }
        end
        db.close
        answer
    end

    # Calendar::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Calendar::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction
        db.execute "delete from _calendaritems_ where _uuid_=?", [uuid]
        db.commit
        db.close
        nil
    end

    # -----------------------------------------------------------

    # Calendar::interactivelyIssueNewCalendarItemOrNull()
    def self.interactivelyIssueNewCalendarItemOrNull()
        element = NereidInterface::interactivelyIssueNewElementOrNull()
        return if element.nil?
        date = LucilleCore::askQuestionAnswerAsString("date: ")
        uuid = SecureRandom.hex
        Calendar::insertRecord(uuid, date, element["uuid"])
        Calendar::getItemByUUID(uuid)
    end

    # Calendar::toString(item)
    def self.toString(item)
        "[calendar] #{item["date"]} #{NereidInterface::toString(item["nereiduuid"])}"
    end

    # Calendar::ns16s()
    def self.ns16s()
        Calendar::getCalendarItems()
            .select{|item| item["date"] <= CatalystUtils::today() }
            .sort{|i1, i2| i1["date"]<=>i2["date"] }
            .map{|item|
                {
                    "uuid"     => item["uuid"],
                    "announce" => Calendar::toString(item),
                    "lambda"   => lambda{
                        puts Calendar::toString(item).green
                        if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                            Calendar::destroy(item["uuid"])
                        end
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Calendar::landing(item)
    def self.landing(item)
        loop {
            system("clear")

            return if Calendar::getItemByUUID(item["uuid"]).nil?
            item = Calendar::getItemByUUID(item["uuid"]) # could have been transmuted in the previous loop

            mx = LCoreMenuItemsNX1.new()
            puts Calendar::toString(item).green
            mx.item("data carrier landing".yellow, lambda { 
                NereidInterface::landing(item["nereiduuid"])
            })
            mx.item("update date".yellow, lambda { 
                date = LucilleCore::askQuestionAnswerAsString("date: ")
                Calendar::insertRecord(item["uuid"], date, item["nereiduuid"])
            })
            mx.item("destroy".yellow, lambda { 
                Calendar::destroy(item["uuid"])
            })
            status = mx.promptAndRunSandbox()
            break if !status
        }        
    end

    # Calendar::dailyBriefing()
    def self.dailyBriefing()
        system("clear")
        puts "Calendar daily briefing"
        Calendar::getCalendarItems()
            .sort{|i1, i2| i1["date"]<=>i2["date"] }
            .each{|item|
                puts Calendar::toString(item)
            }
        LucilleCore::pressEnterToContinue()
    end

    # Calendar::dailyBriefingIfNotDoneToday()
    def self.dailyBriefingIfNotDoneToday()
        if !KeyValueStore::flagIsTrue(nil, "ba0eb2ee-6003-457e-9379-4a7ad2af7fc3:#{CatalystUtils::today()}") then
            Calendar::dailyBriefing()
            KeyValueStore::setFlagTrue(nil, "ba0eb2ee-6003-457e-9379-4a7ad2af7fc3:#{CatalystUtils::today()}")
        end
    end

    # Calendar::diveCalendarItems()
    def self.diveCalendarItems()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Calendar::getCalendarItems()
                .each{|item|
                    mx.item(Calendar::toString(item), lambda {
                        Calendar::landing(item)
                    })
                }
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Calendar::main()
    def self.main()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            mx.item("dive into calendar".yellow, lambda { 
                Calendar::diveCalendarItems()
            })
            mx.item("make new calendar item".yellow, lambda { 
                Calendar::interactivelyIssueNewCalendarItemOrNull() 
            })
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
