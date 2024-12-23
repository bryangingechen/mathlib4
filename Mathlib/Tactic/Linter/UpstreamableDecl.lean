/-
Copyright (c) 2024 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa, Anne Baanen
-/
import ImportGraph.Imports
import Mathlib.Lean.Expr.Basic
import Mathlib.Tactic.MinImports

/-! # The `upstreamableDecl` linter

The `upstreamableDecl` linter detects declarations that could be moved to a file higher up in the
import hierarchy. This is intended to assist with splitting files.
-/

open Lean Elab Command

/-- Does this declaration come from the current file? -/
def Lean.Name.isLocal (env : Environment) (decl : Name) : Bool :=
  (env.getModuleIdxFor? decl).isNone

open Mathlib.Command.MinImports

/-- Does the declaration with this name depend on `def`s in the current file? -/
def Lean.Environment.localDefDependencies (env : Environment) (stx id : Syntax) :
    CommandElabM Bool := do
  let declName : NameSet ← try
    NameSet.ofList <$> resolveGlobalConst id
  catch _ =>
    pure ∅

  let immediateDeps ← getAllDependencies stx id

  -- Drop all the unresolvable constants, otherwise `transitivelyUsedConstants` fails.
  let immediateDeps : NameSet := immediateDeps.fold (init := ∅) fun s n =>
    if (env.find? n).isSome then s.insert n else s

  let deps ← liftCoreM <| immediateDeps.transitivelyUsedConstants
  let constInfos := deps.toList.filterMap env.find?
  let defs := constInfos.filter (·.isDef)
  return defs.any fun constInfo => !(declName.contains constInfo.name) && constInfo.name.isLocal env

namespace Mathlib.Linter

/--
The `upstreamableDecl` linter detects declarations that could be moved to a file higher up in the
import hierarchy. If this is the case, it emits a warning.

This is intended to assist with splitting files.

The linter does not place a warning on any declaration depending on a definition in the current file
(while it does place a warning on the definition itself), since we often create a new file for a
definition on purpose.
-/
register_option linter.upstreamableDecl : Bool := {
  defValue := false
  descr := "enable the upstreamableDecl linter"
}

namespace DoubleImports

@[inherit_doc Mathlib.Linter.linter.upstreamableDecl]
def upstreamableDeclLinter : Linter where run := withSetOptionIn fun stx ↦ do
    unless Linter.getLinterValue linter.upstreamableDecl (← getOptions) do
      return
    if (← get).messages.hasErrors then
      return
    if stx == (← `(command| set_option $(mkIdent `linter.upstreamableDecl) true)) then return
    let env ← getEnv
    let id ← getId stx
    if id != .missing then
      let minImports := getIrredundantImports env (← getAllImports stx id)
      match minImports with
      | ⟨(RBNode.node _ .leaf upstream _ .leaf), _⟩ => do
        if !(← env.localDefDependencies stx id) then
          let p : GoToModuleLinkProps := { modName := upstream }
          let widget : MessageData := .ofWidget
            (← liftCoreM <| Widget.WidgetInstance.ofHash
              GoToModuleLink.javascriptHash <|
              Server.RpcEncodable.rpcEncode p)
            (toString upstream)
          Linter.logLint linter.upstreamableDecl id
            m!"Consider moving this declaration to the module {widget}."
      | _ => pure ()

initialize addLinter upstreamableDeclLinter

end DoubleImports

end Mathlib.Linter
