require "minitest/autorun"
require "json"
require "logger"
require_relative "../lib/uw_student_webservice"

describe UwStudentWebservice do
  before do
    log       = Logger.new("log.txt")
    log.level = Logger::FATAL
    @uw       = UwStudentWebService.new(logger: log)
  end

  def terms
    [:winter, :spring, :summer, :autumn]
  end

  describe "when asked for campus " do
    it "must return at least 3 of them" do
      data = @uw.campus
      campus = data["Campuses"]
      campus.size.must_be :>, 2
    end
  end

  describe "web checking last RESTful respone " do
    it "it must not be nil" do
      @uw.term(1921, terms[0])
      @uw.last.wont_be_nil
    end
  end

  describe "web asked for terms " do
    it "must respond with a FirstDay" do
      data = @uw.term(2013, terms[2])
      data["FirstDay"].wont_be_nil
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

  describe "when asked for curriculumn " do
    it "must return at least 5 of them" do
      @uw.curricula(1999, terms[0], department: "B A").size.must_be :>, 5
    end
  end

  describe "when asked for all curricula in a year " do
    it "must return at least 100 of them" do
      # note...this can timeout if too many future terms are requested
      @uw.curricula(1990, terms[3]).size.must_be :>, 99
    end
  end

  # section searches
  #   instructor or curriculumn are required
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
      @uw.sections(2000, curriculum: "engl", quarter: "autumn")
                  .size.must_be :>, 5
    end
  end

  describe "when asked for future sections " do
    it "must return at 898 of them" do
      @uw.sections(2000, curriculum: "engl", quarter: "autumn", count: 3)
                  .size.must_equal(898)
    end
  end

  describe "when asked for sections in a course " do
    it "must return at least 2 of them" do
      @uw.sections(1992, curriculum: "OPMGT", quarter: "winter",
                   course_num: 301).size.must_be :>, 2
    end
  end

  describe "when asked for sections an instructor is teaching " do
    it "must return at least 1 of them" do
      @uw.sections(2009, instructor: "78BE067C6A7D11D5A4AE0004AC494FFE",
                   quarter: terms[2]).size.must_be :>, 0
    end
  end

  # course searches
  #   cirric is not needed if searching by course number
  #   future terms must be 0-2, but, must be zero if exclude course w/o section
  #   make sure to page larger results using page_size and page_start
  #     while !@uw.next.nil?
  #        get result, append, next
  #   the following query string attributes dont seem to work
  #     course_title_starts, course_title_contains,

  describe "when asked for courses in a curriculm " do
    it "must return at least 10 of them" do
      @uw.courses(1985, "winter", curriculum: "GEOG").size.must_be :>, 9
    end
  end

  describe "when asked for courses having number = 100 " do
    it "must return at least 10 of them" do
      @uw.courses(1985, "winter", course: 100).size.must_be :>, 9
    end
  end

  describe "when asked for courses having number = 100 with future terms " do
    it "must return at least 10 of them" do
      @uw.courses(2013, "winter", course: 100, count: 2).size.must_be :>, 9
    end
  end

  describe "when asked for courses in a curriculm having sections " do
    it "must return at least 5 of them" do
      @uw.courses(2005, "autumn", curriculum: "ENGL", has_sections: "on")
                  .size.must_be :>, 5
    end
  end

  describe "when paging courses in a curriculm " do
    it "must have a url that indicates next page" do
      # this particular curric has 107 courses
      # ideally, you would want to join results until .next is empty
      @uw.courses(1985, "autumn", curriculum: "GEOG", size: 25)
      @uw.next.wont_be_empty
      @uw.courses(nil, nil, get_next: true).size.must_equal(25)
      @uw.courses(nil, nil, get_next: true).size.must_equal(25)
      @uw.courses(nil, nil, get_next: true).size.must_equal(25)
      @uw.courses(nil, nil, get_next: true).size.must_equal(7)
      @uw.next.must_be_empty
    end
  end

  describe "when asked for courses without sections " do
    it "must return less than with sections" do
      @uw.courses(1985, "autumn", curriculum: "GEOG", size: 150)
      count_with = @uw.last["TotalCount"]

      @uw.courses(1985, "autumn", curriculum: "GEOG", size: 150,
                  has_sections: "on")
      count_without = @uw.last["TotalCount"]

      count_with.must_be :>, count_without
    end
  end

  #
  # remaining public endpoints
  #
  describe "when asked for a course " do
    it "must return course data" do
      data = @uw.course(1992, "autumn", "CSE", 142)
      data["FirstEffectiveTerm"].wont_be_empty
    end
  end

  describe "when asked for a section " do
    it "must have 8 enrolled" do
      # who were these first 8 to take this infamous course?
      # I took it in 2002...it was C++ then
      data = @uw.section(1992, "autumn", "CSE", 142, "AA")
      data["CurrentEnrollment"].must_equal("8")
    end
  end

  describe "when asked to test a section with a zero start room number " do
    it "must return without error" do
      @uw.section(2010, "spring", "ARTS", 150, "A").wont_be_nil
    end
  end
end
