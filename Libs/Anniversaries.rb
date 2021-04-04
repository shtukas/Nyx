
class Anniversaries

    # Anniversaries::dateIsCorrect(date)
    def self.dateIsCorrect(date)
        begin
            Date.parse(date)
            true
        rescue
            false
        end
    end

    # Anniversaries::datePlusNMonthAnniversaryStyle(date: String, shiftInMonths: Integer)
    def self.datePlusNMonthAnniversaryStyle(date, shiftInMonths)
        dateElements = [date[0, 4].to_i, date[5, 2].to_i+shiftInMonths, date[8, 2].to_i]

        while dateElements[1] > 12 do
            dateElements[0] = dateElements[0]+1
            dateElements[1] = dateElements[1] - 12
        end

        date = "#{dateElements[0]}-#{dateElements[1].to_s.rjust(2, "0")}-#{dateElements[2].to_s.rjust(2, "0")}"

        while !Anniversaries::dateIsCorrect(date) do
            date = "#{date[0, 4]}-#{date[5, 2]}-#{(date[8, 2].to_i-1).to_s.rjust(2, "0")}"
        end
        date
    end

    # Anniversaries::computeNextCelebrationDateOrdinal(startdate: String, repeatType: String, lastCelebrationDate: String) # [ date: String, ordinal: Int ]
    def self.computeNextCelebrationDateOrdinal(startdate, repeatType, lastCelebrationDate)
        cursordate = Date.parse(startdate)
        cursorOrdinal = 0
        if repeatType == "weekly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursordate = cursordate + 7
                cursorOrdinal = cursorOrdinal + 1
            }
        end
        if repeatType == "monthly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursorOrdinal = cursorOrdinal + 1
                cursordate = Date.parse(Anniversaries::datePlusNMonthAnniversaryStyle(startdate, cursorOrdinal))
            }
        end
        if repeatType == "yearly" then
            loop {
                if cursordate.to_s > lastCelebrationDate then
                    return [cursordate.to_s, cursorOrdinal]
                end
                cursorOrdinal = cursorOrdinal + 1
                cursordate = "#{startdate[0, 4].to_i+cursorOrdinal}-#{startdate[5, 2]}-#{startdate[8, 2]}"
                while !Anniversaries::dateIsCorrect(cursordate) do
                    cursordate = "#{cursordate[0, 4]}-#{cursordate[5, 2]}-#{(cursordate[8, 2].to_i-1).to_s.rjust(2, "0")}"
                end
            }
        end
    end

    # Anniversaries::runTests()
    def self.runTests()
        raise "72118532-21b3-4897-a6d1-7c21458b4624" if Anniversaries::datePlusNMonthAnniversaryStyle("2020-11-25", 1) != "2020-12-25"
        raise "279b1ee3-728e-4883-9a4d-abf3b9a494d7" if Anniversaries::datePlusNMonthAnniversaryStyle("2020-12-25", 1) != "2021-01-25"
        raise "5507b102-2651-4b57-ba7b-7e6c217bddba" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-01", 1) != "2021-02-01"
        raise "38e0536a-7943-4649-a002-6f65e9d88c0a" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 1) != "2021-02-28"
        raise "cd8feeec-54bd-4a63-be2c-e279c77390ba" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 2) != "2021-03-31"
        raise "d82394e7-708d-49a8-9d65-792a77093ce5" if Anniversaries::datePlusNMonthAnniversaryStyle("2021-01-31", 3) != "2021-04-30"
        raise "8bb58535-b435-4bbe-9ded-76cf5d1ce6ad" if Anniversaries::datePlusNMonthAnniversaryStyle("2024-01-31", 1) != "2024-02-29"
        raise "53ac9950-7df9-481d-a3cf-2ec07f566f89" if Anniversaries::datePlusNMonthAnniversaryStyle("2024-01-31", 2) != "2024-03-31"

        raise "ff1f70da-1342-4a20-91cb-f5a86f66a44c" if Anniversaries::computeNextCelebrationDateOrdinal("2021-02-28", "yearly", "2022-01-01").join(", ") != "2022-02-28, 1"
        raise "ff1f70da-1342-4a20-91cb-f5a86f66a44c" if Anniversaries::computeNextCelebrationDateOrdinal("2024-02-29", "yearly", "2025-01-01").join(", ") != "2025-02-28, 1"
    end

    # -----------------------------------------------------------

    # Anniversaries::databaseFilepath()
    def self.databaseFilepath()
        "#{CatalystUtils::catalystDataCenterFolderpath()}/Anniversaries.sqlite3"
    end

    # Anniversaries::insertRecord(uuid, startdate, repeatType, lastCelebrationDate, nereiduuid)
    def self.insertRecord(uuid, startdate, repeatType, lastCelebrationDate, nereiduuid)
        db = SQLite3::Database.new(Anniversaries::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction
        db.execute "delete from _anniversaries_ where _uuid_=?", [uuid]
        db.execute "insert into _anniversaries_ (_uuid_, _startdate_, _repeatType_, _lastCelebrationDate_, _nereiduuid_) values (?,?,?,?,?)", [uuid, startdate, repeatType, lastCelebrationDate, nereiduuid]
        db.commit
        db.close
        nil
    end

    # Anniversaries::insertItem(item)
    def self.insertItem(item)
        Anniversaries::insertRecord(item["uuid"], item["startdate"], item["repeatType"], item["lastCelebrationDate"], item["nereiduuid"])
    end

    # Anniversaries::getItemByUUID(uuid)
    def self.getItemByUUID(uuid)
        db = SQLite3::Database.new(Anniversaries::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _anniversaries_ where _uuid_=?", [uuid] ) do |row|
            answer = {
                "uuid"       => row['_uuid_'],
                "startdate"  => row['_startdate_'],
                "repeatType" => row['_repeatType_'],
                "lastCelebrationDate" => row['_lastCelebrationDate_'],
                "nereiduuid" => row['_nereiduuid_']
            }
        end
        db.close
        answer
    end

    # Anniversaries::getItems()
    def self.getItems()
        db = SQLite3::Database.new(Anniversaries::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _anniversaries_", [] ) do |row|
            answer << {
                "uuid"       => row['_uuid_'],
                "startdate"  => row['_startdate_'],
                "repeatType" => row['_repeatType_'],
                "lastCelebrationDate" => row['_lastCelebrationDate_'],
                "nereiduuid" => row['_nereiduuid_']
            }
        end
        db.close
        answer
    end

    # Anniversaries::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(Anniversaries::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction
        db.execute "delete from _anniversaries_ where _uuid_=?", [uuid]
        db.commit
        db.close
        nil
    end

    # ----------------------------------------------------------------------------------

    # Anniversaries::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        element = NereidInterface::interactivelyIssueNewElementOrNull()
        return if element.nil?

        startdate = LucilleCore::askQuestionAnswerAsString("startdate: ")
        return nil if startdate == ""

        repeatType = LucilleCore::selectEntityFromListOfEntitiesOrNull("repeat type", ["weekly", "monthly", "yearly"])
        return nil if repeatType.nil?

        lastCelebrationDate = LucilleCore::askQuestionAnswerAsString("lastCelebrationDate (default to today): ")
        if lastCelebrationDate == "" then
            lastCelebrationDate = CatalystUtils::today()
        end

        item = {
            "uuid"                => SecureRandom.hex,
            "startdate"           => startdate,
            "repeatType"          => repeatType,
            "lastCelebrationDate" => lastCelebrationDate,
            "nereiduuid"          => element["uuid"]
        }        

        Anniversaries::insertItem(item)

        item
    end

    # Anniversaries::itemNextDateOrdinal(item) # [ date: String, ordinal: Int ]
    def self.itemNextDateOrdinal(item)
        Anniversaries::computeNextCelebrationDateOrdinal(item["startdate"], item["repeatType"], item["lastCelebrationDate"])
    end

    # Anniversaries::toString(item)
    def self.toString(item)
        "[anniversary] [#{Anniversaries::itemNextDateOrdinal(item).join(", ")}] #{NereidInterface::toString(item["nereiduuid"])} (#{item["repeatType"]} since #{item["startdate"]})"
    end

    # Anniversaries::ns16s()
    def self.ns16s()
        Anniversaries::getItems()
            .select{|item| Anniversaries::itemNextDateOrdinal(item)[0] <= CatalystUtils::today() }
            .map{|item|
                {
                    "uuid"     => item["uuid"],
                    "announce" => Anniversaries::toString(item),
                    "lambda"   => lambda{
                        puts Anniversaries::toString(item).green
                        if LucilleCore::askQuestionAnswerAsBoolean("done ? : ") then
                            item["lastCelebrationDate"] = Time.new.to_s[0, 10]
                            Anniversaries::insertItem(item)
                        end
                    }
                }
            }
            .sort{|i1, i2| i1["announce"]<=>i2["announce"] }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Anniversaries::dailyBriefing()
    def self.dailyBriefing()
        system("clear")
        puts "Anniversaries daily briefing"
        Anniversaries::getItems()
            .sort{|i1, i2| Anniversaries::itemNextDateOrdinal(i1)[0] <=> Anniversaries::itemNextDateOrdinal(i2)[0] }
            .each{|item|
                puts Anniversaries::toString(item)
            }
        LucilleCore::pressEnterToContinue()
    end

    # Anniversaries::dailyBriefingIfNotDoneToday()
    def self.dailyBriefingIfNotDoneToday()
        if !KeyValueStore::flagIsTrue(nil, "9140133b-4189-4c5f-b85f-8b3c9a77e0c2:#{CatalystUtils::today()}") then
            Anniversaries::dailyBriefing()
            KeyValueStore::setFlagTrue(nil, "9140133b-4189-4c5f-b85f-8b3c9a77e0c2:#{CatalystUtils::today()}")
        end
    end

    # Anniversaries::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            item = Anniversaries::getItemByUUID(item["uuid"]) # to get the current version
            return if item.nil?
            puts Anniversaries::toString(item).green
            mx = LCoreMenuItemsNX1.new()
            mx.item("update start date".yellow, lambda { 
                startdate = LucilleCore::askQuestionAnswerAsString("start date: ")
                return if startdate == ""
                item["startdate"] = startdate
                Anniversaries::insertItem(item)
            })
            mx.item("destroy".yellow, lambda { 
                Anniversaries::destroy(item["uuid"])
            })
            status = mx.promptAndRunSandbox()
            break if !status            
        }
    end

    # Anniversaries::anniversariesDive()
    def self.anniversariesDive()
        loop {
            items = Anniversaries::getItems()
                        .sort{|i1, i2| Anniversaries::itemNextDateOrdinal(i1)[0] <=> Anniversaries::itemNextDateOrdinal(i2)[0] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Anniversaries::toString(item) })
            return if item.nil?
            Anniversaries::landing(item)
        }
    end

    # Anniversaries::main()
    def self.main()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            mx.item("dive into anniversary items".yellow, lambda { 
                Anniversaries::anniversariesDive()
            })
            mx.item("make new anniversary item".yellow, lambda { 
                Anniversaries::interactivelyIssueNewItemOrNull()
            })
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end