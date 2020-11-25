#encoding: utf-8

require 'mongo'

module Omloga
  class Request
    attr_accessor :id, :uuid, :pid, :saved, :lines, :count, :complete_count, :path, :status, :created_at, :updated_at

    def initialize(uuid, pid, start_line)
      @id = BSON::ObjectId.new
      @uuid = uuid
      @pid = pid
      @saved = false
      @count = 1
      @complete_count = 0
      @status = []
      @path = []
      @lines = []
      add_start_line(start_line.to_s)
    end

    def add_start_line(line)
      self.lines << line
      self.path << line.match(/Started [A-Z]+ "(.+)"/)[1]
    end

    def add_end_line(line)
      self.lines << line
      self.status << line.match(/Completed ([2-5][0-9][0-9]) /)[1].to_i
    end

    def mongo_doc
      obj = {
        '_id' => id,
        'uuid' => uuid,
        'pid' => pid,
        'count' => count,
        'path' => path,
        'status' => status,
        'lines' => lines
      }

      if saved
        obj['updated_at'] = Time.now
      else
        obj['created_at'] = obj['updated_at'] = Time.now
      end
      obj
    end

    def id_doc
      {'_id' => id }
    end
    
    def add_line_special(line, pos)
      line = line.to_s
      lines.insert(line, pos.to_i)
    rescue StandardError => e
      puts "\nline = \n#{line} | is_last = #{is_last}"
      puts e.message
      puts e.backtrace.join("\n")
      exit
    end
  end #__End of class Request__
end #__End of module Omloga__
