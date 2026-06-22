import 'dart:async';
import '../../models/ai_note_model.dart';
import 'ai_provider.dart';

class MockAiProvider implements AiProvider {
  @override
  Future<String> generateNotes({
    required String extractedText,
    required NoteType type,
  }) async {
    // Simulate network delay for AI processing
    await Future.delayed(const Duration(seconds: 3));

    // Return mock markdown formatted based on the requested note type
    switch (type) {
      case NoteType.summary:
        return '''# Short Summary
Based on the provided text, here is a concise summary:

The text discusses core concepts related to the subject matter. It highlights the importance of understanding the foundational principles and how they interact in practical applications.

**Key Takeaways:**
* Principle 1: Foundational building blocks.
* Principle 2: Practical implementation methods.
* Principle 3: Future outlook and advanced topics.''';
      
      case NoteType.detailed:
        return '''# Detailed Notes
Here are comprehensive notes derived from the text.

## 1. Introduction
The text introduces the topic by defining the scope and providing historical context. It is essential to understand where these concepts originated.

## 2. Core Mechanisms
* **Mechanism A**: Operates by transforming inputs into measurable outputs.
* **Mechanism B**: Serves as a regulatory framework to prevent system overload.

### Supporting Details
The relationship between these mechanisms can be described using the standard model of interaction, which states that A directly influences the efficiency of B under normal conditions.''';

      case NoteType.bulletPoints:
        return '''# Bullet Point Revision
* Focuses on foundational principles.
* Identifies two main mechanisms: A and B.
* Mechanism A: Transformation of inputs.
* Mechanism B: Regulatory framework.
* Both must operate synchronously for maximum efficiency.
* Historical context is vital for understanding modern applications.''';

      case NoteType.keyConcepts:
        return '''# Key Concepts
1. **Foundational Principles**: The baseline understanding required before advancing.
2. **Transformation (Mechanism A)**: The process of altering state based on defined rules.
3. **Regulation (Mechanism B)**: The system of checks and balances ensuring stability.
4. **Synchronicity**: The state where all mechanisms operate in harmony.''';

      case NoteType.definitions:
        return '''# Important Definitions
* **Transformation**: The induced change of state in a closed system.
* **Regulation**: The containment of variables within acceptable operational parameters.
* **Efficiency**: The ratio of useful work performed to total energy expended.
* **Synchronicity**: Simultaneous occurrence of causally related events.''';

      case NoteType.formulas:
        return '''# Formula Extraction
Based on the text, here are the key mathematical or logical formulas:

* **Efficiency (E)** = \\( \\frac{W_{out}}{W_{in}} \\times 100 \\)
* **Transformation Rate (T)** = \\( \\Delta S / \\Delta t \\)
* **Regulation Threshold (R)**: \\( R < T_{max} - 10\\% \\)''';

      case NoteType.examOriented:
        return '''# Exam-Oriented Notes
**Focus Areas for the Exam:**
1. Be able to define Transformation and Regulation.
2. Understand the interplay between Mechanism A and B.
3. Memorize the Efficiency formula.

**Probable Questions:**
* Q: How does Mechanism B prevent system overload?
* Q: Describe the relationship between inputs and outputs in Mechanism A.
* Q: Calculate efficiency given an input of 100J and an output of 80J.''';

      case NoteType.mcqs:
        return '''# MCQs for Practice

**1. What is the primary function of Mechanism A?**
A) Regulation
B) Transformation
C) Storage
D) Deletion
*Answer: B*

**2. Which mechanism acts as a regulatory framework?**
A) Mechanism A
B) Mechanism B
C) Mechanism C
D) None of the above
*Answer: B*

**3. Synchronicity refers to:**
A) Operating in isolation
B) Simultaneous occurrence of events
C) Random variations
D) Delayed reactions
*Answer: B*''';
    }
  }
}
