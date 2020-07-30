#!/usr/bin/ruby

PPID=$$
DOC_DIR = `xdg-user-dir DOCUMENTS`.chomp

Dir.mkdir "#{DOC_DIR}/atnow" unless File.exist? "#{DOC_DIR}/atnow"
File.open("#{DOC_DIR}/atnow/now", "w") {|f| nil } unless File.exist? "#{DOC_DIR}/atnow/now"

wp = IO.popen(["yad", "--notification", "--listen", '--image=user-available', '--text="@Now"', '--item-separator=`', "--command=kill -HUP #{PPID}"], "w")

update_menu = ->() {
  lines = File.readlines "#{DOC_DIR}/atnow/now"
  if lines.length > 520
    File.open("#{DOC_DIR}/atnow/archive-#{Time.now.strftime("%Y%m%d-%H")}", "w") do |f|
      f.puts lines.first(500)
    end
    lines = lines[500..]
    File.open("#{DOC_DIR}/atnow/now" ,"w") do |f|
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
    File.open("#{DOC_DIR}/atnow/now" ,"a") do |f|
      begin
        f.flock(File::LOCK_EX)
        f.puts([Time.now.strftime("%Y-%m-%d\t%H:%M:%S"), text.tr('|`', "/'")].join("\t"))
      ensure
        f.flock(File::LOCK_UN)
      end
    end
    update_menu.()
  end
end

begin
  File.open("#{ENV["HOME"]}/.atnow.pid", "w") {|f| f.print PPID}
  Process.waitpid(wp.pid)
ensure
  File.delete("#{ENV["HOME"]}/.atnow.pid")
end
