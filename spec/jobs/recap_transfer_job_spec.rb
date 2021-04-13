require 'rails_helper'

RSpec.describe RecapTransferJob do
  describe ".perform" do
    before do
      Timecop.freeze(Time.local(2021, 4, 13, 3, 0, 0))
    end
    after do
      Timecop.return
    end
    it "transfers the given dump file" do
      dump_file = FactoryBot.create(:recap_incremental_dump_file)
      bucket_mock = instance_double(Scsb::S3Bucket)
      allow(Scsb::S3Bucket).to receive(:new).and_return(bucket_mock)
      allow(bucket_mock).to receive(:upload_file)

      described_class.perform_now(dump_file)

      expect(bucket_mock).to have_received(:upload_file).with(file_path: "data/1618308000", key: "1618308000")
    end
  end
end
