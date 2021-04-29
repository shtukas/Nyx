
# encoding: UTF-8

class Galaxy

    # Galaxy::roots()
    def self.roots()
        ["/Users/pascal/Galaxy/Nyx/StdFSTrees"]
    end

    # Galaxy::locationEnumerator()
    def self.locationEnumerator()
        Enumerator.new do |filepaths|
            Galaxy::roots().each{|root|
                if File.exists?(root) then
                    begin
                        Find.find(root) do |path|
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

    # Galaxy::galaxyFileHierarchiesMx19s()
    def self.galaxyFileHierarchiesMx19s()
        Galaxy::locationEnumerator().map{|location|
            {
                "announce" => location[51, location.size] || "",
                "type"     => "galaxy-location",
                "location" => location
            }
        }
    end
end
