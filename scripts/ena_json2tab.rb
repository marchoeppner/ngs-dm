#!/usr/bin/ruby
# == NAME
# ena_json2tab.rb
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

experiment  = json["experiment"]

fields = experiment["fields"]

puts "key\tdescription\tunits\tcardinality\tvalues"

fields.each do |field|

  name = field["name"]
  cardinality = field["cardinality"]
  description = field["description"]
  units = field["units"]
  allowed_values = field["cv"].join(",")
  field_type = field["field_type"]

  puts "#{name}\t#{description}\t#{units}\t#{cardinality}\t#{allowed_values}"

end