---
name: hindsight-churn
description: Invoke to absorb high-fidelity high-density information and retain it in Hindsight memory bank
---

# Skill: High-Fidelity Hindsight Memory

Hindsight applies **lossy compression** to large documents and repetitive structures, summarizing prose and stripping granular edge cases. To retain highly structured data (e.g., test matrices, configuration tables) without data loss, build a **Graph of Pointers** using **micro-facts**.

## Mechanics & Gotchas

- **Deduplication:** Hindsight hashes content. Retaining identical text with a new tag merges the chunk and drops the new tag. Ensure text uniqueness when updating.
- **Semantic Retrieval:** `xd://hindsight_recall` runs TEMPR (dense vector + BM25). Tags filter the boundary; the `query` matches the semantic intent. A tag alone cannot pull a 100-row table if the query lacks semantic alignment.
-  **Progressive Disclosure:** Isolate large document reconstruction to `xd://hindsight_knowledge` pages. Use `xd://hindsight_recall` exclusively for targeted, step-by-step fact retrieval.

## Ingestion Sequence

Execute these steps to memorize structured documents verbatim.

1.  **Extract the AST**
    Parse the source document using AST converters (`npx mammoth` for `.docx`, `pandoc`, or `jq`). Preserve table boundaries and list hierarchies. 
    *Completion: The document is flattened into a strict JSON Entity-Attribute-Value matrix or a clean Markdown list.*

2.  **Retain the Master Index**
    Write a single root node to `xd://hindsight_retain`. State the document structure and list the exact query hooks required to find the child rules.
    *Completion: Hindsight holds one Master Index fact linking to the upcoming micro-facts.*

3.  **Retain Micro-Facts**
    Iterate through the extracted matrix. Write each row as an isolated `xd://hindsight_retain` call. Inject a relational pointer (e.g., "Parent: Master Index") directly into the content string to force a semantic bond.
    *Completion: Every matrix row is successfully retained as an individual, fully-contextualized micro-fact.*

### Ingestion Example: Graph of Pointers Payload

```javascript
// Step 2: Master Index
await tool.write({
  path: "xd://hindsight_retain",
  content: JSON.stringify({
    content: "Master Index: Acme Test Plan. Contains 74 rules across 4 surfaces. Search 'QA Rule' to find constraints.",
    context: "Acme Master Index",
    tags: ["acme-matrix-v1", "master-index"],
    updateMode: "replace"
  })
});

// Step 3: Micro-Fact with Relational Pointer
await tool.write({
  path: "xd://hindsight_retain",
  content: JSON.stringify({
    // Notice the explicit "Parent" mapping injected into the text
    content: "QA Rule 5 of 74. Parent: Acme Master Index. Surface: Payment Link. Constraint: The minimum amount is 15,000 IDR.",
    context: "QA Rule 5",
    tags: ["acme-matrix-v1", "micro-fact"],
    updateMode: "replace"
  })
});
```

## Retrieval Sequence

Execute these steps to navigate a Graph of Pointers.

1.  **Locate the Root**
    Query `xd://hindsight_recall` for the document's Master Index. 
    *Completion: The Master Index is in context, exposing the taxonomy and specific query hooks for the child facts.*

2.  **Extract or Synthesize**
    *   **For targeted facts:** Execute hyper-specific `xd://hindsight_recall` queries using the hooks discovered in Step 1 (e.g., `query="Payment Link Minimum Amount"`).
    *   **For full reconstruction:** Trigger `xd://hindsight_knowledge` (`action: "create_page"`) with a `sourceQuery` instructing the background LLM to traverse the Master Index pointers and compile all child facts into a Markdown table.
    *Completion: The required verbatim facts are recovered and applied to the current task.*

### Retrieval Example: Knowledge Page Synthesis

```json
// Step 2: Full reconstruction payload to xd://hindsight_knowledge
{
  "action": "create_page",
  "name": "Acme Integration Test Matrix",
  "sourceQuery": "Using the 'Acme Master Index' and its 74 associated 'QA Rules', reconstruct the full QA constraints matrix. Group the rules clearly by their Surface. Extract all exact conditions (MUST Reject, MUST Success).",
  "tags": ["acme-matrix-v1"],
  "dryRun": false
}
```

