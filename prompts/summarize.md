---
name: summarize
description: Summarizes text content into key points
variables: 
  - text
  - max_points
---

# Text Summarization Prompt

Please summarize the following text into the most important key points:

**Text to summarize:**
{{text}}

**Requirements:**
- Extract the {{max_points}} most important points
- Use clear, concise language
- Maintain the original meaning and context
- Format as a numbered list

**Summary:**
