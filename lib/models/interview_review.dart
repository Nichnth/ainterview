class InterviewReview {
  const InterviewReview({
    required this.summary,
    required this.communicationFeedback,
    required this.technicalFeedback,
    required this.improvementAreas,
    required this.recommendations,
  });

  final String summary;
  final String communicationFeedback;
  final String technicalFeedback;
  final List<String> improvementAreas;
  final List<String> recommendations;
}
