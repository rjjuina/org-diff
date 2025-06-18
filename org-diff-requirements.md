# org-diff Requirements Document

## Project Overview

**Project Name:** org-diff  
**Type:** Emacs Plugin/Package  
**Purpose:** Inline text comparison within org-mode code blocks using org-mode's template expansion system  
**Target Users:** Emacs org-mode users who need to compare text snippets directly within their documents

## Core Feature

### Template Expansion
- Type `<diff` followed by TAB to expand into a diff code block
- Generated structure:
  ```org
  #+begin_diff
  
  #+end_diff
  ```

### Diff Checking Command
- Command: `org-diff-check` (callable via `M-x org-diff-check`)
- Analyzes the diff block at cursor position
- Compares all lines within the block

### Comparison Logic
- Compare each line against every other line in the block
- Identify which lines are identical and which have differences
- Character-level difference detection

### Result Display
- **Inline Highlighting**: Differences are highlighted directly in the original text using overlays
- **Visual Feedback**:
  - Different/changed characters: Bold with colored background
  - Identical lines: Dimmed or grayed out
  - Clear visual distinction between matching and non-matching content
- **Example**:
  ```
  line1: Hello world     (normal - reference)
  line2: Hello world     (dimmed - identical to line1)
  line3: Hi world        ("Hi" is bold/highlighted)
  line4: Hello world!    ("!" is bold/highlighted)
  ```

### Basic Commands
- `M-x org-diff-check` - Run diff analysis on current block
- `M-x org-diff-clear` - Clear all diff highlighting

## Non-Functional Requirements

### Performance
- Instant comparison for typical use cases (up to 50 lines)
- Minimal memory overhead

### Usability
- Zero configuration needed
- Works immediately after installation
- Clear visual feedback

### Compatibility
- **Emacs 31** (emacs-plus@31 via Homebrew)
- **org-mode 9.0+**
- Works with standard org-mode installation

## Technical Constraints
- Use built-in Emacs facilities (no external dependencies)
- Leverage org-mode's existing template system
- Use overlays for non-destructive highlighting

## Success Criteria
- Template expansion works seamlessly
- Differences are clearly visible
- No disruption to normal org-mode workflow
- Instant feedback on text differences