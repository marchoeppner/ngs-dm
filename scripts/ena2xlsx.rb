#!/usr/bin/ruby
# == NAME
# mixs_parser.rb
#
# == USAGE
# ./this_script.rb [ -h | --help ]
#[ -i | --infile ] |[ -o | --outfile ] | 
# == DESCRIPTION
# Reads MIXS schema and extracts items from a list
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
require 'json'
require 'rubyXL'
require 'rubyXL/convenience_methods/cell'
require 'rubyXL/convenience_methods/color'
require 'rubyXL/convenience_methods/font'
require 'rubyXL/convenience_methods/workbook'
require 'rubyXL/convenience_methods/worksheet'

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.on("-j","--json", "=JSON","JSON schema file") {|argument| options.json = argument }
opts.on("-n","--name","=NAME", "Name of schema to extract") {|argument| options.name = argument }
opts.on("-h","--help","Display the usage information") {
 puts opts
 exit
}

opts.parse!

json = JSON.parse(IO.readlines(options.json).join("\n"))

items = json["$defs"]

bucket = {}

items.each do |item,elements|

  next unless item == options.name

  bucket["properties"] = elements["properties"]
  
end

abort "Data not found for #{options.name}" unless bucket["properties"]

workbook = RubyXL::Workbook.new

################
# Cover page
################

cover = workbook.worksheets[0]

row = 0
col = 0

cover.sheet_name = "Deckblatt"

cover.add_cell(0,0,"Metadaten Standard")
cover.add_cell(0,1,options.name)

#####################
# Metadata sheet
#####################

meta = workbook.worksheets[1]

meta.sheet_name = "Metadaten"



