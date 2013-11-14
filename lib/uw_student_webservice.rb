require "restclient"
require "logger"
require "json"
require_relative "uw_student_webservice/version"

class UwStudentWebService
  attr_reader :last, :next

  def initialize(throw_404: true, logger: Logger.new(STDOUT),
                 use_cache: true, cert: "", key: "")
    @base             = "https://ws.admin.washington.edu/student/v4/public/"
    @base_private     = "https://ws.admin.washington.edu/student/v4/"
    @last             = nil
    @next             = ""
    @use_cache        = use_cache
    @logger           = logger
    @throw_404        = throw_404
    @private_endpoint = false
    load_config(cert, key)
  end

  def campus
    parse("#{endpoint}campus.json")
  end

  def colleges(campus)
    data = parse("#{endpoint}college.json?campus_short_name=#{campus}")

    data["Colleges"]
  end

  def departments(college)
    fix_param(college)
    data = parse("#{endpoint}department.json?college_abbreviation=#{college}")

    data["Departments"]
  end

  def curricula(year, quarter, department: "", count: 0)
    fix_param(department)
    data = parse("#{endpoint}curriculum.json?year=#{year}&quarter=#{quarter}"\
                 "&future_terms=#{count}&department_abbreviation=#{department}")

    data["Curricula"]
  end

  def course(year, quarter, curriculum, number, is_private: false)
    fix_param(curriculum)
    data = parse("#{endpoint(is_private)}course/#{year},#{quarter},"\
                 "#{curriculum},#{number}.json")
    data
  end

  def term(year, quarter)
    parse("#{endpoint}term/#{year},#{quarter}.json")
  end

  def sections(year, curriculum: "", instructor: "",
               count: 0, quarter: "", course_num: "", is_private: false)
    fix_param(curriculum)
    data = parse("#{endpoint(is_private)}section.json?year=#{year}"\
                 "&quarter=#{quarter}&curriculum_abbreviation=#{curriculum}"\
                 "&future_terms=#{count}&course_number=#{course_num}"\
                 "&reg_id=#{instructor}")

    data["Sections"]
  end

  def courses(year, quarter, curriculum: "", course: "", has_sections: "",
              size: 100, start: "", count: "", get_next: false)
    if get_next
      url = @next.sub("student/v4/public/", "")
      data = parse("#{endpoint}#{url}")
    else
      fix_param(curriculum)
      data = parse("#{endpoint}course.json?&year=#{year}&quarter=#{quarter}"\
                   "&curriculum_abbreviation=#{curriculum}&"\
                   "course_number=#{course}&page_size=#{size}"\
                   "&page_start=#{start}"\
                   "&exclude_courses_without_sections=#{has_sections}&"\
                   "future_terms=#{count}")
    end

    data["Courses"]
  end

  def section(year, quarter, curriculum, number, id, is_private: false)
    fix_param(curriculum)
    data = parse("#{endpoint(is_private)}course/#{year},#{quarter}," \
                 "#{curriculum},#{number}/#{id}.json")

    data
  end

  #
  # these are for UW stff/faculty only, authentcation required
  # other methods that have is_private: as a param option can call
  # the private endpoint as well as the public endpoint
  #

  def test_score(type, regid)
    parse("#{endpoint(true)}testscore/#{type},#{regid}.json")
  end

  def enrollment_search(regid, verbose: "")
    data = parse("#{endpoint(true)}enrollment.json?reg_id=#{regid}"\
                 "&verbose=#{verbose}")

    verbose.empty? ? data["EnrollmentLinks"] : data["Enrollments"]
  end

  def enrollment(year, quarter, regid, verbose: "")
    parse("#{endpoint(true)}enrollment/#{year},#{quarter},#{regid}.json"\
          "?verbose=#{verbose}")
  end

  def section_status(year, quarter, curric, course, id)
    fix_param(curric)

    parse("#{endpoint(true)}course/#{year},#{quarter},#{curric}," \
          "#{course}/#{id}/status.json")
  end

  def term_private(year, quarter)
    parse("#{endpoint(true)}term/#{year},#{quarter}.json")
  end

  def person(regid)
    parse("#{endpoint(true)}person/#{regid}.json")
  end

  def person_search(type, id)
    parse("#{endpoint(true)}person.json?#{type}=#{id}")
  end

  def registration(year, quarter, curric, course, id, reg_id, dup_code = "")
    fix_param(curric)

    parse("#{endpoint(true)}registration/#{year},#{quarter},#{curric}," \
          "#{course},#{id},#{reg_id},#{dup_code}.json")
  end

  def registration_search(year, quarter, curriculum: "", course: "",
                          section: "", reg_id: "", active: "",
                          reg_id_instructor: "")
    fix_param(curriculum)
    data = parse("#{endpoint(true)}registration.json?year=#{year}&"\
                 "quarter=#{quarter}&curriculum_abbreviation=#{curriculum}&"\
                 "course_number=#{course}&section_id=#{section}&"\
                 "reg_id=#{reg_id}&is_active=#{active}&"\
                 "instructor_reg_id=#{reg_id_instructor}")

    data["Registrations"]
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

  def endpoint(is_private = false)
    @private_endpoint = is_private

    is_private ? @base_private : @base
  end

  def parse(url)
    data = request(url)
    return nil unless !data.nil?
    data = clean(data)

    @last = JSON.parse(data)
    @logger.info "fetched - #{@last}"
    @next = @last["Next"].nil? ? "" : @last["Next"]["Href"]

    @last
  end

  def request(url)
    cache_path = Dir.pwd + "/cache/#{url.gsub('/', '')}"

    data = get_cache(cache_path)
    if data.nil?
      restful_client(url).get do |response, request, result, &block|
        if response.code == 200
          set_cache(response, cache_path)
          data = response
        elsif response.code == 301
          response.follow_redirection(request, result, &block)
        elsif (response.code == 401 ||
           (response.code == 500 && response.to_s.include?("Sr-Course-Titles")))
          # these should be reported to help@uw.edu
          # HEPPS errors for future courses, report to help@uw.edu
          # HEPPS errors for past courses are not fixable
          @logger.fatal("#{url} - #{response.to_s}")
        elsif response.code == 404 && !@throw_404
          @logger.fatal("#{url} - 404 - #{response.to_s}")
        else
          raise "Errors for #{url}\n#{response.to_s}"
        end
      end
    end

    data
  end

  def restful_client(url, is_private: false)
    if @private_endpoint
      RestClient::Resource.new(
        url,
        :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(@cert_file),
        :ssl_client_key   =>  OpenSSL::PKey::RSA.new(@key_file),
        :log              =>  @logger
      )
    else
      RestClient::Resource.new(url, :log =>  @logger)
    end
  end

  def get_cache(file)
    if @use_cache && File.exist?(file)
      @logger.info "Getting cache for #{file}"
      File.open(file).read
    else
      nil
    end
  end

  def set_cache(response, url)
    if @use_cache
      @logger.info "Setting cache for #{url}"
      File.open(url, "w") { |f| f.write(response) }
    end
  end

  def load_config(cert, key)
    if ! (cert.empty? && key.empty?)
      does_exist?(cert)
      @cert_file = File.read(cert)
      does_exist?(key)
      @key_file  = File.read(key)
      @logger.info "loaded cert and key files"
    end

    true
  end

  def does_exist?(file)
    raise "Could not find #{file}" unless File.exist?(file)
  end

  def clean_bools(data)
    data.gsub('"false"', 'false')
    data.gsub('"true"', 'true')
  end

  def clean_spaces(data)
    data.gsub! /(\\?"|)((?:.(?!\1))+.)(?:\1)/ do |match|
      match.gsub(/^(\\?")\s+|\s+(\\?")$/, "\\1\\2").strip
    end
  end

  def clean(data)
    data = clean_spaces(data)
    data = clean_bools(data)
  end
end
