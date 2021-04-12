#!/usr/bin/ruby
require 'yaml'
require 'fileutils'

PPID=$$

CONFIG_FILE = File.join((ENV["XDG_USER_HOME"] && !ENV["XDG_USER_HOME"].empty? ? ENV["XDG_USER_HOME"] : File.join(ENV["HOME"], ".config")), "reasonset", "diary.yaml")

CONFIG_BASE = {
  "atnow_dir" => File.join(`xdg-user-dir DOCUMENTS`.strip, "atnow"),
  "diary_dir" => File.join(`xdg-user-dir DOCUMENTS`.strip, "diary"),
  "pid_dir" => "/var/run/user/#{Process::UID.eid}",
  "atnow2diary" => false,
}

if File.exist? CONFIG_FILE
  CONFIG = CONFIG_BASE.merge YAML.load(File.read(CONFIG_FILE))
else
  CONFIG = CONFIG_BASE
end

DOC_DIR = CONFIG["atnow_dir"]
PID_DIR = CONFIG["pid_dir"]

CURRENT_TIME = Time.now.strftime("%Y-%m-%d\t%H:%M:%S")

Dir.mkdir DOC_DIR unless File.exist? DOC_DIR
File.open("#{DOC_DIR}/now", "w") {|f| nil } unless File.exist? "#{DOC_DIR}/now"

wp = IO.popen(["yad", "--notification", "--listen", '--image=user-available', '--text="@Now"', '--item-separator=`', "--command=kill -HUP #{PPID}"], "w")

update_menu = ->() {
  lines = File.readlines "#{DOC_DIR}/now"
  if lines.length > 520
    File.open("#{DOC_DIR}/archive-#{Time.now.strftime("%Y%m%d-%H")}", "w") do |f|
      f.puts lines.first(500)
    end
    lines = lines[500..]
    File.open("#{DOC_DIR}/now" ,"w") do |f|
      begin
        f.flock(File::LOCK_EX)
        f.puts lines
      ensure
        f.flock(File::LOCK_UN)
      end
    end
  end
  wp.puts("menu:" + lines.last(20).map {|i| fs = i.strip.sub(/^.*?\t/, "")
  fs.length > 64 ? sprintf('%s…`zenity --info --text="%s"`user-available', fs[0, 63], fs) : sprintf('%s``user-available', fs) }.join("|"))
}
update_menu.()

Signal.trap(:HUP) do
  text=`yad --entry --title="Your Tweet" --text="What's Happen?" --image=gtk-dialog-question --width=450`
  if text.length > 0
    File.open("#{DOC_DIR}/now" ,"a") do |f|
      begin
        f.flock(File::LOCK_EX)
        f.puts([CURRENT_TIME, text.tr('|`', "/'")].join("\t"))
      ensure
        f.flock(File::LOCK_UN)
      end
    end
    update_menu.()
  end

  if CONFIG["atnow2diary"]
    today = Time.now.strftime("%Y/%m_%d")
    FileUtils.mkdir_p(File.joinb(CONFIG["diary_dir"], File.dirname(today))) unless File.exist? File.join(CONFIG["diary_dir"], File.dirname(today))
    File.open(File.join(CONFIG["diary_dir"], today), "w") {} unless File.exist?(File.join(CONFIG["diary_dir"], today))
    File.open(File.join(CONFIG["diary_dir"], today), "r+") do |f|
      content = f.read
      newline = (content.include?("\r\n") ? "\r\n" : "\n")
      unless content[-(newline.length * 2) ..] == newline + newline
        if content[-(newline.length) ..] == newline
          f.print newline
        else
          f.print(newline, newline)
        end
      end

      f.printf("%s -- %s %s%s", text.strip, CURRENT_TIME.sub("\t", " "), newline, newline)

    end

  end
end

begin
  File.open("#{PID_DIR}/atnow.pid", "w") {|f| f.print PPID}
  Process.waitpid(wp.pid)
ensure
  File.delete("#{PID_DIR}/atnow.pid")
end
