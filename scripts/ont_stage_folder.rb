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
require 'date'

class String
	def black;          "\e[30m#{self}\e[0m" end
	def red;            "\e[31m#{self}\e[0m" end
	def green;          "\e[32m#{self}\e[0m" end
end

def cmd(text)
    warn "#{DateTime.now} - #{text}".green
    system(text)
end
### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.on("-l","--lookup", "=LOOKUP","Lookup file") {|argument| options.lookup = argument }
opts.on("-p","--pass", "=PASS","ONT pass directory") {|argument| options.pass = argument }
opts.on("-o","--output", "=OUTPUT","Output folder") {|argument| options.output = argument }
opts.on("-h","--help","Display the usage information") {
 puts opts
 exit
}

opts.parse!

abort "Must prodive an output directory!" unless options.output
abort "No lookup file specified, exiting" unless otions.lookup

output = options.output
cmd("mkdir -p #{output}")

lookup = {}
IO.readlines(options.lookup).map {|l| lookup[l.split("\t")[0].strip] = l.split("\t")[1].strip }	

barcodes = Dir["#{options.pass}/barcode*"].map {|b| b.strip }

valid_barcodes = barcodes.select { |bc| (Dir[bc + "/*.fastq.gz"].sum {|f| File.size(f) }/100000) > 10 }

barcodes.each do |bc|

    if !valid_barcodes.include?(bc)
        warn "Skipping barcode #{bc} - no data.".red
    else 
        b = bc.split("/")[-1]
        lookup.has_key?(b) ? lib = lookup[b] : lib = nil

        abort "Barcode directory looks sane, but but no library specified #{bc}".red unless lib

        warn "Using barcode #{lib}"

        command = "cat #{bc}/*.fastq.gz > #{output}/#{lib}_R1_001.fastq.gz"
        cmd(command)

    end
end
