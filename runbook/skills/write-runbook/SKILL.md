---
name: write-runbook
description: Create or review a runbook — an executable procedure someone else follows from top to bottom without judgment of their own. "runbook", "RUNBOOK.md", "手順書", "作業依頼" で起動。
metadata:
  author: pokutuna
---

# Write Runbook

Create a concise procedure that runs from top to bottom without judgment from the person running it.

Three parties are involved. Keep them distinct:

- **The requester**: makes the request, so that the work gets done without them doing it. They can answer your questions while you write.
- **The author**: you. You turn the request into a procedure, and you settle every decision the procedure needs. You're gone by the time it runs.
- **The executor**: follows the procedure to reach the intended result. Might be the requester, a colleague, or another agent. You can't ask them anything, and they can't ask you.

Unless the request says otherwise, assume the executor brings no familiarity with the system, no background knowledge, and no one to ask. Every decision the runbook needs is already settled in the document — either you resolved it as you wrote, or it's a branch whose condition the executor can evaluate by observation.

## Prepare

1. Inspect the request and relevant code, configuration, and documentation. Treat existing runbooks as references; don't edit them unless the request asks for it.
2. Separate the intended effect from runbook completion. Define completion by observable artifacts, outputs, or states. Reaching a state the procedure names as an end — the change wasn't needed, a precondition ruled the work out, the observation came back negative — completes the runbook. Give each such ending its own observable condition, so the executor knows they arrived rather than gave up.
3. Resolve choices from decisions the requester has already made and from repository context. Ask the requester when a missing choice materially changes the execution path. Don't leave such a choice to the executor: a confirmation item, an open question, or an instruction to check with someone isn't a resolution, and the executor has no one to ask.
4. Separate the choices that belong to the requester from the ones that belong to you. Performance targets, acceptance policy, strategy, and permission to act are theirs, so don't invent them. That the requester named a fix doesn't establish that the executor may apply it, and describing a step as out of scope doesn't settle who decides it. Wait limits, observation intervals, and retry counts are yours: pick a value the executor can check by observation, and say what it's based on. Prefer a comparison between two things the executor can observe over a number you had to pick.
5. Identify non-obvious invariants that must survive retries or troubleshooting.
6. If a script already exists for substantial loops, aggregation, or repeated mechanics, have the executor invoke it and keep the runbook focused on checking its result. If none exists, write the steps out, and never cite a script that doesn't exist. Propose one separately if it's worth having, and implement it only if the request includes implementation. Conditions the executor evaluates by observation are branches, not mechanics to move into a script.

## Write

- State the purpose and concrete completion conditions near the start.
- Put shared execution context once before the steps: environment, working directory, setup, session persistence, and reconnection when relevant.
- Organize the normal path into ordered phases or steps. For each meaningful checkpoint, state what must be observed before continuing.
- Allow placeholders for values produced by earlier steps or provided to the executor at run time. Make their source and later use clear where they appear. Never use a placeholder where a decision belongs; settle the decision instead.
- Write branches as explicit conditions with a specific next action, skip, retry, or stop. State what the executor observes to tell the conditions apart — the value, output, or state to look at, and which way each reading leads. Keep the main path readable from top to bottom.
- Cover two kinds of failure separately: undoing an effect the runbook already produced, and getting a stalled step to proceed. Include the guidance you actually know for each, and say when it doesn't exist. Preserve invariants and resume from the failed phase when possible.
- Place checks at trust, destructive, costly, or provenance-sensitive boundaries. Don't repeat checks whose result remains valid.
- Keep design history, completed-work logs, and lengthy rationale outside the runbook; link them when useful.
- Use headings that fit the task. Don't add empty sections or require a fixed template, status field, or completion-report schema. Don't tailor the format to a presumed audience, because you don't know who executes the runbook. A place to record a value the steps produce is part of the procedure, not a template field.

## Review

Confirm each of the following before handing the runbook over:

- The stated completion conditions are observable.
- Commands and paths are grounded in the current repository or in what the request provides.
- Common prerequisites appear once, not in every step.
- Each branch has an actionable consequence and states what to observe to choose between them.
- No decision is left to the executor, whether as an unresolved choice dressed up as an instruction, a confirmation item, an open question, a placeholder, or a step that asks them to judge what is appropriate.
- Nothing is assumed about who executes the runbook.
- Every value you picked yourself is one the executor can check, and nothing you settled — a value, a permission, or a scope boundary — stands in for a choice the requester owns.
- Defensive checks are proportional and don't obscure the normal path.
- The document holds current instructions rather than accumulated experiment history.

For a review-only request, report findings and suggested changes without editing. When the request asks for edits, preserve unrelated content and scope.
