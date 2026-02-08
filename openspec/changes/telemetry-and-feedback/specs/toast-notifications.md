# Spec: Toast Notification System

## Overview

A React-based toast notification system for DevEnvManager-Tauri that provides immediate visual feedback for all user actions.

## Requirements

### Functional

| ID | Requirement |
|----|-------------|
| TN-1 | Display toast on operation success |
| TN-2 | Display toast on operation error |
| TN-3 | Display progress toast for long operations |
| TN-4 | Auto-dismiss success toasts after 3 seconds |
| TN-5 | Auto-dismiss error toasts after 5 seconds |
| TN-6 | Progress toasts persist until operation completes |
| TN-7 | Stack multiple toasts vertically |
| TN-8 | Limit stack to 5 visible toasts |
| TN-9 | Allow manual dismissal via click/swipe |
| TN-10 | Support optional action button on toast |

### Non-Functional

| ID | Requirement |
|----|-------------|
| TN-NF-1 | Toast appears within 50ms of trigger |
| TN-NF-2 | Smooth slide-in animation (200ms) |
| TN-NF-3 | Smooth fade-out animation (150ms) |
| TN-NF-4 | Industrial-brutalist visual style |
| TN-NF-5 | High contrast for accessibility |

## Scenarios

### Scenario: Success Toast

**Given** the user clicks "Validate"  
**When** the validation completes successfully  
**Then** a green success toast appears with message "Validation passed"  
**And** the toast auto-dismisses after 3 seconds

### Scenario: Error Toast

**Given** the user clicks "Update All"  
**When** the update fails with error "Network timeout"  
**Then** a red error toast appears with message "Update failed: Network timeout"  
**And** the toast auto-dismisses after 5 seconds

### Scenario: Progress Toast

**Given** the user clicks "Update All"  
**When** the update operation starts  
**Then** a blue progress toast appears with message "Updating tools..."  
**And** the progress bar updates as tools are updated  
**And** on completion, the progress toast is replaced with a success toast

### Scenario: Toast Stack

**Given** 3 toasts are currently displayed  
**When** a 4th toast is triggered  
**Then** the 4th toast appears at the bottom of the stack  
**And** all toasts are visible  
**And** the oldest toast moves up

### Scenario: Manual Dismiss

**Given** an error toast is displayed  
**When** the user clicks the X button  
**Then** the toast is immediately dismissed

## Component API

```typescript
// ToastContext.tsx
export const ToastProvider: React.FC<{ children: React.ReactNode }>;

export function useToast(): {
  // Add toast methods
  success: (title: string, message?: string) => void;
  error: (title: string, message?: string) => void;
  warning: (title: string, message?: string) => void;
  info: (title: string, message?: string) => void;
  
  // Progress toast (returns ID for updates)
  progress: (title: string, percent?: number) => string;
  updateProgress: (id: string, percent: number, message?: string) => void;
  
  // Generic add/remove
  addToast: (toast: ToastConfig) => string;
  removeToast: (id: string) => void;
};

// Toast.tsx
interface ToastProps {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info' | 'progress';
  title: string;
  message?: string;
  progress?: number;
  onDismiss: () => void;
  action?: {
    label: string;
    onClick: () => void;
  };
}
```

## Visual Design

```
┌────────────────────────────────────────────┐
│ ✓ VALIDATION PASSED                    [×] │
│   All 42 checks completed successfully     │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│ ✗ UPDATE FAILED                        [×] │
│   Network timeout after 30 seconds         │
│   [Retry]                                  │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│ ⟳ UPDATING TOOLS...                   [×] │
│   Installing bun@1.2.0...                  │
│   ████████████░░░░░░░░░░░░░░░░░░░░░ 35%   │
└────────────────────────────────────────────┘
```

## CSS Classes

| Class | Purpose |
|-------|---------|
| `.toast-container` | Fixed bottom-right container |
| `.toast` | Base toast styles |
| `.toast--success` | Green border/icon |
| `.toast--error` | Red border/icon |
| `.toast--warning` | Amber border/icon |
| `.toast--info` | Blue border/icon |
| `.toast--progress` | Blue with progress bar |
| `.toast-enter` | Slide-in animation |
| `.toast-exit` | Fade-out animation |

## Files

| File | Purpose |
|------|---------|
| `src/contexts/ToastContext.tsx` | Context provider and hook |
| `src/components/Toast.tsx` | Individual toast component |
| `src/components/ToastContainer.tsx` | Toast stack container |
| `src/styles/toast.css` | Styling |

## Test Cases

| ID | Test |
|----|------|
| TN-T1 | `success()` renders success toast |
| TN-T2 | `error()` renders error toast |
| TN-T3 | Success toast auto-dismisses after 3s |
| TN-T4 | Error toast auto-dismisses after 5s |
| TN-T5 | Progress toast updates on `updateProgress()` |
| TN-T6 | Max 5 toasts visible at once |
| TN-T7 | Manual dismiss removes toast immediately |
| TN-T8 | Action button triggers callback |
