#!/usr/bin/ruby
require 'yaml'

CONFIG_FILE = File.join((ENV["XDG_USER_HOME"] && !ENV["XDG_USER_HOME"].empty? ? ENV["XDG_USER_HOME"] : File.join(ENV["HOME"], ".config")), "reasonset", "diary.yaml")

CONFIG_BASE = {
  "diary_dir" => File.join(`xdg-user-dir DOCUMENTS`.chomp, "diary"),
}

if File.exist? CONFIG_FILE
  CONFIG = CONFIG_BASE.merge YAML.load(File.read(CONFIG_FILE))
else
  CONFIG = CONFIG_BASE
end

DIARY_DIR = CONFIG["diary_dir"]

day = nil

if ARGV[0]
  date_string = ARGV.shift
  day = `date --date="#{date_string}" "+%Y/%m_%d"`
  day = $?.success? ? day.strip : nil
end

unless day
  day = `zenity --calendar --date-format="%Y/%m_%d"`
  if !$?.success? or day !~ %r:^\d+/\d+_\d+$:
    exit 1
  else
    day = day.strip
  end
end

editor = CONFIG["editor"] || ENV["DIARY_EDITOR"] || ENV["EDITOR"] || "vi"

Dir.chdir(DIARY_DIR)
Dir.mkdir(File.dirname(day)) unless File.exist?(File.dirname(day))

system(editor, day)
