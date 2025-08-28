# Plan for LLM Guardian Module

This document outlines a plan to improve the LLM Guardian module for the chatbot. The goal is to ensure the chatbot only answers questions related to cybersecurity, robotics, vendor products, and standardization.

## Current Implementation

The current system uses a node named `AI Language Model3` as a guardian. It uses a zero-shot prompt to classify the user's query as either relevant ("true") or not relevant ("false"). A Switch node then routes the query based on this classification.

This is a good starting point, but we can improve its accuracy and robustness.

## Proposed Improvements (Proof of Concept)

Here are two alternative approaches to enhance the guardian module. We can start with one and iterate.

### Option 1: Few-Shot Prompting

This approach provides the model with examples to improve its classification accuracy.

**Concept:**
By showing the LLM examples of in-scope and out-of-scope questions, it can better learn the boundaries of the allowed topics.

**Implementation Steps:**
1.  **Update the prompt of `AI LanguageModel3`:** Add a section with examples.

    **Example new prompt:**
    ```
    You are a topic classifier. Your task is to determine if the following user query is related to any of these topics: cybersecurity, robotics, vendor products, or standardization.

    Here are some examples of queries that are IN scope:
    - "What are the latest trends in phishing attacks?" (cybersecurity)
    - "Can you explain the NIST cybersecurity framework?" (standardization, cybersecurity)
    - "Tell me about the capabilities of the UR5 robot arm." (robotics, vendor product)
    - "What are the differences between ISO 27001 and SOC 2?" (standardization)

    Here are some examples of queries that are OUT of scope:
    - "What's the weather like today?"
    - "Can you tell me a joke?"
    - "Who won the world cup in 1998?"

    User Query:
    "{{ $('Message Processor').item.json.messageText }}"

    Respond with "true" if the query is related to any of the allowed topics, and "false" otherwise. Do not provide any other explanation or text.
    ```
2.  **No other changes needed:** The rest of the workflow can remain the same.

### Option 2: Structured JSON Output with Reasoning

This approach makes the model's output more reliable and easier to work with. It also provides more context for logging and debugging.

**Concept:**
Instead of a plain "true" or "false", we ask the model to return a JSON object containing the classification, the identified category, and its reasoning.

**Implementation Steps:**
1.  **Update the prompt of `AI Language Model3`:** Modify the prompt to request a JSON output.

    **Example new prompt:**
    ```
    You are a highly intelligent topic classification assistant. Your task is to analyze the user's query and determine if it falls into one of the following categories: "cybersecurity", "robotics", "vendor_product", "standardization". If it does not fit any of these, classify it as "none".

    User Query:
    "{{ $('Message Processor').item.json.messageText }}"

    Provide your response as a JSON object with the following structure:
    {
      "is_relevant": <true or false>,
      "category": <"cybersecurity" | "robotics" | "vendor_product" | "standardization" | "none">,
      "reasoning": "<A brief explanation of your classification decision.>"
    }
    ```
2.  **Update the `Is Question Relevant?` Switch Node:** The switch node needs to be updated to read the `is_relevant` field from the JSON output of the guardian. The condition should be changed to check `{{ $('AI Language Model3').first().json.is_relevant }}`.

## Recommendation

For a proof of concept, **Option 1 (Few-Shot Prompting)** is the simplest to implement and often provides a significant improvement in accuracy over zero-shot classification.

**Option 2 (Structured JSON Output)** is a more robust and scalable solution that I would recommend as the next step after validating the initial PoC. It will make the system more maintainable in the long run.

Let me know which direction you'd like to explore, and I can help you with the next steps.
