import Lean
import Solution

open Lean Meta Elab Command

run_elab do
  let env ← getEnv
  let some (.thmInfo theoremInfo) := env.find? `solution
    | throwError "solution must be a theorem"
  let correct ← isDefEq theoremInfo.type (mkConst `Problem.Statement)
  unless correct do
    throwError "solution has the wrong statement"
  let allowed := #[`propext, `Classical.choice, `Quot.sound]
  let axioms ← collectAxioms `solution
  for axiomName in axioms do
    unless allowed.contains axiomName do
      throwError "Disallowed axiom: {axiomName}"
  logInfo m!"Verified solution. Axioms: {axioms}"
