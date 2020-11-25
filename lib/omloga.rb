require 'mongo'
require 'optparse'
require 'ostruct'
require 'omloga/request'

def omloga(args)

  options = OpenStruct.new

  opts_parser = OptionParser.new do |opts|

    opts.banner = "\nUsage : omloga -d <mongodb-uri> -c <collection-name> [OPTIONS] <log-file-path>"

    opts.separator ""

    opts.on('-d', '--dburi Mongodb-URI', 'MongoDB URI with username/password (if needed) and DB name') do |uri|
      options.dburi = uri
    end

    opts.on('-c', '--collection Collection-Name', 'Name of the collection where the log lines should be stored') do |c|
      options.collection = c
    end

    opts.on('--log-skip SKIP-FILE-PATH', 'Logs the skipped lines to the specified file') do |sf|
      options.skip_file_path = sf
    end

    opts.on_tail('-h', '--help', 'Show this help message') do
      puts opts
      exit
    end
  end

  opts_parser.parse!(args)

  if args.length < 1
    puts "Insufficient number of arguments"
    puts opts_parser
    exit
  end

  def db_client
    $DB_CLIENT
  end

  def logs_collection
    $DB_LOGS_COLLECTION
  end

  def request_hash
    $REQUEST_HASH
  end

  $DB_CLIENT = Mongo::Client.new(options.dburi)
  db_client.logger.level = Logger::INFO
  $DB_LOGS_COLLECTION = db_client[options.collection]
  $REQUEST_HASH = {}
  $LOG_FILE = args[0]

  def is_start_line?(line)
    line = line.to_s
    return false if line.nil? or line.length < 7 # "Started" is 7 characters long. It is minimal

    if line.match(/Started/).nil?
      false
    else
      true
    end
  end

  def is_complete_line?(line)
    line = line.to_s
    return false if line.nil? or line.length < 9 # "Completed" is 9 characters long. It is minimal

    if line.match(/Completed/).nil?
      false
    else
      true
    end
  end

  def get_pid(line)
    match_data = line.match(/#([0-9]+)\]/)
    if match_data
      return match_data[1]
    else
      return nil
    end
  end

  def get_uuid(line)
    match_data = line.match(/([a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12})/)
    if match_data
      return match_data[1]
    else
      return nil
    end
  end

  line_count = 0
  request_count = 0
  lines_skipped = 0
  status_str = ''
  $stdout.sync = true
  log_skip = false
  if options.skip_file_path
    skipped_lines = File.open(options.skip_file_path, 'a')
    log_skip = true
  end

  File.foreach($LOG_FILE) do |log_line|
    log_line.strip!
    pid = get_pid(log_line)
    uuid = get_uuid(log_line)
    req = request_hash[uuid]
    if uuid == nil
      lines_skipped += 1
      skipped_lines.print log_line if log_skip
      next
    end 

    if is_start_line?(log_line)
      if req
        req.add_start_line(log_line)
        req.count+= 1
      else
        req = Omloga::Request.new(uuid, pid, log_line)
        request_hash[uuid] = req
      end
    else
      unless req
        lines_skipped+= 1
        skipped_lines.print log_line if log_skip
        next 
      end
      is_complete = is_complete_line?(log_line)

      if is_complete
        req.add_end_line(log_line)
        req.complete_count+= 1

        if req.complete_count >= req.count
          logs_collection.find(req.id_doc).update_one(req.mongo_doc, {upsert: true})
          request_hash.delete(uuid)
          request_count+= req.count
        end
      else
        req.lines << log_line
      end
    end
    line_count+= 1

    status_str.length.times { print "\b" }

    status_str = "Lines Processed : #{line_count} | Requests found : #{request_count} | Lines Skipped : #{lines_skipped}"
    print status_str
  end

  puts ""

  if log_skip
    puts "Skipped lines have been written to : #{options.skip_file_path}" 
    skipped_lines.close
  end

  puts "\nDone..!"
end
