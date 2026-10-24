# AI Usage Log

**Disclosure policy:** an interactive LLM-based coding assistant was used as a
*support tool only*. Per the author's policy the vendor/model identifier is not named.
Every influential usage event is recorded below, including mistakes the assistant made
and the human corrections applied. All final decisions and verification are the author's.

## Entry 01
### Date
2026-10-08
### Student
Mulatef Aldahia
### Tool
Interactive LLM-based coding assistant (model not named)
### Purpose
Diagnose why validation mAP50 looked excellent (0.930) while the per-class table
showed only 19 of 37 classes.
### Prompt Summary
Asked the assistant to audit the augmentation/remapping pipeline for silent label loss.
### AI Suggestions
- Copy label files verbatim instead of remapping class ids
- Add a mandatory per-split coverage guardrail before training
- Re-annotate the dataset from scratch
### Accepted Suggestions
- Verbatim label copy
- Coverage guardrail (abort if any learnable class missing in any split)
### Rejected Suggestions
- Full re-annotation
### Reason for Rejection
Root cause was a pipeline bug (2,664 dropped val boxes), not annotation quality.
### Human Review
Author verified val box count returned to 9,749 and re-ran training (v6).

## Entry 02
### Date
2026-10-12
### Student
Mulatef Aldahia
### Tool
Interactive LLM-based coding assistant (model not named)
### Purpose
Explain why a 494px crop yielded only 8 detections at imgsz=1280.
### Prompt Summary
Asked for root-cause analysis of resolution sensitivity at inference.
### AI Suggestions
- Adopt size rule: longest side >1200px → imgsz=1280, else → 320
- Use multi-scale test-time averaging
### Accepted Suggestions
- The size rule (documented in README and app code)
### Rejected Suggestions
- Multi-scale TTA
### Reason for Rejection
Latency and complexity unsuitable for the mobile APK.
### Human Review
Author validated 75/75 boxes on the crop and ~300 boxes on a full page after applying the rule.

## Entry 03
### Date
2026-10-15
### Student
Mulatef Aldahia
### Tool
Interactive LLM-based coding assistant (model not named)
### Purpose
Fix two-column pages being read as merged single lines.
### AI Suggestions
- Split columns at the largest horizontal gap (>8% of page width) before line grouping
- Build a full layout-analysis parser
### Accepted Suggestions
- Column split heuristic
### Rejected Suggestions
- Full layout parser
### Reason for Rejection
Out of scope for this version (SRS §5).
### Human Review
Author confirmed 36 lines recovered on a two-column test page.

## Entry 04
### Date
2026-10-20
### Student
Mulatef Aldahia
### Tool
Interactive LLM-based coding assistant (model not named)
### Purpose
Debug Gradio demo crashes (OpenCV scalar-color error; missing Unicode font).
### Prompt Summary
Asked for fixes to drawing code and font handling.
### AI Suggestions
- Cast colors to native int before cv2 calls
- Render labels with PIL + fallback font list instead of cv2.putText
### Accepted Suggestions
- Both fixes
### Rejected Suggestions
- Removing class labels from the visualization
### Reason for Rejection
Labels are essential for qualitative evaluation.
### Human Review
Author re-ran the demo; 75 labeled boxes rendered correctly.

## Entry 05
### Date
2026-10-24
### Student
Mulatef Aldahia
### Tool
Interactive LLM-based coding assistant (model not named)
### Purpose
Structure the Mini-SRS, README, and edge-case enumeration for the course deliverables.
### Prompt Summary
Asked the assistant to propose FR/NFR phrasing and realistic edge cases.
### AI Suggestions
- 7 FRs / 5 NFRs / 8 edge cases aligned with measured system behaviour
- Add out-of-scope list (translation, Glagolitic, cloud mode)
### Accepted Suggestions
- FR/NFR set and edge cases after manual verification against real metrics
### Rejected Suggestions
- Claims of accuracy beyond measured values
### Reason for Rejection
Documentation must report only measured numbers (mAP50=0.878, R=0.861).
### Human Review
Author cross-checked every number against training logs before committing.