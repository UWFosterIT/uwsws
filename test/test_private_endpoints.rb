require "minitest/autorun"
require "json"
require "logger"
require_relative "../lib/uw_student_webservice"

describe UwStudentWebservice do
  before do
    log       = Logger.new("log.txt")
    log.level = Logger::FATAL

    cert = "/home/marc/.keys/milesm.bschool.pem"
    key = "/home/marc/.keys/ItsAllGood.key"
    @regid = "DB79E7927ECA11D694790004AC494FFE"
    @uw  = UwStudentWebService.new(cert: cert, key: key, logger: log,
                                   use_cache: true)
  end

  #
  # all of these test are for private endpoints
  # they require that you initialize the service with a cert
  # and a key file as they are required for all of these tests.
  # Simply delete this test if you want your rake to pass and are
  # not using these endpoints
  #
  describe "when getting test score private endpoint " do
    it "it must not be nil" do
      @uw.test_score("SAT", "9136CCB8F66711D5BE060004AC494FFE")
      @uw.last.wont_be_nil
    end
  end

  describe "when getting term private endpoint " do
    it "it must not be nil" do
      @uw.term_private(2013, "autumn")
      @uw.last.wont_be_nil
    end
  end

  describe "when getting section status private endpoint " do
    it "it must not be nil" do
      # this endpoint requires extra permissions that I dont have
      # @uw.section_status(2009, "winter", "MUSAP", 218, "A")
      # @uw.last.wont_be_nil
    end
  end

  describe "when getting sections private endpoint " do
    it "must return at least 5 of them" do
      @uw.sections(1999, curriculum: "OPMGT", is_private: true)
                   .size.must_be :>, 5
    end
  end

  describe "when getting a section private endpoint " do
    it "must have 8 enrolled" do
      data = @uw.section(1992, "autumn", "CSE", 142, "AA", is_private: true)
      data["CurrentEnrollment"].must_equal("8")
    end
  end

  describe "when getting a course private endpoint " do
    it "must return course data" do
      data = @uw.course(1992, "autumn", "CSE", 142, is_private: true)
      data["FirstEffectiveTerm"].wont_be_empty
    end
  end

  describe "when getting a person private endpoint " do
    it "must not be nil" do
      @uw.person(@regid)
      @uw.last.wont_be_nil
    end
  end

  describe "when doing a search for a person private endpoint " do
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

  describe "when doing an enrollment search private endpoint " do
    it "it must equal 2" do
      @uw.enrollment_search(@regid).size.must_equal(2)
    end
  end

  describe "when doing a verbose enrollment search private endpoint " do
    it "it must have 2" do
      @uw.enrollment_search(@regid, verbose: "on").size.must_equal(2)
    end
  end

  describe "when getting a grade within an enrollment private endpoint " do
    it "it must equal 3.9" do
      data = @uw.enrollment(2002, "summer", @regid, verbose: "on")
      data["Registrations"][0]["Grade"].must_equal("3.9")
    end
  end

  #
  # NOTE ABOUT REGISTRATION SEARCHES
  # THEY ONLY WORK WITH CURRENT TERMS....
  # these tests will fail unless the params are in the present year/quarter
  #
  describe "when getting a registration private endpoint " do
    it "it must not be nil" do
      @uw.registration(2013, "autumn", "CSE", 142, "A",
                       "6ADA93ABA771476481FE44FC086C74DA")
      @uw.last.wont_be_nil
    end
  end

  describe "when searching for active course registrations private endpoint " do
    it "it must be between 200 and 320" do
      data = @uw.registration_search(2013, "autumn",  curriculum: "CSE",
                                     course: 142, section: "A", active: "on")
      data.size.must_be :>, 200
      data.size.must_be :<, 320
    end
  end

  describe "when searching for course registrations private endpoint " do
    it "it must be between 650 and 702" do
      data = @uw.registration_search(2013, "autumn",  curriculum: "CSE",
                                     course: 142, section: "A")
      data.size.must_be :>, 650
      data.size.must_be :<, 702
    end
  end

  describe "when searching for person registrations private endpoint " do
    it "it must have more than 10" do
      @uw.registration_search(2013, "autumn",
                              reg_id: "6ADA93ABA771476481FE44FC086C74DA")
         .size.must_be :>, 10
    end
  end
end
