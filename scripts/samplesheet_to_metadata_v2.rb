#!/usr/bin/ruby
# == NAME
# samplesheet_to_metadata.rb
#
# == USAGE
# ./this_script.rb [ -h | --help ]
#[ -i | --infile ] |[ -o | --outfile ] | 
# == DESCRIPTION
# Converts the sample sheets from Z3 to metadata files
#
# == OPTIONS
# -h,--help Show help
# -i,--infile=INFILE input file

#
# == EXPERT OPTIONS
#
# == AUTHOR
#  Marc Hoeppner, mphoeppner@gmail.com

require 'optparse'
require 'ostruct'
require 'rubyXL'
require 'rubyXL/convenience_methods/cell'
require 'rubyXL/convenience_methods/color'
require 'rubyXL/convenience_methods/font'
require 'rubyXL/convenience_methods/workbook'
require 'rubyXL/convenience_methods/worksheet'

### Define modules and classes here

def command?(command)
    system("which #{ command} > /dev/null 2>&1")
end

class MetaEntry

    attr_accessor :key, :value, :unit

    def initialize(key,value,unit)
        @key = key.strip
        @value = value.strip
        @unit = unit.strip
    
        _sane?
    end
    
    private
    
    def _sane?
    
    end

end

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.on("-i","--infile", "=INFILE","Input file") {|argument| options.infile = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

#######################
# Parse XLS samplesheet
#######################

### Convert XLSX to CSV
xlsx = RubyXL::Parser.parse(options.infile)

front = xlsx["Deckblatt"] || raise("Missing submitter page!")
meta = xlsx["Metadaten"] || raise("Missing metadata page!")

### Get project information from first sheet

name = front[1][1]

# Parse the metadata

units = []
meta.sheet_data[0][0..50].each_with_index do |u,i|
    next if u.nil?
    units << u.value unless u.value.nil?
end

# Get the column headers for later use
header = []
meta.sheet_data[1][0..units.length].each_with_index do |h,i|
    header << h.value.gsub(" ", "_") unless h.value.nil?
end 

# Iterate over each row using the column headers to extract annotations
# We assume no more than 400 rows, which is usually reasonable
# This starts at row 3, as 1+2 are headers 

meta.sheet_data[2..400].each_with_index do |r,idx|

    data = {}
    header.each_with_index do |h,i|

	# Deal with empty columns without having the parser blow up
        r[i] ? val = r[i].value.to_s : val = nil

        if val && val.length > 0
            if val.include?("T00:00")
                val = val.split("T00:00")[0]
            end
            data[h] = val
        end

    end

    next if data.keys.empty? 
    
    # Write the iRODS metadata package
    f = File.new(data["library_name"] + ".meta", "w+")

    data.each do |k,v|
	    u = units[header.index(k)]
	    meta = MetaEntry.new(k,v,u)
        next if meta.value == "NA"
        f.puts "#{meta.key}\t#{meta.value}\t#{meta.unit}"
    end

    f.close
    
end
