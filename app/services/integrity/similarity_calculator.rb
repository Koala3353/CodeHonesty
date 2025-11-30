# Calculates code similarity between submissions using tokenization
class Integrity::SimilarityCalculator
  SIMILARITY_THRESHOLD = 80  # Percentage threshold for flagging

  def initialize(submission1, submission2)
    @submission1 = submission1
    @submission2 = submission2
  end

  def calculate
    snapshots1 = @submission1.code_snapshots
    snapshots2 = @submission2.code_snapshots

    return nil if snapshots1.empty? || snapshots2.empty?

    # Compare all file pairs and find best matches
    similarities = []

    snapshots1.each do |s1|
      snapshots2.each do |s2|
        next unless same_file_type?(s1, s2)

        similarity = calculate_similarity(s1.content, s2.content)
        similarities << {
          file1: s1.file_path,
          file2: s2.file_path,
          similarity: similarity
        }
      end
    end

    return nil if similarities.empty?

    # Calculate overall similarity
    overall = similarities.map { |s| s[:similarity] }.sum.to_f / similarities.size

    {
      overall: overall.round(2),
      file_comparisons: similarities,
      matched_files: similarities.count { |s| s[:similarity] >= SIMILARITY_THRESHOLD }
    }
  end

  def calculate_and_save!
    result = calculate
    return nil unless result

    SimilarityReport.find_or_create_by!(
      submission: @submission1,
      compared_submission: @submission2
    ) do |report|
      report.similarity_score = result[:overall]
      report.matched_lines = count_matched_lines(result)
      report.report_data = result
    end
  end

  private

  def same_file_type?(s1, s2)
    ext1 = File.extname(s1.file_path).downcase
    ext2 = File.extname(s2.file_path).downcase
    ext1 == ext2
  end

  def calculate_similarity(content1, content2)
    return 0 if content1.blank? || content2.blank?

    tokens1 = tokenize(content1)
    tokens2 = tokenize(content2)

    return 0 if tokens1.empty? || tokens2.empty?

    # Calculate Jaccard similarity
    intersection = (tokens1 & tokens2).size
    union = (tokens1 | tokens2).size

    ((intersection.to_f / union) * 100).round(2)
  end

  def tokenize(content)
    # Remove comments and normalize whitespace
    normalized = content.gsub(/\/\/.*$/, "")           # Remove // comments
                       .gsub(/\/\*.*?\*\//m, "")       # Remove /* */ comments
                       .gsub(/#.*$/, "")               # Remove # comments
                       .gsub(/\s+/, " ")               # Normalize whitespace
                       .downcase

    # Split into tokens (words and symbols)
    normalized.scan(/[a-z_][a-z0-9_]*|\d+|[^\s]/)
  end

  def count_matched_lines(result)
    result[:file_comparisons]
      .select { |c| c[:similarity] >= SIMILARITY_THRESHOLD }
      .count
  end
end
