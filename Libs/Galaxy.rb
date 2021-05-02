
# encoding: UTF-8

class Galaxy

    # Galaxy::locationEnumerator(roots)
    def self.locationEnumerator(roots)
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exists?(root) then
                    begin
                        Find.find(root) do |path|
                            next if File.basename(path)[0, 1] == "."
                            next if path.include?("target")
                            next if path.include?("project")
                            next if path.include?("node_modules")
                            next if path.include?("static")
                            filepaths << path
                        end
                    rescue
                    end
                end
            }
        end
    end

    # Galaxy::mx19sAtRoot(root)
    def self.mx19sAtRoot(root)
        Galaxy::locationEnumerator([root]).map{|location|
            {
                "announce" => "#{File.basename(location)}",
                "type"     => "galaxy-location",
                "location" => location
            }
        }
    end

    # Galaxy::mx20s()
    def self.mx20s()
        root = "/Users/pascal/Galaxy/Nyx/StdFSTrees"
        Galaxy::locationEnumerator([root]).map{|location|
            {
                "announce"         => "[location] #{File.basename(location)} (#{File.dirname(location)[-60, 60]})",
                "deep-searcheable" => "#{File.basename(location)}",
                "type"             => "galaxy-location",
                "location"         => location
            }
        }
    end
end
