require "rails_helper"

RSpec.describe "SupportingDocument identify_batch", type: :model do
  def organization
    @organization ||= create_organization!(name: "ONG")
  end

  it "identify_batch two JPEGs overlap when IDENTIFY_THREADS is 2" do
    mutex = Mutex.new
    started = 0
    inflight = 0
    max_inflight = 0
    ready = ConditionVariable.new
    allow(PhotoSymbols.current).to receive(:scan).and_wrap_original do |method, **kwargs|
      mutex.synchronize do
        started += 1
        inflight += 1
        max_inflight = [ max_inflight, inflight ].max
        ready.broadcast
        Timeout.timeout(5) { ready.wait(mutex) while started < 2 }
      end
      result = method.call(**kwargs)
      mutex.synchronize { inflight -= 1 }
      result
    end

    items = with_env("IDENTIFY_THREADS" => "2") do
      SupportingDocument.identify_batch(
        organization: organization,
        files: [ photo_jpg("left.jpg"), photo_jpg("right.jpg") ]
      )
    end

    expect(max_inflight).to eq(2)
    expect(items.map { |item| item[:ok] }).to eq([ true, true ])
  end

  it "identify_batch two JPEGs are serial when IDENTIFY_THREADS is 1" do
    mutex = Mutex.new
    inflight = 0
    max_inflight = 0
    allow(PhotoSymbols.current).to receive(:scan).and_wrap_original do |method, **kwargs|
      mutex.synchronize do
        inflight += 1
        max_inflight = [ max_inflight, inflight ].max
      end
      sleep 0.05
      result = method.call(**kwargs)
      mutex.synchronize { inflight -= 1 }
      result
    end

    with_env("IDENTIFY_THREADS" => "1") do
      SupportingDocument.identify_batch(
        organization: organization,
        files: [ photo_jpg("left.jpg"), photo_jpg("right.jpg") ]
      )
    end

    expect(max_inflight).to eq(1)
  end

  it "IDENTIFY_THREADS 0 clamps to 1" do
    with_env("IDENTIFY_THREADS" => "0") do
      expect(SupportingDocument.identify_threads).to eq(1)
    end
  end

  it "IDENTIFY_THREADS 9 clamps to 8" do
    with_env("IDENTIFY_THREADS" => "9") do
      expect(SupportingDocument.identify_threads).to eq(8)
    end
  end

  it "IDENTIFY_THREADS unset uses 4" do
    with_env("IDENTIFY_THREADS" => nil) do
      expect(SupportingDocument.identify_threads).to eq(4)
    end
  end

  it "identify_batch wraps each file in the Rails executor" do
    wraps = 0
    allow(Rails.application.executor).to receive(:wrap).and_wrap_original do |method, &block|
      wraps += 1
      method.call(&block)
    end

    SupportingDocument.identify_batch(
      organization: organization,
      files: [ photo_jpg("left.jpg"), photo_jpg("right.jpg") ]
    )

    expect(wraps).to eq(2)
  end
end
