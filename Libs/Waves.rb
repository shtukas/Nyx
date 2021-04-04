
# encoding: UTF-8

class Waves

    # Waves::traceToRealInUnitInterval(trace)
    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    # Waves::traceToMetricShift(trace)
    def self.traceToMetricShift(trace)
        0.001*Waves::traceToRealInUnitInterval(trace)
    end

    # Waves::makeScheduleObjectInteractivelyOrNull()
    def self.makeScheduleObjectInteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntitiesOrNull("schedule type: ", scheduleTypes, lambda{|entity| entity })

        schedule = nil
        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            schedule = {
                "uuid"      => SecureRandom.hex,
                "@"         => "sticky",
                "from-hour" => fromHour
            }
        end
        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
            end
            schedule = {
                "uuid" => SecureRandom.hex,
                "@"    => type,
                "repeat-value" => value
            }
        end
        schedule
    end

    # Waves::unixtimeAtComingMidnight()
    def self.unixtimeAtComingMidnight()
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00").to_time.to_i
    end

    # Waves::scheduleToDoNotShowUnixtime(schedule)
    def self.scheduleToDoNotShowUnixtime(schedule)
        if schedule['@'] == 'sticky' then
            return Waves::unixtimeAtComingMidnight() + 6*3600
        end
        if schedule['@'] == 'every-n-hours' then
            return Time.new.to_i+3600 * schedule['repeat-value'].to_f
        end
        if schedule['@'] == 'every-n-days' then
            return Time.new.to_i+86400 * schedule['repeat-value'].to_f
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != schedule['repeat-value'] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != schedule['repeat-value'] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleToString(schedule)
    def self.scheduleToString(schedule)
        if schedule['@'] == 'sticky' then
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return "sticky, from: #{schedule['from-hour']}"
        end
        if schedule['@'] == 'every-n-hours' then
            return "every-n-hours #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-n-days' then
            return "every-n-days #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            return "every-this-day-of-the-month: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            return "every-this-day-of-the-week: #{schedule['repeat-value']}"
        end
        JSON.generate(schedule)
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        wave["lastDoneDateTime"] = Time.now.utc.iso8601
        TodoCoreData::put(wave)
        unixtime = Waves::scheduleToDoNotShowUnixtime(wave['schedule'])
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
    end

    # Waves::issueWave(uuid, element, schedule)
    def self.issueWave(uuid, element, schedule)
        wave = {
            "uuid"       => uuid,
            "nyxNxSet"   => "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4",
            "unixtime"   => Time.new.to_f,
            "nereiduuid" => element["uuid"],
            "schedule"   => schedule
        }
        TodoCoreData::put(wave)
        wave
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()
        element = NereidInterface::interactivelyIssueNewElementOrNull()
        return nil if element.nil?
        schedule = Waves::makeScheduleObjectInteractivelyOrNull()
        return nil if schedule.nil?
        wave = Waves::issueWave(LucilleCore::timeStringL22(), element, schedule)
        wave
    end

    # Waves::getOrNull(uuid)
    def self.getOrNull(uuid)
        TodoCoreData::getOrNull(uuid)
    end

    # Waves::waves()
    def self.waves()
        TodoCoreData::getSet("7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4")
    end

    # Waves::toString(wave)
    def self.toString(wave)
        ago = 
            if wave["lastDoneDateTime"] then
                "#{((Time.new.to_i - DateTime.parse(wave["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
            else
                ""
            end
        "[wave] [#{Waves::scheduleToString(wave["schedule"])}] #{NereidInterface::toString(wave["nereiduuid"])} (#{ago})"
    end

    # Waves::ns16s()
    def self.ns16s()
        Waves::waves()
            .map{|wave|
                {
                    "uuid"     => wave["uuid"],
                    "announce" => Waves::toString(wave),
                    "lambda"   => lambda { 
                        Waves::access(wave)
                        if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
                            Waves::performDone(wave)
                        end
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Waves::access(wave)
    def self.access(wave)
        puts Waves::toString(wave)

        element = NereidInterface::getElementOrNull(wave["nereiduuid"])
        return if element.nil?

        case element["type"]
        when "Line"
        when "Url"
            CatalystUtils::openUrl(element["payload"])
        else
            NereidInterface::access(wave["nereiduuid"])
        end
    end

    # Waves::selectWaveOrNull()
    def self.selectWaveOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Waves::waves().sort{|w1, w2| Waves::toString(w1) <=> Waves::toString(w2) }, lambda {|wave| Waves::toString(wave) })
    end

    # Waves::landing(wave)
    def self.landing(wave)
        loop {
            system("clear")
            return if TodoCoreData::getOrNull(wave["uuid"]).nil? # Could hve been destroyed in the previous loop
            puts Waves::toString(wave)
            puts "uuid: #{wave["uuid"]}"
            puts "last done: #{wave["lastDoneDateTime"]}"
            if DoNotShowUntil::isVisible(wave["uuid"]) then
                puts "active"
            else
                puts "hidden until: #{Time.at(DoNotShowUntil::getUnixtimeOrNull(wave["uuid"])).to_s}"
            end
            puts "schedule: #{wave["schedule"]}"

            menuitems = LCoreMenuItemsNX1.new()

            menuitems.item("start", lambda {
                NereidInterface::landing(wave["nereiduuid"])
                if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
                    Waves::performDone(wave)
                end
            })

            menuitems.item("nereid landing",lambda { NereidInterface::landing(wave["nereiduuid"]) })

            menuitems.item("done",lambda { Waves::performDone(wave) })

            menuitems.item("description", lambda { 
                description = CatalystUtils::editTextSynchronously(wave["description"])
                return if description.nil?
                wave["description"] = description
                TodoCoreData::put(wave)
            })

            menuitems.item("recast", lambda { 
                schedule = Waves::makeScheduleObjectInteractivelyOrNull()
                return if schedule.nil?
                wave["schedule"] = schedule
                TodoCoreData::put(wave)
            })

            menuitems.item("destroy", lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                    TodoCoreData::destroy(wave)
                end
            })

            status = menuitems.promptAndRunSandbox()
            break if !status
        }
    end

    # Waves::wavesDive()
    def self.wavesDive()
        loop {
            system("clear")
            wave = Waves::selectWaveOrNull()
            return if wave.nil?
            Waves::landing(wave)
        }
    end

    # Waves::main()
    def self.main()
        loop {
            system("clear")
            puts "Waves 🌊"
            options = [
                "new wave",
                "waves dive"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "new wave" then
                Waves::issueNewWaveInteractivelyOrNull()
            end
            if option == "waves dive" then
                Waves::wavesDive()
            end
        }
    end
end



