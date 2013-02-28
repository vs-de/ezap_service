require_relative('./init_test.rb')

context "global master service" do
  #helper :mock
  setup do
    @gms_thread = Thread.new do 
      Ezap::Service::GlobalMaster.start
    end
  end
  asserts('a service can be started and connect') do
    srv = Ezap::Service::Base.new
    srv.gm_request(['shutdown'])
  end
  asserts('joining threads'){@gms_thread.join}

end
