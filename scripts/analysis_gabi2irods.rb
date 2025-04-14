#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'open3'
require 'json'

BASE_URL = "/lsh/ngs"

class String
	def black;          "\e[30m#{self}\e[0m" end
	def red;            "\e[31m#{self}\e[0m" end
	def green;          "\e[32m#{self}\e[0m" end
end
	

def check_irods
	stdout_str, stderr_str, status = Open3.capture3("ils")
	stderr_str.include?("Error") ? irods = false : irods = true
	return irods
end

def check_gabi(folder)
	status = true
	
	if !Dir.exist?("#{folder}/samples")
		return false
	end
	
	jsons = Dir["#{folder}/samples/*/*.json"]
	if jsons.empty?
		return false
	end

	return status
end

def build_metadata(json)

	bucket = [
		"sample\t#{json["sample"]}\tstring",
		"assembly_length\t#{json["quast"]["Total length"]}\tinteger",
		"contigs\t#{json["quast"]["# contigs"]}\tinteger",
		"pipeline\tbio-raum/gabi\tstring",
		"pipeline_version\t#{json["software"]["Workflow"]["bio-raum/gabi"]}\tstring",
		"taxon\t#{json["taxon"]}\tstring",
		"n50\t#{json["quast"]["N50"]}\tinteger",
		"gc\t#{json["quast"]["GC (%)"]}\tfloat",
		"analysis_date\t#{json["date"]}\tdate",
		"qc_status\t#{json["qc"]["call"]}\tstring",
		"coverage_mean\t#{json["mosdepth"]["total"]["mean"]}\tfloat",
		"percent_40X\t#{json["mosdepth_global"]["total"]["40"]}\tfloat",
		"Q30\t#{json["fastp"]["summary"]["before_filtering"]["q30_rate"]}"
	]

	# get the name of the input reads
	fastp_command = json["fastp"]["command"].split(" ")
	reads = "#{fastp_command[2]},#{fastp_command[4]}"
	bucket.push("reads\t#{reads}\tstring")
	
	serotype = []

	json["serotype"].each do |s,data|
		sero = data.find{|k,v| k.downcase.include?("serotype")}
		if sero
			serotype << sero[1]
		end
	end

	bucket.push("serotype\t#{serotype.uniq.join(",")}\tstring")

	return bucket

end

def run(command)

  warn "Running: #{command}".green
  system(command)

end
### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.on("-f","--folder", "=Folder with reads") {|argument| options.folder = argument }
opts.on("-o","--outfile", "=OUTFILE","Output file") {|argument| options.outfile = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse!

if !check_irods
	abort "You are not authenticated with the iRODS service - please run `iinit`!"
end

if !check_gabi(options.folder)
	abort "GABI folder not found or incomplete (#{options.folder})"
end

system("mkdir -p datamanagement")

samples = Dir["#{options.folder}/samples/*"].map {|f| File.expand_path(f)}

Dir.chdir("datamanagement") do |dir|

	samples.each do |sdir|
	
		sname = sdir.split("/")[-1]

		json_file = "#{sdir}/#{sname}.qc.json"
		json = JSON.parse(IO.readlines(json_file).join)

		sample = json["sample"]

		warn sample

		assembly = "#{sdir}/assembly/#{sname}.fasta"

		if !File.exist?(assembly)
			abort "Assembly not found (#{assembly})"
		end

		meta = build_metadata(json)
		meta.push("source\t#{sdir}\tstring")

		f = File.new("#{sample}.meta","w+")
		meta.each do |m|
			f.puts m
		end
		f.close

		run("cp #{assembly} .")
		run("cp #{json_file} .")
		tar_file = "#{sample}.tar.gz"
		md5_file = "#{sample}.tar.gz.md5sum"
		run("tar --exclude=tar.gz -cvf #{tar_file} #{sample}*")
		run("md5sum #{tar_file} > #{md5_file}")

		run("iput -R lshArchive -D tar -f #{tar_file} #{BASE_URL}/bacteria/#{tar_file}")
		run("iput -R lshArchive -D tar -f #{md5_file} #{BASE_URL}/bacteria/#{md5_file}")

		meta.each do |ms|
			imeta_cmd = "imeta add -d #{BASE_URL}/bacteria/#{tar_file} #{ms}"
			run(imeta_cmd)
		end 

	end

end