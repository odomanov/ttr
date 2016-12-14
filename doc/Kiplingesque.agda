{-# OPTIONS --no-positivity-check #-}
module Kiplingesque where

open import Data.Product
open import Data.Sum
open import Data.Unit

mutual
  data U : Set where
    `Π : (S : U) → (El S → U) → U
    _`∧_ : (S : U) → (T : U) → U
    _`∨_ : (S : U) → (T : U) → U
    `U : U -- optional but fun!
  El : U → Set
  El (`Π S T)=(s : El S) → El (T s)
  El `U = U
  El (S `∧ T) = El S × El T
  El (S `∨ T) = El S ⊎ El T

data _⊑_ : U -> U -> Set where
  meetL : ∀ {S S' T} -> S ⊑ T -> (S `∧ S') ⊑ T
  joinL : ∀ {S S' T} -> S ⊑ T -> S' ⊑ T -> (S `∨ S') ⊑ T
  -- etc.

convert : ∀ {A B} -> A ⊑ B -> El A -> El B
convert (meetL p) (x , _) = convert p x
convert (joinL p q) (inj₁ x) = convert p x
convert (joinL p q) (inj₂ y) = convert q y

mutual
  data Cx : Set where
    — : Cx
    _,_ : (Γ : Cx) → (Env Γ -> U) → Cx

  Env : Cx -> Set
  Env — = ⊤
  Env (Γ , A) = Σ (Env Γ) (λ x → El (A x))


Typ : Cx -> Set
Typ Γ = (ρ : Env Γ) -> U

data _∋_ : (Γ : Cx) (T : Typ Γ) -> Set where
  here : ∀ {Γ T} -> (Γ , T) ∋ (λ x → T (proj₁ x))
  there : ∀ {Γ T S} -> Γ ∋ T -> (Γ , S) ∋ (λ x → T (proj₁ x))

lk : ∀ {Γ T} -> Γ ∋ T -> (ρ : Env Γ) -> El (T ρ)
lk here (_ , v) = v
lk (there i) (ρ , _) = lk i ρ

data _⊢_ : (Γ : Cx) -> Typ Γ -> Set
data _⊢Type : (Γ : Cx) -> Set
eval : ∀ {Γ A} -> (ρ : Env Γ) -> Γ ⊢ A -> El (A ρ)
evalTyp : ∀ {Γ} -> (ρ : Env Γ) -> Γ ⊢Type -> U


data _⊢_  where
  var : ∀ {Γ T} -> Γ ∋ T -> Γ ⊢ T
  app : ∀ {Γ A} {B : Typ (Γ , A)} ->
        Γ ⊢ (λ ρ → `Π (A ρ) (λ x → B (ρ , x))) -> (u : Γ ⊢ A) ->
        Γ ⊢ (λ ρ → B ( ρ , eval ρ u ))
  lam : ∀ {Γ A} {B : Typ (Γ , A)} ->
        (Γ , A) ⊢ B ->
        Γ ⊢ (λ ρ → `Π (A ρ) (λ x → (B (ρ , x))))
  typ : ∀ {Γ} -> Γ ⊢Type -> Γ ⊢ (λ ρ → `U)
  conv : ∀ {Γ} {A B : Typ Γ} -> Γ ⊢ A -> ((ρ : Env Γ) -> A ρ ⊑ B ρ) -> Γ ⊢ B

data _⊢Type where
  Pi : ∀ {Γ} -> (A : Γ ⊢Type) -> (Γ , (λ ρ → evalTyp ρ A)) ⊢Type
                 -> Γ ⊢Type
  Type : ∀ {Γ} -> Γ ⊢Type
  Elim : ∀ {Γ} -> (A : Γ ⊢ (λ ρ → `U)) -> Γ ⊢Type
  Meet : ∀ {Γ} -> Γ ⊢Type -> Γ ⊢Type -> Γ ⊢Type

evalTyp ρ (Pi A B) = `Π (evalTyp ρ A) (λ x → evalTyp (ρ , x) B)
evalTyp _ Type = `U
evalTyp ρ (Meet A B) = evalTyp ρ A `∧ evalTyp ρ B
evalTyp ρ (Elim A) = eval ρ A

eval ρ (var x) = lk x ρ
eval ρ (app t u) = eval ρ t (eval ρ u)
eval ρ (lam t) = λ x → eval (ρ , x) t
eval ρ (typ T) = evalTyp ρ T
eval ρ (conv t s) = convert (s ρ) (eval ρ t)