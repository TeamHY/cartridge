import 'package:uuid/uuid.dart';

class Quiz {
  final String id;
  String question;
  List<String> choices;
  int answerIndex;
  bool isOpenEnded;
  String? imagePath;
  String openAnswer;
  List<String?> choiceImages;

  Quiz({
    String? id,
    required this.question,
    required this.choices,
    required this.answerIndex,
    this.isOpenEnded = false,
    this.imagePath,
    this.openAnswer = '',
    List<String?>? choiceImages,
  })  : id = id ?? const Uuid().v4(),
        choiceImages = choiceImages ??
            List<String?>.filled(choices.length, null, growable: true);

  factory Quiz.empty() {
    return Quiz(
      question: '',
      choices: List<String>.filled(5, '', growable: true),
      answerIndex: 0,
    );
  }

  Iterable<String> get imagePaths => [
        imagePath,
        ...choiceImages,
      ].whereType<String>();

  bool get _hasContent => question.trim().isNotEmpty || imagePath != null;

  bool get isComplete {
    if (!_hasContent) return false;
    if (isOpenEnded) return true;
    if (choices.length < 2) return false;
    for (var i = 0; i < choices.length; i++) {
      final hasImage = i < choiceImages.length && choiceImages[i] != null;
      if (choices[i].trim().isEmpty && !hasImage) return false;
    }
    return answerIndex >= 0 && answerIndex < choices.length;
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>).cast<String>().toList();
    final images =
        (json['choiceImages'] as List<dynamic>?)?.cast<String?>() ?? const [];
    return Quiz(
      id: json['id'],
      question: json['question'],
      choices: choices,
      answerIndex: json['answerIndex'],
      isOpenEnded: json['isOpenEnded'] ?? false,
      imagePath: json['imagePath'],
      openAnswer: json['openAnswer'] ?? '',
      choiceImages: List<String?>.generate(
        choices.length,
        (i) => i < images.length ? images[i] : null,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'choices': choices,
      'answerIndex': answerIndex,
      'isOpenEnded': isOpenEnded,
      'imagePath': imagePath,
      'openAnswer': openAnswer,
      'choiceImages': choiceImages,
    };
  }
}
