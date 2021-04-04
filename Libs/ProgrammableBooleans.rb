
# encoding: UTF-8

class ProgrammableBooleans

    # ProgrammableBooleans::resetTrueNoMoreOften(uuid)
    def self.resetTrueNoMoreOften(uuid)
        KeyValueStore::set(nil, uuid, Time.new.to_f)
    end

    # ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds(uuid, n)
    def self.trueNoMoreOftenThanEveryNSeconds(uuid, n)
        lastTimestamp = KeyValueStore::getOrDefaultValue(nil, uuid, "0").to_f
        return false if (Time.new.to_f - lastTimestamp) < n
        ProgrammableBooleans::resetTrueNoMoreOften(uuid)
        true
    end
end
