import Mathlib.Tactic.Linter.UnusedTactic
import Mathlib.Tactic.AdaptationNote

example (h : 0 + 1 = 0) : False := by
  change 1 = 0 at h
  simp at h

example : 0 + 1 = 1 := by
  change 1 = 1
  rfl

/--
warning: 'change 1 = 1' tactic does nothing
note: this linter can be disabled with `set_option linter.unusedTactic false`
-/
#guard_msgs in
example : 1 = 1 := by
  change 1 = 1
  rfl

def why2 : True → True := (by refine ·)

example : True := by
  #adaptation_note /-- hi -/
  exact .intro

-- both `;` and `<;>` are unseen by the linter
example : True ∧ True := by
  constructor <;> trivial;

set_option linter.unusedTactic true
/--
warning: 'congr' tactic does nothing
note: this linter can be disabled with `set_option linter.unusedTactic false`
---
warning: 'done' tactic does nothing
note: this linter can be disabled with `set_option linter.unusedTactic false`
-/
#guard_msgs in
-- the linter notices that `congr` is unused
example : True := by
  congr
  constructor
  done

section allowing_more_unused_tactics
--  test that allowing more unused tactics has the desired effect of silencing the linter
#allow_unused_tactic Lean.Parser.Tactic.done Lean.Parser.Tactic.skip

#guard_msgs in
example : True := by
  skip
  constructor
  done

end allowing_more_unused_tactics
