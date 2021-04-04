
# encoding: UTF-8

class QuarksHorizon

    # QuarksHorizon::getHorizonOrNull(unixtime1, count1, unixtime2, count2)
    def self.getHorizonOrNull(unixtime1, count1, unixtime2, count2)
        return nil if count2 >= count1
        # (count2 - count1)/(unixtime2-unixtime1) = (count3 - count1)/(unixtime3-unixtime1) # fundamental equality
        # Now we pose count3 = 0
        # (count1 - count2)/(unixtime2-unixtime1) = count1/(unixtime3-unixtime1)
        # (unixtime3-unixtime1) = count1*(unixtime2-unixtime1)/(count1 - count2)
        # unixtime3 = count1*(unixtime2-unixtime1)/(count1 - count2) + unixtime1
        (count1*(unixtime2-unixtime1)).to_f/(count1 - count2) + unixtime1
    end

    # QuarksHorizon::getPairs()
    def self.getPairs()
        IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Quarks-Horizon.txt")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0 }
            .map{|line| 
                elements = line.split(";")
                [elements[1].to_i, elements[2].to_i]
            }
    end

    # QuarksHorizon::getPair1OrNull()
    def self.getPair1OrNull()
        limit = Time.new.to_i - 86400*7
        QuarksHorizon::getPairs()
            .select{|pair| pair[0] <= limit }
            .last
    end

    # QuarksHorizon::getPair2OrNull()
    def self.getPair2OrNull()
        QuarksHorizon::getPairs()
            .last
    end

    # QuarksHorizon::getHorizonDateTimeOrNull()
    def self.getHorizonDateTimeOrNull()
        pair1 = QuarksHorizon::getPair1OrNull()
        return if pair1.nil?

        pair2 = QuarksHorizon::getPair2OrNull()
        return if pair2.nil?

        unixtime1 = pair1[0]
        count1    = pair1[1]
        unixtime2 = pair2[0]
        count2    = pair2[1]

        horizon = QuarksHorizon::getHorizonOrNull(unixtime1, count1, unixtime2, count2)
        return nil if horizon.nil?
        Time.at(horizon).utc.iso8601
    end

    # QuarksHorizon::makeNewDataPoint()
    def self.makeNewDataPoint()
        t = Time.new
        c = Quarks::quarks().count
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Quarks-Horizon.txt", "a"){|f| f.puts("#{t.to_s};#{t.to_i};#{c}") }
    end
end


Thread.new {
    loop {
        sleep 60
        next if !ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("66c4556d-dfdb-4dec-b771-bea1482cfc6c", 86400)
        QuarksHorizon::makeNewDataPoint()
    }
}