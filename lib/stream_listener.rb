class StreamListener

  def initialize(server)
    @server = server
    connect
  end

  attr_reader :server

  def url
    @server.url
  end

  def connect
    head_response = Typhoeus.head url, headers: { "Icy-MetaData" => "1" }
    metadata_interval = head_response.headers["icy-metaint"].to_i
    listen_for_metadata url, metadata_interval
  end

  def current_song
    "Wat"
  end

  private

  def listen_for_metadata(url, metadata_interval)
    url = URI.parse(url)
    count = 0
    buffer = ""

    Net::HTTP.start url.host, url.port do |http|
      request = Net::HTTP::Get.new url.path, "Icy-MetaData" => "1"
      http.request request do |response|
        response.read_body do |chunk|
          buffer += chunk
          buffer_size = buffer.bytesize
          if buffer_size >= metadata_interval
            buffer = buffer.byteslice metadata_interval, buffer_size - metadata_interval
            to_process = buffer.byteslice 0, metadata_interval
            metadata = find_metadata to_process
            found_metadata! metadata if metadata.present?
          end
        end
      end
    end
  end

  def found_metadata! metadata
    puts metadata.inspect
  end

  def find_metadata(buffer)
    line = buffer.inspect
    extract = line.scan /StreamTitle=([^;]*)/
    puts extract.inspect
    if extract.present?
      extract.first.first
    else
      false
    end
  end

end
