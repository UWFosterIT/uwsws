require "restclient"
require "logger"
require "json"
require "digest/md5"
        
class UwSws
  attr_reader :last, :next

  def initialize(throw_404: true, logger: Logger.new(STDOUT),
                 use_cache: true, cert: "", key: "", throw_HEPPS: true,
                 base: "https://ws.admin.washington.edu/student/v5/")
    @base             = base
    @last             = nil
    @next             = ""
    @use_cache        = use_cache
    @logger           = logger
    @throw_404        = throw_404
    @throw_HEPPS      = throw_HEPPS
    load_config(cert, key)
  end

  def campus
    parse "campus.json"
  end

  def colleges(campus)
    data = parse "college.json?campus_short_name=#{campus}"

    data["Colleges"]
  end

  def departments(college)
    fix_param college
    data = parse "department.json?college_abbreviation=#{college}"

    data["Departments"]
  end

  def curricula(year, quarter, department: "", count: 0)
    fix_param department
    data = parse("curriculum.json?year=#{year}&quarter=#{quarter}"\
                 "&future_terms=#{count}&department_abbreviation=#{department}")

    data["Curricula"]
  end

  def course(year, quarter, curriculum, number)
    fix_param curriculum
    data = parse "course/#{year},#{quarter},#{curriculum},#{number}.json"
    data
  end

  def term(year, quarter)
    parse "term/#{year},#{quarter}.json"
  end

  def term_current
    parse "term/current.json"
  end

  def term_next
    parse "term/next.json"
  end

  def term_previous
    parse "term/previous.json"
  end

  def sections(year, curriculum: "", instructor: "", count: 0, quarter: "",
               course_num: "", delete_flag: "")
    fix_param curriculum
    data = parse("section.json?year=#{year}"\
                 "&quarter=#{quarter}&curriculum_abbreviation=#{curriculum}"\
                 "&future_terms=#{count}&course_number=#{course_num}"\
                 "&reg_id=#{instructor}&delete_flag=#{delete_flag}")

    data["Sections"]
  end

  def courses(year, quarter, curriculum: "", course: "", has_sections: "",
              size: 100, start: "", count: "", get_next: false)
    if get_next
      data = parse @next.sub("/student/v5/", "")
    else
      fix_param curriculum
      data = parse("course.json?&year=#{year}&quarter=#{quarter}"\
                   "&curriculum_abbreviation=#{curriculum}&"\
                   "course_number=#{course}&page_size=#{size}"\
                   "&page_start=#{start}"\
                   "&exclude_courses_without_sections=#{has_sections}&"\
                   "future_terms=#{count}")
    end

    data["Courses"]
  end

  def section(year, quarter, curriculum, number, id)
    fix_param curriculum
    parse "course/#{year},#{quarter},#{curriculum},#{number}/#{id}.json"
  end

  def test_score(type, regid)
    parse "testscore/#{type},#{regid}.json"
  end

  def tests(regid)
    parse "testscore/#{regid}.json"
  end

  def enrollment(year, quarter, regid, verbose: "")
    parse "enrollment/#{year},#{quarter},#{regid}.json?verbose=#{verbose}"
  end

  def enrollments(regid, verbose: "")
    data = parse "enrollment.json?reg_id=#{regid}&verbose=#{verbose}"

    verbose.empty? ? data["EnrollmentLinks"] : data["Enrollments"]
  end

  def section_status(year, quarter, curric, course, id)
    fix_param curric

    parse "course/#{year},#{quarter},#{curric},#{course}/#{id}/status.json"
  end

  def person(regid)
    parse "person/#{regid}.json"
  end

  def people(type, id)
    parse "person.json?#{type}=#{id}"
  end

  def registration(year, quarter, curric, course, id, reg_id, dup_code = "")
    fix_param curric

    parse("registration/#{year},#{quarter},#{curric}," \
          "#{course},#{id},#{reg_id},#{dup_code}.json")
  end

  def registrations(year, quarter, curriculum: "", course: "",
                          section: "", reg_id: "", active: "",
                          reg_id_instructor: "")
    fix_param curriculum
    data = parse("registration.json?year=#{year}&"\
                 "quarter=#{quarter}&curriculum_abbreviation=#{curriculum}&"\
                 "course_number=#{course}&section_id=#{section}&"\
                 "reg_id=#{reg_id}&is_active=#{active}&"\
                 "instructor_reg_id=#{reg_id_instructor}")

    data["Registrations"]
  end

  def notice(regid)
    parse "notice/#{regid}.json"
  end

  def change_of_major(year, quarter, regid)
    parse "enrollment/#{year},#{quarter},#{regid}/major.json"
  end

  def finance(regid)
    parse "person/#{regid}/financial.json"
  end

  private

  def default_logger
    @logger = Logger.new(STDOUT)
    @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    @logger.level = Logger::FATAL

    @logger
  end

  def fix_param(param)
    unless param.to_s.empty?
      param.include?(" ") ? param.gsub!(" ", "%20") : param
      param.include?("&") ? param.gsub!("&", "%26") : param
    end
  end

  def parse(url)
    data = request "#{@base}#{url}"
    return nil unless !data.nil?
    data = clean data

    @last = JSON.parse data
    @logger.debug "fetched - #{@last}"
    @next = @last["Next"].nil? ? "" : @last["Next"]["Href"]

    @last
  end

  def request(url)
    cache_path = Dir.pwd + "/cache/" + Digest::MD5.hexdigest(url)

    data = get_cache(cache_path)
    if data.nil?
      restful_client(url).get do |response, request, result, &block|
        if response.code == 200
          set_cache(response, cache_path)
          data = response
        elsif response.code == 301
          response.follow_redirection(request, result, &block)
        elsif response.code == 401 ||
           (response.code == 500 &&
            response.to_s.include?("Sr-Course-Titles") && !@throw_HEPPS)
          # these should be reported to help@uw.edu
          # HEPPS errors for future courses, report to help@uw.edu
          # HEPPS errors for past courses are not fixable
          @logger.warn("#{url} - #{response.to_s}")
        elsif response.code == 404 && !@throw_404
          @logger.warn("#{url} - 404")
        else
          raise "Errors for #{url}\n#{response.to_s}"
        end
      end
    end

    data
  end

  def restful_client(url)
    RestClient::Resource.new(
      url,
      ssl_client_cert: OpenSSL::X509::Certificate.new(@cert_file),
      ssl_client_key: OpenSSL::PKey::RSA.new(@key_file),
      log: @logger)
  end

  def get_cache(file)
    if @use_cache && File.exist?(file)
      @logger.debug "Getting cache for #{file}"
      File.open(file).read
    else
      nil
    end
  end

  def set_cache(response, url)
    if @use_cache
      @logger.debug "Setting cache for #{url}"
      File.open(url, "w") { |f| f.write(response) }
    end
  end

  def load_config(cert, key)
    if ! (cert.empty? && key.empty?)
      does_exist? cert
      @cert_file = File.read cert
      does_exist? key
      @key_file  = File.read key
      @logger.debug "loaded cert and key files"
    end

    true
  end

  def does_exist?(file)
    raise "Could not find #{file}" unless File.exist? file
  end

  def clean_bools(data)
    data.gsub('"false"', "false")
    data.gsub('"true"', "true")
  end

  def clean_spaces(data)
    data.gsub!(/(\\?"|)((?:.(?!\1))+.)(?:\1)/) do |match|
      match.gsub(/^(\\?")\s+|\s+(\\?")$/, "\\1\\2").strip
    end
  end

  def clean(data)
    data = clean_spaces data
    data = clean_bools data
  end
end
