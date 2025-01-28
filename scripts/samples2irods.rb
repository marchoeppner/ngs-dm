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

### Define modules and classes here

def metadata_to_string(file_name)
  
  answer = ""
  
  IO.readlines(file_name).each do |line|
    
    elements = line.strip.split("\t")
    if elements.length == 2
      elements.push("string")
    end
    elements.each do |e|
      e.gsub!(/\;/, ',')
    end
    
    answer += "#{elements.join(';')};"
    
  end
  return answer
  
end


def metadata_to_imeta(file_name)

	answer = []

	IO.readlines(file_name).each do |line|

    		elements = line.strip.split("\t")
    		if elements.length == 2
      			elements.push("string")
    		end
    		elements.each do |e|
      			e.gsub!(/\;/, ',')
    		end

    		answer << elements.collect{|e| "\"#{e}\"" }.join(" ")

  	end
	
	return answer

end

def metadata_to_info(file_name)
  
  answer = {}
  
  IO.readlines(file_name).each do |line|
    
    elements = line.strip.split("\t")
    answer[elements[0]] = elements[1]
    
  end
  
  return answer
  
end

def run(command)

  warn "Running: #{command}"
  system(command)

end

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.on("-i","--infile", "=INFILE","Input file") {|argument| options.infile = argument }
opts.on("-p","--pretend","Simulate only") {|argument| options.pretend = true }
opts.on("-c","--cleanup","Cleanup existing file before loading") {|argument| options.cleanup = true }
opts.on("-f","--folder","=FOLDER", "iRODS Collection",) {|argument| options.folder = argument }
opts.on("-h","--help","Display the usage information") {
 puts opts
 exit
}

opts.parse! 

abort "Must provide iRODS collection name (--folder)" unless options.folder

BASE_URL = "/lsh/ngs"

command = "imkdir /lsh/ngs/#{options.folder}"
run(command)

file_groups = Dir.entries(Dir.getwd).select{|e| e.include?(".fastq.gz")}.group_by{|e| e.split(/_L00/)[0].split(/_R[1,2]/)[0] }

file_groups.each do |group,files|
  
  warn "Processing data set #{group}"  
  library_id = group
  warn library_id
  metadata = library_id + ".meta"

  abort "Could not find the metadata sheet (#{metadata}) for the sample #{group}" unless File.exist?(metadata)
  
  next unless File.exist?(metadata)

  meta_string = metadata_to_string(metadata)
  info = metadata_to_info(metadata)

  meta_sets = metadata_to_imeta(metadata)

  tar_file = group + ".tar"
  md5_file = tar_file + ".md5"
  
  unless File.exist?(tar_file)
    this_command = "tar -cvf #{tar_file} #{group}* #{metadata}"
    if options.pretend
       warn this_command
    else
    	run(this_command)
      md5 = "md5sum #{tar_file} > #{md5_file}"
      run(md5)
    end
  end

  command = "irm -f #{BASE_URL}/#{options.folder}/#{tar_file}"

  if options.cleanup
	  if options.pretend
        	warn command
	  else
        	run(command)
	  end
  end
    
  command = "iput -R lshArchive -D tar -f #{tar_file} #{BASE_URL}/#{options.folder}/#{tar_file}"

  if options.pretend
	  warn command  
  else
  	run(command)
  end

  command = "iput -R lshArchive -f #{md5_file} #{BASE_URL}/#{options.folder}/#{md5_file}"
  
  if options.pretend
	  warn command  
  else
  	run(command)
  end

  meta_sets.each do |ms|
  	imeta_cmd = "imeta add -d #{BASE_URL}/#{options.folder}/#{tar_file} #{ms}"
  	run(imeta_cmd) unless options.pretend
  end 
	    
end
