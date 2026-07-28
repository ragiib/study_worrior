import '../../models/ai_note_model.dart';
import 'package:flutter/foundation.dart';

class PromptManager {
  /// Returns the appropriate prompt for the given [NoteType] and [text].
  static String getPrompt(NoteType type, String text) {
    debugPrint('PromptManager: Selecting template for NoteType.${type.name}');
    
    switch (type) {
      case NoteType.summary:
        return _getSummaryPrompt(text);
      case NoteType.detailed:
        return _getDetailedPrompt(text);
      case NoteType.bulletPoints:
        return _getRevisionPrompt(text);
      case NoteType.keyConcepts:
        return _getKeyConceptsPrompt(text);
      case NoteType.definitions:
        return _getDefinitionsPrompt(text);
      case NoteType.formulas:
        return _getFormulasPrompt(text);
      case NoteType.examOriented:
        return _getExamOrientedPrompt(text);
      case NoteType.mcqs:
        return _getMcqsPrompt(text);
      default:
        // Handle unsupported note types gracefully by falling back to detailed notes
        debugPrint('PromptManager: Unsupported note type, falling back to Detailed template.');
        return _getDetailedPrompt(text);
    }
  }

  static String _getSummaryPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and generate a concise chapter summary.
Focus on main ideas.
Keep output short and easy to revise.

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String _getDetailedPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and generate comprehensive notes.
Explain all important concepts.
Preserve chapter structure.

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String _getRevisionPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and generate exam-focused revision material in bullet points.
Highlight important facts and formulas.
Keep content optimized for quick review.

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String _getKeyConceptsPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and extract important concepts only.
Provide short explanations for each concept.

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String _getDefinitionsPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and extract definitions and meanings.
Format clearly for study.

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String _getFormulasPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and extract any formulas or equations.
Explain what each formula is used for and what its variables mean.

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String _getExamOrientedPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and create exam-oriented study notes highlighting what to focus on, along with probable questions.
Include:
1. Important Exam Points
2. Probable Questions

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String _getMcqsPrompt(String text) {
    return '''
You are an expert educational assistant.

Read the chapter carefully and generate Multiple Choice Questions (MCQs) with the correct answers based on the text.
Provide the correct answer with a short explanation for each question.

Use simple student-friendly language.
Focus on exam preparation.
Do not omit important information.
Format your response entirely in Markdown. Do not include introductory conversational text.

Chapter Content:
$text
''';
  }

  static String getDoubtSolverPrompt(String text, String question) {
    return '''
You are an expert educational assistant. A student has uploaded an image of their study material and has a specific question about it.

First, here is the text extracted from the student's image:
---
$text
---

The student's question is: "$question"

Please answer the student's question based primarily on the extracted text.
Use simple, student-friendly language with clear explanations, examples, important points, and step-by-step reasoning when useful.
If the text doesn't contain enough information to fully answer the question, you can use your general knowledge, but always refer back to the text where possible.
Format your response entirely in Markdown. Do not include introductory conversational text like "Here is the answer".
''';
  }

  static String getVoiceTeacherPrompt(String userSpeech) {
    return '''
You are an expert, encouraging, and friendly Voice Teacher for a student.
The student has just spoken to you.

Student said: "$userSpeech"

Respond to the student in a clear, concise, and conversational manner.
Your response will be read aloud by a Text-to-Speech (TTS) engine, so:
- Avoid formatting like bold, italics, markdown tables, or complex lists.
- Avoid long, complicated sentences.
- Speak naturally and engagingly.
- Keep the answer relatively short (a few sentences to a couple of paragraphs max) unless they specifically ask for a long explanation.
''';
  }
}
