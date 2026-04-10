# BugFix: EditorFormSync Hook Finds Wrong Editor

## The Problem

When the Backpex admin form had **two ExEditorWeb.LiveEditor components** (code field and args field), the `EditorFormSync` JavaScript hook would incorrectly sync values between them. Specifically:

- The **args field would be populated with the code field's value**
- This happened because the hook always found the **FIRST** editor in the form
- With multiple editors, it could never distinguish which one it was supposed to sync with

### Root Cause

In `demo/assets/js/hooks/editor_form_sync.js`, the `findEditor()` function used:

```javascript
const editor = formContainer.querySelector(`[phx-hook="EditorHook"]`);
```

This finds the FIRST matching element in the entire form. When two editors exist (code and args), both hooks would find the code editor (the first one), causing cross-contamination.

## The Fix

**File Modified**: `demo/assets/js/hooks/editor_form_sync.js`

**Strategy**: Instead of searching the entire form, the hook now searches for the editor in a **specific context**:

1. **First**: Search in preceding sibling elements (the editor is rendered just before the hidden input)
2. **Second**: Search in the closest parent "field" container
3. **Third**: Search the form but find the editor that comes before the hidden input in document order
4. **Fallback**: If only one editor exists on the page, use it

### Key Changes

```javascript
// OLD (buggy):
const editor = formContainer.querySelector(`[phx-hook="EditorHook"]`);

// NEW (fixed):
// 1. Check preceding siblings first
let current = hiddenInput.previousElementSibling;
while (current) {
  const editor = current.querySelector(`[phx-hook="EditorHook"]`);
  if (editor) return editor;  // Found the right editor!
  current = current.previousElementSibling;
}

// 2. Check field container with cardinality check
const fieldContainer = hiddenInput.closest("div[class*='field']");
const editorsInContainer = fieldContainer.querySelectorAll(`[phx-hook="EditorHook"]`);
if (editorsInContainer.length === 1) {
  return editorsInContainer[0];  // Only one editor - it's the right one
}

// ... more strategies ...
```

## Tests Added

### 1. Multiple LiveEditor Component Tests
**File**: `test/ex_editor_web/live_editor_multiple_instances_test.exs`

Tests that verify the LiveEditor component itself properly isolates each instance:
- Each instance maintains its own content ✓
- Each instance has separate hook instances ✓
- Each instance has unique gutter elements ✓
- Component state is scoped per instance ✓
- Each component receives debounce settings separately ✓

### 2. Backpex Form Sync Tests
**File**: `demo/test/demo_web/live/admin/backpex_form_sync_regression_test.exs`

Tests that verify EditorFormSync works correctly with multiple editors:
- Code and args fields have separate EditorFormSync hooks ✓
- Each editor displays correct initial content ✓
- Code textarea contains code, not JSON ✓
- Args textarea contains JSON, not code ✓
- Values are maintained separately ✓

### 3. Multiple Editors in Form Tests
**File**: `demo/test/demo_web/live/admin/code_snippet_multiple_editors_test.exs`

Tests that verify the form structure supports multiple editors:
- Both code and args editors are rendered ✓
- Each editor has correct ID (`editor_code`, `editor_args`) ✓
- Hidden inputs correspond to correct editors ✓

## Verification

**Before Fix**:
```
Code field: Shows "defmodule MyApp.Counter do..."
Args field: Shows "defmodule MyApp.Counter do..." (WRONG! Should show JSON)
```

**After Fix**:
```
Code field: Shows "defmodule MyApp.Counter do..."
Args field: Shows {"debug":false,"initial_value":0,"timeout":5000} (CORRECT!)
```

## Test Results

- ✅ Demo tests: 30 tests, 0 failures
- ✅ ExEditor library tests: 290 tests (5 for multiple instances), 0 failures
- ✅ All regression tests passing

## Impact

This fix ensures that when using multiple ExEditorWeb.LiveEditor components in the same Backpex form:
- Each editor maintains its own value
- Form submission includes correct values for both fields
- No cross-contamination between fields
- JavaScript hooks are properly scoped to their corresponding editors
