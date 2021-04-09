
# encoding: UTF-8

# -----------------------------------------------------------------------

class Utils

    # Utils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.hex
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # Utils::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # Utils::isDateTime_UTC_ISO8601(datetime)
    def self.isDateTime_UTC_ISO8601(datetime)
        DateTime.parse(datetime).to_time.utc.iso8601 == datetime
    end

    # Utils::isInteger(str)
    def self.isInteger(str)
        str == str.to_i.to_s
    end

    # Utils::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Utils::openUrl(url)
    def self.openUrl(url)
        system("open -a Safari '#{url}'")
    end

    # ----------------------------------------------------

    # Utils::levenshteinDistance(s, t)
    def self.levenshteinDistance(s, t)
      # https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1] # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end

    # Utils::stringDistance1(str1, str2)
    def self.stringDistance1(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        Utils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

    # Utils::stringDistance2(str1, str2)
    def self.stringDistance2(str1, str2)
        # We need the smallest string to come first
        if str1.size > str2.size then
            str1, str2 = str2, str1
        end
        diff = str2.size - str1.size
        (0..diff).map{|i| Utils::levenshteinDistance(str1, str2[i, str1.size]) }.min
    end

    # ----------------------------------------------------

    # Utils::selectLinesUsingInteractiveInterface(lines) : Array[String]
    def self.selectLinesUsingInteractiveInterface(lines)
        # Some lines break peco, so we need to be a bit clever here...
        linesX = lines.map{|line|
            {
                "line"     => line,
                "announce" => line.gsub("(", "").gsub(")", "").gsub("'", "").gsub('"', "") 
            }
        }
        announces = linesX.map{|i| i["announce"] } 
        selected = `echo '#{([""]+announces).join("\n")}' | /usr/local/bin/peco`.split("\n")
        selected.map{|announce| 
            linesX.select{|i| i["announce"] == announce }.map{|i| i["line"] }.first 
        }
        .compact
    end

    # Utils::selectLineOrNullUsingInteractiveInterface(lines) : String
    def self.selectLineOrNullUsingInteractiveInterface(lines)

        # Temporary measure to remove stress on Utils::selectLinesUsingInteractiveInterface / peco after 
        # we added the videos from video stream
        lines = lines.reject{|line| line.include?('.mkv') }
        
        lines = Utils::selectLinesUsingInteractiveInterface(lines)
        if lines.size == 0 then
            return nil
        end
        if lines.size == 1 then
            return lines[0]
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("select", lines)
    end

    # Utils::selectOneObjectOrNullUsingInteractiveInterface(items, toString = lambda{|item| item })
    def self.selectOneObjectOrNullUsingInteractiveInterface(items, toString = lambda{|item| item })
        lines = items.map{|item| toString.call(item) }
        line = Utils::selectLineOrNullUsingInteractiveInterface(lines)
        return nil if line.nil?
        items
            .select{|item| toString.call(item) == line }
            .first
    end
end
