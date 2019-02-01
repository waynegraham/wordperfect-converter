#! /usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'pp'
require 'ostruct'
require 'fileutils'
require 'libreconv'

#
# Converter class
#
class ConverterOptions
  #
  # Return a structure describing the options
  #
  def self.parse(args)
    options = OpenStruct.new
    options.verbose = false
    options.directory = '.'
    options.ignore = '.doc'

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: convert.rb [options]'

      opts.separator ''
      opts.separator 'Specific options:'

      # Optional directory path
      opts.on('-d', '--dir [PATH]',
              'Path for WordPerfect files to convert',
              '   (makes a backup of all files)') do |path|
        options.directory = path
      end

      opts.on('-i', '--ignore [extensions]',
        'File extensions to ignore') do |ext|
          options.ignore = ext || '.doc'
          options.ignore.sub!(/\A\.?(?=.)/, '.') # Ensure extension begins with dot.
        end

      opts.on('-v', '--verbose', 'Run verbosely') do |v|
        options.verbose = v
      end

      opts.separator ''
      opts.separator 'Common options:'

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('--version', 'Show version') do
        puts '0.0.1'
        exit
      end
    end

    opt_parser.parse!(args)
    options
  end
end

def copy_with_path(src, dest)
  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.cp(src, dest)
end

def backup
  Dir["#{@from_dir}/*"].each do |old_dest|
    new_dest = old_dest.gsub(@from_dir, @to_dir)
    should_not_copy = @ignore.any? { |s| new_dest.end_with?(s) }

    unless should_not_copy
      puts new_dest
      copy_with_path(old_dest, new_dest)
    end
  end
end

def rename
    Dir["#{@from_dir}/*"].each do |old_file|
      extension = File.extname(old_file)
      unless extension == @options.ignore
        filename = File.basename(old_file)
        File.rename(old_file, "#{@from_dir}/#{filename}.wpd") unless @to_dir.include? filename
      end
    end
end

def convert
  Dir["#{@from_dir}/*"].each do |old_file|
    new_file = File.basename(old_file) + '.pdf'
    puts "Converting #{old_file} to #{new_file}"
    Libreconv.convert(old_file, "#{@from_dir}/#{new_file}")
  end
end

@options = ConverterOptions.parse(ARGV)

@ignore = ['originals', '.wpd']

# create a backup directory
@from_dir = File.absolute_path(@options.directory)
@to_dir = "#{@from_dir}/originals/"


backup
rename
convert
