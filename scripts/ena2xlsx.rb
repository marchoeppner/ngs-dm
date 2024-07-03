#!/usr/bin/ruby
# == NAME
# ena2xlsx.rb
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
opts.on("-o","--output", "=OUTPUT","Output file") {|argument| options.output = argument }
opts.on("-h","--help","Display the usage information") {
 puts opts
 exit
}

opts.parse!

defaults = {
  "library_selection" => [ "PCR", "RANDOM" ],
  "library_strategy" => [ "WGS", "AMPLICON"],
  "platform" => [ "ILLUMINA", "OXFORD_NANOPORE" ],
  "instrument_model" => [ "Illumina MiSeq" , "MinION"],
  "library_layout" => [ "PAIRED" ]
}

mandatory = [ "library_name","library_construction_protocol" ]

bg_color = { "even" => "dceef9", "uneven" => "b3c8d5"}

order = [ "library_name","sample_alias", "study_alias"]

abort "Missing output file argument" unless options.output

json = JSON.parse(IO.readlines(options.json).join("\n"))

experiment  = json["experiment"]["fields"]
study       = json["study"]["fields"]
sample      = json["sample"]["fields"]
name        = options.json.split("/")[-1].split(".")[0]

data = []
experiment.map {|e| data << e }
sample.each do |s|
  data << s unless data.find{|d| d["name"] == s["name"]}
end
data << { "name" => "external_id", "cardinality" => "mandatory", "cv" => [], "description" => "External identifier"}
data << { "name" => "external_source", "cardinality" => "mandatory", "cv" => [ "LSH LIMSOPHY" ], "description" => "External identifier source"}

workbook = RubyXL::Workbook.new

################
# Cover page
################

cover = workbook.worksheets[0]

row = 0
col = 0

cover.sheet_name = "Deckblatt"

cover.add_cell(0,0,"Metadaten Standard")
cover.change_column_width(0, 20)
cover.add_cell(0,1,name)
cover.change_column_width(1, 20)

#####################
# Metadata sheet
#####################

row = 0
col = 0

meta = workbook.add_worksheet("Metadaten")

data_selected = data.select{|d| d["cardinality"] == "mandatory" }

data.select {|d| mandatory.include?(d["name"])}.map {|d| data_selected << d }
data_sorted = data_selected.sort_by{|d| d["name"]}

data_ordered = []
order.each do |o|
  entry = data_sorted.find{|d| d["name"] == o}
  data_ordered << entry
  data_sorted.delete(entry)
end
data_sorted.each {|d| data_ordered << d }

data_ordered.each_with_index do |data,i|

  i.even? ? color = bg_color["even"] : color = bg_color["uneven"]
  meta.change_column_fill(i,color)

  row = 0

  name = data["name"]
  val = name
  meta.add_cell(row+1,i,name)
  meta.sheet_data[row+1][i].change_font_bold(true)

  dtype = data["field_type"]
  val = dtype if dtype.to_s.size > val.to_s.size
  meta.add_cell(row,i,dtype)

  row += 1

  w = val.to_s.size*1.1
  if w > meta.get_column_width(i)
    meta.change_column_width(i, w)
  end

  defaults.has_key?(name) ? values = defaults[name] : values = data["cv"]

  if values.length > 0 && values.length < 15
    this_row = row
    20.times do 
      this_row += 1
      this_ref = RubyXL::Reference.ind2ref(this_row,i)
      meta.add_validation_list(this_ref,values)
    end
  end

end


workbook.write("#{options.output}.xlsx")
