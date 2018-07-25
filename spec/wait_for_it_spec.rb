require 'spec_helper'

describe WaitForIt do
  it 'has a version number' do
    expect(WaitForIt::VERSION).not_to be nil
  end

  it "sends TERM to child on exit" do
    options = { wait_for: "booted" }

    WaitForIt.new("ruby #{ fixture_path("never_exits.rb") }", options) do |spawn|
      spawn.send(:shutdown)
      count_before = spawn.count("running")
      sleep 1
      count_after = spawn.count("running")
      expect(count_before).to eq(count_after)
    end
  end

  it "raises an error if a process takes too long to boot" do
    expect {
      options = { timeout: 1, env: { SLEEP: 10 }, wait_for: "Done" }
      WaitForIt.new("ruby #{ fixture_path("sleep.rb") }", options) do |spawn|
        # never gets here
      end
    }.to raise_error(WaitForIt::WaitForItTimeoutError)
  end

  it "counts" do
    options = { env: { SLEEP: 0 }, wait_for: "Done" }
    WaitForIt.new("ruby #{ fixture_path("sleep.rb") }", options) do |spawn|
      expect(spawn.count("slept for 0")).to eq(1)
      expect(spawn.count("foo")).to eq(0)
    end
  end

  it "wait does not raise an error" do
    options = { env: { SLEEP: 0 }, wait_for: "Done" }
    WaitForIt.new("ruby #{ fixture_path("sleep.rb") }", options) do |spawn|
     expect(spawn.wait("foo", 1)).to eq(false)
     expect(spawn.wait("Done", 1)).to be_truthy
    end
  end

  it "contains?" do
    options = { env: { SLEEP: 0 }, wait_for: "Done" }
    WaitForIt.new("ruby #{ fixture_path("sleep.rb") }", options) do |spawn|
      expect(spawn.contains?("Started")).to be_truthy
      expect(spawn.contains?("foo")).to be_falsey
    end
  end

  describe 'wait!' do
    it 'raises if process takes too long too long' do
      expect {
        options = { env: { SLEEP: 100 }, wait_for: "Started"}
        WaitForIt.new("ruby #{ fixture_path("sleep.rb") }", options) do |spawn|
          spawn.wait!("Done", 1)
        end
      }.to raise_error(WaitForIt::WaitForItTimeoutError)
    end

    it 'does not raise an error' do
      options = { env: { SLEEP: 3 }, wait_for: "Started"}
      WaitForIt.new("ruby #{ fixture_path("sleep.rb") }", options) do |spawn|
        spawn.wait!("Done", 10)
      end
    end
  end
end
