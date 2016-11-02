describe Fastlane::Actions::ApperianAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The apperian plugin is working!")

      Fastlane::Actions::ApperianAction.run(nil)
    end
  end
end
