
# encoding: UTF-8

class Runner

    # Runner::isRunning?(uuid)
    def self.isRunning?(uuid)
        !KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}").nil?
    end

    # Runner::start(uuid)
    def self.start(uuid)
        return if Runner::isRunning?(uuid)
        KeyValueStore::set(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}", Time.new.to_i)
    end

    # Runner::stop(uuid)
    def self.stop(uuid)
        return nil if !Runner::isRunning?(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}").to_i
        timespan = Time.new.to_f - unixtime
        KeyValueStore::destroy(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        timespan
    end

    # Runner::runTimeInSecondsOrNull(uuid)
    def self.runTimeInSecondsOrNull(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        return nil if unixtime.nil?
        Time.new.to_f - unixtime.to_i
    end

    # Runner::runTimeAsString(uuid, padding = "")
    def self.runTimeAsString(uuid, padding = "")
        runtime = Runner::runTimeInSecondsOrNull(uuid)
        return "" if runtime.nil?
        "#{padding}(running for #{(runtime.to_f/3600).round(2)} hours)"
    end
end
