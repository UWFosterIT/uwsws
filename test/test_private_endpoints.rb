require "minitest/autorun"
require "json"
require "logger"
require_relative "../lib/uw_sws"

describe UwSws do
  before do
    log       = Logger.new("log.txt")
    log.level = Logger::FATAL

    cert   = "/home/marc/.keys/milesm.bschool.pem"
    key    = "/home/marc/.keys/ItsAllGood.key"
    @regid = "DB79E7927ECA11D694790004AC494FFE"
    @uw    = UwSws.new(cert: cert, key: key, throw_HEPPS: false,
                       logger: log, use_cache: true)
  end

  describe "when getting test scores " do
    it "it must not be nil" do
      @uw.test_score("SAT", "9136CCB8F66711D5BE060004AC494FFE")
      @uw.last.wont_be_nil
    end
  end

  describe "when getting term " do
    it "it must not be nil" do
      @uw.term(2013, :summer)
      @uw.last.wont_be_nil
    end
  end

  describe "when getting terms " do
    it "must respond with a FirstDay" do
      data = @uw.term(2013, :summer)
      data["FirstDay"].wont_be_nil
    end
  end

  describe "when getting section status " do
    it "it must not be nil" do
      # this endpoint requires extra permissions that I don't have
      # @uw.section_status(2009, "winter", "MUSAP", 218, "A")
      # @uw.last.wont_be_nil
    end
  end

  describe "when getting sections " do
    it "must return at least 5 of them" do
      @uw.sections(1999, curriculum: "OPMGT").size.must_be :>, 5
    end
  end

  describe "when getting a course " do
    it "must return course data" do
      data = @uw.course(1992, :autumn, "CSE", 142)
      data["FirstEffectiveTerm"].wont_be_empty
    end
  end

  describe "when getting a person " do
    it "must not be nil" do
      @uw.person(@regid)
      @uw.last.wont_be_nil
    end
  end

  describe "when doing a search for a person " do
    it "each must not be nil" do
      @uw.person_search("reg_id", @regid)
      @uw.last.wont_be_nil
      @uw.person_search("net_id", "milesm")
      @uw.last.wont_be_nil
      @uw.person_search("student_number", "0242267")
      @uw.last.wont_be_nil
      @uw.person_search("employee_id", "864004999")
      @uw.last.wont_be_nil
    end
  end

  describe "when doing an enrollment search " do
    it "it must equal 2" do
      @uw.enrollment_search(@regid).size.must_equal(2)
    end
  end

  describe "when doing a verbose enrollment search " do
    it "it must have 2" do
      @uw.enrollment_search(@regid, verbose: "on").size.must_equal(2)
    end
  end

  describe "when getting a grade within an enrollment " do
    it "it must equal 3.9" do
      data = @uw.enrollment(2002, :summer, @regid, verbose: "on")
      data["Registrations"][0]["Grade"].must_equal("3.9")
    end
  end

  #
  # NOTE ABOUT REGISTRATION SEARCHES
  # THEY ONLY WORK WITH CURRENT TERMS....
  # these tests will fail unless the params are in the present year/quarter
  #
  describe "when getting a registration " do
    it "it must not be nil" do
      # since registrations are not available for prev terms
      # make this a current year and valid regid
      #
      #term = @uw.term_current
      #@uw.registration(term["Year"], term["Quarter"], "CSE", 142, "A",
      #                 "6ADA93ABA771476481FE44FC086C74DA")
      #@uw.last.wont_be_nil
    end
  end

  describe "when searching for active course registrations " do
    it "it must be greater than 100" do
      term = @uw.term_current
      data = @uw.registration_search(term["Year"], term["Quarter"],
                                     curriculum: "CSE", course: 142,
                                     section: "A", active: "on")
      data.size.must_be :>, 100
    end
  end

  describe "when searching for course registrations " do
    it "it must be greater than 200" do
      term = @uw.term_current
      data = @uw.registration_search(term["Year"], term["Quarter"],
                                     curriculum: "CSE", course: 142,
                                     section: "A")
      data.size.must_be :>, 200
    end
  end

  describe "when searching for person registrations " do
    it "it must have more than 10" do
      # since registrations are not available for prev terms
      # make this a current year and valid regid
      #
      #@uw.registration_search(2013, "autumn",
      #                        reg_id: "6ADA93ABA771476481FE44FC086C74DA")
      #   .size.must_be :>, 10
    end
  end


  describe "when getting campus list " do
    it "must return at least 3 of them" do
      data = @uw.campus
      campus = data["Campuses"]
      campus.size.must_be :>, 2
    end
  end

  describe "when checking last response " do
    it "it must not be nil" do
      @uw.term(1921, :winter)
      @uw.last.wont_be_nil
    end
  end


  describe "when asked for the current, next and previous terms " do
    it "each must respond with a FirstDay" do
      @uw.term_current["FirstDay"].wont_be_nil
      @uw.term_next["FirstDay"].wont_be_nil
      @uw.term_previous["FirstDay"].wont_be_nil
    end
  end

  describe "when asked for colleges " do
    it "must return at least 10 of them" do
      @uw.colleges("SEATTLE").size.must_be :>, 9
    end
  end

  describe "when asked for departments " do
    it "must return at least 12 of them" do
      @uw.departments("A & S").size.must_be :>, 11
    end
  end

  describe "when asked for curriculum " do
    it "must return at least 5 of them" do
      @uw.curricula(1999, :winter, department: "B A").size.must_be :>, 5
    end
  end

  describe "when asked for all curricula in a year " do
    it "must return at least 100 of them" do
      # note...this can timeout if too many future terms are requested
      @uw.curricula(1990, :autumn).size.must_be :>, 99
    end
  end

  # section searches
  #   instructor or curriculum are required
  #   year is also required
  #   with no quarter you get all quarters
  #   quarter is required if searching by instructor
  describe "when asked for sections " do
    it "must return at least 5 of them" do
      @uw.sections(1999, curriculum: "OPMGT").size.must_be :>, 5
    end
  end

  describe "when asked for sections in a quarter " do
    it "must return at least 5 of them" do
      @uw.sections(2000, curriculum: "engl", quarter: :autumn)
                  .size.must_be :>, 5
    end
  end

  describe "when asked for future sections " do
    it "must return at 898 of them" do
      @uw.sections(2000, curriculum: "engl", quarter: :autumn, count: 3)
                  .size.must_equal(898)
    end
  end

  describe "when asked for sections in a course " do
    it "must return at least 2 of them" do
      @uw.sections(1992, curriculum: "OPMGT", quarter: :winter,
                   course_num: 301).size.must_be :>, 2
    end
  end

  describe "when asked for sections an instructor is teaching " do
    it "must return at least 1 of them" do
      @uw.sections(2009, instructor: "78BE067C6A7D11D5A4AE0004AC494FFE",
                   quarter: :summer).size.must_be :>, 0
    end
  end

  describe "when asked for section with a HEPPS error " do
    it "must respond with error 500" do
      @uw.section(2013, :autumn, "PB AF", 521, "A").must_be_nil
    end
  end
  # course searches
  #   curric is not needed if searching by course number
  #   future terms must be 0-2, but, must be zero if exclude course w/o section
  #   make sure to page larger results using page_size and page_start
  #     while !@uw.next.nil?
  #        get result, append, next
  #   the following query string attributes dont seem to work
  #     course_title_starts, course_title_contains,

  describe "when asked for courses in a curriculum " do
    it "must return at least 10 of them" do
      @uw.courses(1985, :winter, curriculum: "GEOG").size.must_be :>, 9
    end
  end

  describe "when asked for courses having number = 100 " do
    it "must return at least 10 of them" do
      @uw.courses(1985, :winter, course: 100).size.must_be :>, 9
    end
  end

  describe "when asked for courses having number = 100 with future terms " do
    it "must return at least 10 of them" do
      @uw.courses(2013, :winter, course: 100, count: 2).size.must_be :>, 9
    end
  end

  describe "when asked for courses in a curriculum having sections " do
    it "must return at least 5 of them" do
      @uw.courses(2005, :autumn, curriculum: "ENGL", has_sections: "on")
                  .size.must_be :>, 5
    end
  end

  describe "when paging courses in a curriculum " do
    it "must have a url that indicates next page" do
      # this particular curric has 107 courses
      # ideally, you would want to join results until .next is empty
      @uw.courses(1985, :autumn, curriculum: "GEOG", size: 25)
      @uw.next.wont_be_empty
      @uw.courses(nil, nil, get_next: true).size.must_equal(25)
      @uw.courses(nil, nil, get_next: true).size.must_equal(25)
      @uw.courses(nil, nil, get_next: true).size.must_equal(25)
      @uw.courses(nil, nil, get_next: true).size.must_equal(7)
      @uw.next.must_be_empty
    end
  end

  describe "when asked for a section " do
    it "must have 8 enrolled" do
      # who were these first 8 to take this infamous course?
      # I took it in 2002...it was C++ then
      data = @uw.section(1992, :autumn, "CSE", 142, "AA")
      data["CurrentEnrollment"].must_equal(8)
    end
  end

  describe "when asked to test a section with a zero start room number " do
    it "must return without error" do
      @uw.section(2010, "spring", "ARTS", 150, "A").wont_be_nil
    end
  end
end
