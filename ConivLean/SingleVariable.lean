import ConivLean.Definitions

/-!
# Single-variable CON-IV moment algebra

The theorem named `singleVariable_identification` is a conditional moment identity: the supplied
relation `delta = theta * pi` is a substantive premise and is not derived from causal assumptions
in this module.
-/

namespace ConivLean

theorem singleVariable_identification {delta theta pi : ℝ}
    (hmoment : delta = theta * pi) (hpi : pi ≠ 0) :
    delta / pi = theta := by
  apply (div_eq_iff hpi).2
  exact hmoment

theorem singleVariable_bias {delta theta pi transportBias : ℝ}
    (hmoment : delta = theta * pi + transportBias) (hpi : pi ≠ 0) :
    delta / pi - theta = transportBias / pi := by
  rw [hmoment]
  field_simp [hpi]
  ring

theorem singleVariable_bias_eq_zero {delta theta pi : ℝ}
    (hmoment : delta = theta * pi) (hpi : pi ≠ 0) :
    delta / pi - theta = 0 := by
  rw [singleVariable_identification hmoment hpi]
  ring

end ConivLean
