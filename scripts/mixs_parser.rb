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

bucket =  {}
bucket["$schema"]     = "http://json-schema.org/draft-04/schema#"
bucket["title"]       =  "Metadata template #{options.name}"

items.each do |item,elements|

  next unless item == options.name

  bucket["description"] = elements["description"]
  bucket["type"]        = "object"
  bucket["properties"]  = elements["properties"]
  bucket["required"]    = elements["required"]
  
end

puts bucket.to_json

