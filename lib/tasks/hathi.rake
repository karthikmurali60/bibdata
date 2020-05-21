namespace :hathi do
  
  desc "compact hathi overlap report to only include files that overlap"
  task compact_overlap: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR'] 
      Hathi::CompactOverlap.perform
      output_file = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: 'overlap*compacted.tsv', date_pattern: 'overlap_%Y%m%d_compacted.tsv')
      sorted_file = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(output_file).gsub('.tsv','_sorted.tsv'))
      `sort -t$'\t' -k 1n #{output_file} > #{sorted_file}`
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end
  end

  desc 'Compact hathi_full file to include only the identifier and the oclc'
  task compact_full: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR'] 
      Hathi::CompactFull.compact_full
      output_file = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'], pattern: 'hathi_full*compacted.tsv', date_pattern:"hathi_full_%Y%m%d_compacted.tsv")
      sorted_file = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(output_file).gsub('.tsv','_sorted.tsv'))
      `sort -t$'\t' -k 2n #{output_file} > #{sorted_file}`
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end  
  end

  desc 'Combine Hathi_full and Hathi_overlap_compact files'
  task merge: :environment do
    if ENV['HATHI_INPUT_DIR'] && ENV['HATHI_OUTPUT_DIR'] 
      sorted_file1 = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'],pattern: 'overlap*sorted.tsv', date_pattern: 'overlap_%Y%m%d_compacted_sorted.tsv')
      sorted_file2 = Hathi::CompactFull.get_hathi_file(directory: ENV['HATHI_OUTPUT_DIR'],pattern: 'hathi_full*sorted.tsv', date_pattern:"hathi_full_%Y%m%d_compacted_sorted.tsv")
      hathi_final = File.join(ENV['HATHI_OUTPUT_DIR'], File.basename(sorted_file1).gsub('.tsv','_final.tsv'))
      `join -t$'\t' -1 1 -2 2 #{sorted_file1} #{sorted_file2} > #{hathi_final}`
    else
      puts "Environment variable HATHI_INPUT_DIR & HATHI_OUTPUT_DIR must be set!"
    end
  end  
end
