module Cypress
  class ClinicalRandomizer
    def self.randomize(record, random: Random.new)
      return case random.rand(3)
             when 0
               split_by_date(record, random)
             default
               split_by_date(record, random)
             end
    end

    def self.split_by_date(record, random)
      record_1 = record.clone
      record_2 = record.clone
      split_date = find_split_date(record, random)
      # sort the entries from earliest to latest so we can split them more easily
      entries = record.entries.sort { |x, y| x.start_time.nil? ? -1 : y.start_time.nil? ? 1 : x.start_time <=> y.start_time }
      Record::Sections.each do |section|
        record_1.send section.to_s + "=", []
        record_2.send section.to_s + "=", []
      end
      entries.take_while { |ent| ent.start_time < split_date }.each do |ent|
        record_1.send(ent._type.tableize).push ent
      end
      require 'pry'
      binding.pry
      # record_2.entries = entries.drop_while { |ent| ent.start_time <= split_date }
      [record_1, record_2]
    end

    def self.find_split_date(record, random)
      entries = record.entries.sort { |x, y| x.start_time <=> y.start_time }
      first_date = find_first_date_after(entries, record.bundle.measure_period_start)
      last_date = find_last_date_before(entries, record.bundle.effective_date)
      (last_date - first_date) * random.rand + first_date
    end

    def self.find_first_date_after(entries, date)
      entries.detect { |ent| ent.start_time > date }.start_time
    end

    def self.find_last_date_before(entries, date)
      entries.each_cons(2) do |ents|
        return ents[0].start_time if ents[1].start_time > date
      end
      return entries.last.start_time
    end
  end
end
