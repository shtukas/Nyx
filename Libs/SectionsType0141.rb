
# SectionsType0141::contentToSections(text)
# SectionsType0141::applyNextTransformationToText(content)

class SectionsType0141

    # SectionsType0141::contentToSections(text)
    def self.contentToSections(text)
        SectionsType0141::linesToSections(text.lines.to_a)
    end

    # SectionsType0141::linesToSections(reminaingLines)
    def self.linesToSections(reminaingLines, sections = [""])
        # presection: Array[String]
        if reminaingLines.size==0 then
            return sections
                    .select{|section| section.strip.size>0 }
        end
        line = reminaingLines.shift
        if line.start_with?('[]') then
            sections << line
        else
            sections[sections.size-1] = sections[sections.size-1] + line
        end
        SectionsType0141::linesToSections(reminaingLines, sections)
    end

    # SectionsType0141::applyNextTransformationToText(text)
    def self.applyNextTransformationToText(text)

        positionOfFirstNonSpaceCharacter = lambda{|line, size|
            return (size-1) if !line.start_with?(" " * size)
            positionOfFirstNonSpaceCharacter.call(line, size+1)
        }

        lines = text.strip.lines.to_a
        return text if lines.empty?
        slineWithIndex = lines
            .reject{|line| line.strip == "" }
            .each_with_index
            .map{|line, i| [line, i] }
            .reduce(nil) {|selectedLineWithIndex, cursorLineWithIndex|
                if selectedLineWithIndex.nil? then
                    cursorLineWithIndex
                else
                    if (positionOfFirstNonSpaceCharacter.call(selectedLineWithIndex.first, 1) < positionOfFirstNonSpaceCharacter.call(cursorLineWithIndex.first, 1)) and (selectedLineWithIndex[1] == cursorLineWithIndex[1]-1) then
                        cursorLineWithIndex
                    else
                        selectedLineWithIndex
                    end
                end
            }
        sline = slineWithIndex.first
        lines
            .reject{|line| line == sline }
            .join()
            .strip
    end
end

