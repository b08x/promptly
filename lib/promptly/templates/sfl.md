---
# --- Core Promptly Metadata ---
name: enhanced_support_reply
description: Generates an SFL-structured support email for billing issues.
variables: [customer_name, invoice_id, specific_charge]

# --- SFL: Ideational Metafunction (Field - What's happening?) ---
sfl_ideational:
  topic: Customer Billing Inquiry Response
  domain: SaaS Platform - Subscription Management
  entities:
    - Customer
    - Billing System
    - Support Agent
    - Subscription Plan
    - Invoice
    - Payment History
  processes:
    - Acknowledge
    - Empathize
    - Investigate
    - Explain
    - Resolve
    - Follow-up
  background_context: |
    A customer is questioning a specific charge on their latest invoice.
    They need a clear, empathetic, and accurate explanation.
  positive_constraints:
    - Must reference the invoice ID.
    - Must explain the charge clearly.
    - Must maintain a positive or neutral tone.
  data_sources:
    - Customer CRM Record
    - Stripe/Braintree Logs
    - Internal Usage Metrics
  output_goal: |
    Draft a professional email response that addresses the customer's
    concern, provides a clear explanation, and outlines the resolution
    or next steps.

# --- SFL: Interpersonal Metafunction (Tenor - Relationships & Stance) ---
sfl_interpersonal:
  intended_audience: End User (Potentially non-technical, possibly frustrated)
  tone: Empathetic, Professional, Confident, Helpful
  modality_rules:
    - process: Acknowledging Receipt
      certainty: high
      rationale: We received the query.
    - process: Stating Facts (e.g., plan details)
      certainty: high
      rationale: Based on system records.
    - process: Explaining Charge Cause
      certainty: medium_high # Adjust based on investigation clarity
      rationale: Based on analysis; state clearly but allow for Q&A.
    - process: Proposing Resolution
      certainty: high
      rationale: We will take this action.

# --- SFL: Textual Metafunction (Mode - How it's organized) ---
sfl_textual:
  output_format: Plain Text Email
  structure:
    - Salutation
    - Acknowledgement & Empathy
    - Explanation
    - Resolution / Next Steps
    - Closing
  cohesive_devices:
    - "Thank you for reaching out..."
    - "Regarding the charge for [specific_charge]..."
    - "Our investigation shows that..."
    - "Therefore, we have taken the following action..."
  transition_style: logical_sequence

# --- Pipeline/Chain Configuration ---
pipeline:
  chain_steps:
    - "1. Acknowledge customer query & invoice [invoice_id]."
    - "2. Look up [invoice_id] and [specific_charge]."
    - "3. Compare charge with subscription [Subscription Plan] and usage."
    - "4. Draft explanation using SFL_Ideational and SFL_Interpersonal."
    - "5. Format using SFL_Textual structure."
---

# --- Prompt Body (Can act as base template or final instructions) ---

Generate an email for {{customer_name}} about invoice {{invoice_id}}.

Use the context defined in the SFL front matter.
Focus on explaining {{specific_charge}}.
Follow all constraints, modality, and textual rules.
Execute the defined pipeline steps to structure your response.