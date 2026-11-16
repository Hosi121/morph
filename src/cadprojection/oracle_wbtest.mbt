// Generated independent SymPy Matrix.det and permutation-determinant oracle.

///|
test "arbitrary arity independent full Collins 0" {
  one_step_fixture(@oracle.nat(1), @oracle.chain([]), ProjectionCertificate::{
    arity: @oracle.nat(1),
    atoms: @oracle.chain([]),
    coefficients: @oracle.chain([]),
    reducta: @oracle.chain([]),
    principal: @oracle.chain([]),
  })
}

///|
test "arbitrary arity independent full Collins 1" {
  one_step_fixture(
    @oracle.nat(1),
    @oracle.chain([
      elimination_poly(1, []),
      elimination_poly(1, [(elimination_rat(true, "2", "3"), [0])]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(1),
      atoms: @oracle.chain([
        elimination_poly(1, []),
        elimination_poly(1, [(elimination_rat(true, "2", "3"), [0])]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(0, []),
        elimination_poly(0, [(elimination_rat(true, "2", "3"), [])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([]),
        @oracle.chain([
          elimination_poly(1, [(elimination_rat(true, "2", "3"), [0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(1, [(elimination_rat(true, "2", "3"), [0])]),
          right: elimination_poly(1, []),
          values: @oracle.chain([
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 2" {
  one_step_fixture(
    @oracle.nat(2),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(2),
      atoms: @oracle.chain([
        elimination_poly(2, [
          (elimination_rat(true, "1", "1"), [1, 0]),
          (elimination_rat(false, "1", "1"), [0, 2]),
        ]),
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [0, 1]),
          (elimination_rat(true, "1", "1"), [0, 0]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
        elimination_poly(1, []),
        elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
        elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 2]),
          ]),
          elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
        ]),
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          elimination_poly(2, [(elimination_rat(true, "1", "1"), [0, 0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 2]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "2", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
          right: elimination_poly(2, []),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 2]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [1]),
              (elimination_rat(false, "1", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 2]),
          ]),
          right: elimination_poly(2, [(elimination_rat(true, "1", "1"), [0, 0])]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
          right: elimination_poly(2, [(elimination_rat(true, "1", "1"), [0, 0])]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(true, "1", "1"), [0, 0])]),
          right: elimination_poly(2, []),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 3" {
  one_step_fixture(
    @oracle.nat(2),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
        (elimination_rat(true, "1", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "2", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
        (elimination_rat(true, "3", "1"), [0, 1]),
      ]),
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(2),
      atoms: @oracle.chain([
        elimination_poly(2, [
          (elimination_rat(true, "1", "1"), [1, 1]),
          (elimination_rat(false, "1", "1"), [0, 2]),
          (elimination_rat(true, "1", "1"), [0, 1]),
        ]),
        elimination_poly(2, [
          (elimination_rat(true, "2", "1"), [1, 1]),
          (elimination_rat(false, "1", "1"), [0, 2]),
          (elimination_rat(true, "3", "1"), [0, 1]),
        ]),
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
        elimination_poly(1, [
          (elimination_rat(true, "1", "1"), [1]),
          (elimination_rat(true, "1", "1"), [0]),
        ]),
        elimination_poly(1, []),
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
        elimination_poly(1, [
          (elimination_rat(true, "2", "1"), [1]),
          (elimination_rat(true, "3", "1"), [0]),
        ]),
        elimination_poly(1, []),
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
        elimination_poly(1, []),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
        ]),
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
        ]),
        @oracle.chain([
          elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "2", "1"), [0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [2]),
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [1]),
              (elimination_rat(true, "2", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(false, "2", "1"), [0, 1]),
            (elimination_rat(true, "3", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(true, "4", "1"), [2]),
              (elimination_rat(true, "c", "1"), [1]),
              (elimination_rat(true, "9", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(true, "3", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 4" {
  one_step_fixture(
    @oracle.nat(2),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 2]),
        (elimination_rat(false, "1", "1"), [1, 0]),
        (elimination_rat(true, "1", "1"), [0, 2]),
        (elimination_rat(true, "1", "1"), [0, 0]),
      ]),
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(true, "2", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
        (elimination_rat(true, "2", "1"), [0, 0]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(2),
      atoms: @oracle.chain([
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [1, 2]),
          (elimination_rat(false, "1", "1"), [1, 0]),
          (elimination_rat(true, "1", "1"), [0, 2]),
          (elimination_rat(true, "1", "1"), [0, 0]),
        ]),
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [1, 1]),
          (elimination_rat(true, "2", "1"), [1, 0]),
          (elimination_rat(false, "1", "1"), [0, 1]),
          (elimination_rat(true, "2", "1"), [0, 0]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(1, [
          (elimination_rat(false, "1", "1"), [1]),
          (elimination_rat(true, "1", "1"), [0]),
        ]),
        elimination_poly(1, []),
        elimination_poly(1, [
          (elimination_rat(false, "1", "1"), [1]),
          (elimination_rat(true, "1", "1"), [0]),
        ]),
        elimination_poly(1, [
          (elimination_rat(false, "1", "1"), [1]),
          (elimination_rat(false, "1", "1"), [0]),
        ]),
        elimination_poly(1, [
          (elimination_rat(true, "2", "1"), [1]),
          (elimination_rat(true, "2", "1"), [0]),
        ]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 2]),
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
        ]),
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
          elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 2]),
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "2", "1"), [1, 1]),
            (elimination_rat(true, "2", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(false, "4", "1"), [3]),
              (elimination_rat(true, "c", "1"), [2]),
              (elimination_rat(false, "c", "1"), [1]),
              (elimination_rat(true, "4", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, []),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 2]),
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(false, "5", "1"), [3]),
              (elimination_rat(false, "5", "1"), [2]),
              (elimination_rat(true, "5", "1"), [1]),
              (elimination_rat(true, "5", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 2]),
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0]),
          ]),
          right: elimination_poly(2, []),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 5" {
  one_step_fixture(
    @oracle.nat(2),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(false, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 3]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 1]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(2),
      atoms: @oracle.chain([
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [1, 1]),
          (elimination_rat(false, "1", "1"), [0, 3]),
        ]),
        elimination_poly(2, [
          (elimination_rat(true, "1", "1"), [1, 0]),
          (elimination_rat(false, "1", "1"), [0, 1]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
        elimination_poly(1, []),
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
        elimination_poly(1, []),
        elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
        elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 3]),
          ]),
          elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 1])]),
        ]),
        @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 3]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(false, "3", "1"), [0, 2]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "4", "1"), [3])]),
            elimination_poly(1, [(elimination_rat(false, "6", "1"), [1])]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 1])]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 3]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [3]),
              (elimination_rat(true, "1", "1"), [2]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 3]),
          ]),
          right: elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 1])]),
          right: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(true, "1", "1"), [2])]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 1])]),
          right: elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          right: elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
          right: elimination_poly(2, []),
          values: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 6" {
  one_step_fixture(@oracle.nat(3), @oracle.chain([]), ProjectionCertificate::{
    arity: @oracle.nat(3),
    atoms: @oracle.chain([]),
    coefficients: @oracle.chain([]),
    reducta: @oracle.chain([]),
    principal: @oracle.chain([]),
  })
}

///|
test "arbitrary arity independent full Collins 7" {
  one_step_fixture(
    @oracle.nat(3),
    @oracle.chain([
      elimination_poly(3, []),
      elimination_poly(3, [(elimination_rat(false, "1", "1"), [1, 0, 0])]),
      elimination_poly(3, [(elimination_rat(false, "2", "3"), [0, 0, 0])]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(3),
      atoms: @oracle.chain([
        elimination_poly(3, []),
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [1, 0, 0])]),
        elimination_poly(3, [(elimination_rat(false, "2", "3"), [0, 0, 0])]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(2, []),
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
        elimination_poly(2, [(elimination_rat(false, "2", "3"), [0, 0])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([]),
        @oracle.chain([
          elimination_poly(3, [(elimination_rat(false, "1", "1"), [1, 0, 0])]),
        ]),
        @oracle.chain([
          elimination_poly(3, [(elimination_rat(false, "2", "3"), [0, 0, 0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
          ]),
          right: elimination_poly(3, []),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "2", "3"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "2", "3"), [0, 0, 0]),
          ]),
          right: elimination_poly(3, []),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 8" {
  one_step_fixture(
    @oracle.nat(3),
    @oracle.chain([
      elimination_poly(3, [
        (elimination_rat(false, "1", "1"), [1, 0, 1]),
        (elimination_rat(false, "1", "1"), [0, 1, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 2]),
      ]),
      elimination_poly(3, [
        (elimination_rat(true, "1", "1"), [1, 0, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 1]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(3),
      atoms: @oracle.chain([
        elimination_poly(3, [
          (elimination_rat(false, "1", "1"), [1, 0, 1]),
          (elimination_rat(false, "1", "1"), [0, 1, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 2]),
        ]),
        elimination_poly(3, [
          (elimination_rat(true, "1", "1"), [1, 0, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 1]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
        elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
          ]),
          elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 1, 0])]),
        ]),
        @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1]),
          ]),
          elimination_poly(3, [(elimination_rat(true, "1", "1"), [1, 0, 0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "2", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(true, "1", "1"), [2, 0]),
              (elimination_rat(false, "4", "1"), [0, 1]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, []),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(false, "2", "1"), [2, 0]),
              (elimination_rat(false, "1", "1"), [0, 1]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(true, "1", "1"), [2, 0]),
              (elimination_rat(true, "1", "1"), [0, 1]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
          ]),
          right: elimination_poly(3, []),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 9" {
  one_step_fixture(
    @oracle.nat(3),
    @oracle.chain([
      elimination_poly(3, [
        (elimination_rat(false, "1", "1"), [1, 1, 0]),
        (elimination_rat(false, "1", "1"), [1, 0, 2]),
        (elimination_rat(true, "1", "1"), [0, 1, 0]),
        (elimination_rat(true, "1", "1"), [0, 0, 2]),
      ]),
      elimination_poly(3, [
        (elimination_rat(false, "1", "1"), [0, 1, 1]),
        (elimination_rat(false, "1", "1"), [0, 1, 0]),
        (elimination_rat(true, "2", "1"), [0, 0, 1]),
        (elimination_rat(true, "2", "1"), [0, 0, 0]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(3),
      atoms: @oracle.chain([
        elimination_poly(3, [
          (elimination_rat(false, "1", "1"), [1, 1, 0]),
          (elimination_rat(false, "1", "1"), [1, 0, 2]),
          (elimination_rat(true, "1", "1"), [0, 1, 0]),
          (elimination_rat(true, "1", "1"), [0, 0, 2]),
        ]),
        elimination_poly(3, [
          (elimination_rat(false, "1", "1"), [0, 1, 1]),
          (elimination_rat(false, "1", "1"), [0, 1, 0]),
          (elimination_rat(true, "2", "1"), [0, 0, 1]),
          (elimination_rat(true, "2", "1"), [0, 0, 0]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [1, 0]),
          (elimination_rat(true, "1", "1"), [0, 0]),
        ]),
        elimination_poly(2, []),
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [1, 1]),
          (elimination_rat(true, "1", "1"), [0, 1]),
        ]),
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [0, 1]),
          (elimination_rat(true, "2", "1"), [0, 0]),
        ]),
        elimination_poly(2, [
          (elimination_rat(false, "1", "1"), [0, 1]),
          (elimination_rat(true, "2", "1"), [0, 0]),
        ]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(false, "1", "1"), [1, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 2]),
          ]),
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
          ]),
        ]),
        @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(false, "1", "1"), [1, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(false, "4", "1"), [3, 1]),
              (elimination_rat(true, "c", "1"), [2, 1]),
              (elimination_rat(false, "c", "1"), [1, 1]),
              (elimination_rat(true, "4", "1"), [0, 1]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, []),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(false, "1", "1"), [1, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 3]),
              (elimination_rat(true, "3", "1"), [1, 2]),
              (elimination_rat(false, "4", "1"), [1, 0]),
              (elimination_rat(true, "1", "1"), [0, 3]),
              (elimination_rat(false, "3", "1"), [0, 2]),
              (elimination_rat(true, "4", "1"), [0, 0]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(false, "1", "1"), [1, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 1]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "2", "1"), [0, 0, 0]),
          ]),
          right: elimination_poly(3, []),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 10" {
  one_step_fixture(
    @oracle.nat(3),
    @oracle.chain([
      elimination_poly(3, [
        (elimination_rat(true, "1", "1"), [1, 0, 1]),
        (elimination_rat(true, "1", "1"), [0, 1, 1]),
        (elimination_rat(false, "1", "1"), [0, 0, 2]),
      ]),
      elimination_poly(3, [
        (elimination_rat(true, "2", "1"), [1, 0, 1]),
        (elimination_rat(true, "1", "1"), [0, 1, 1]),
        (elimination_rat(false, "1", "1"), [0, 0, 2]),
        (elimination_rat(true, "1", "1"), [0, 0, 1]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(3),
      atoms: @oracle.chain([
        elimination_poly(3, [
          (elimination_rat(true, "1", "1"), [1, 0, 1]),
          (elimination_rat(true, "1", "1"), [0, 1, 1]),
          (elimination_rat(false, "1", "1"), [0, 0, 2]),
        ]),
        elimination_poly(3, [
          (elimination_rat(true, "2", "1"), [1, 0, 1]),
          (elimination_rat(true, "1", "1"), [0, 1, 1]),
          (elimination_rat(false, "1", "1"), [0, 0, 2]),
          (elimination_rat(true, "1", "1"), [0, 0, 1]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
        elimination_poly(2, [
          (elimination_rat(true, "1", "1"), [1, 0]),
          (elimination_rat(true, "1", "1"), [0, 1]),
        ]),
        elimination_poly(2, []),
        elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
        elimination_poly(2, [
          (elimination_rat(true, "2", "1"), [1, 0]),
          (elimination_rat(true, "1", "1"), [0, 1]),
          (elimination_rat(true, "1", "1"), [0, 0]),
        ]),
        elimination_poly(2, []),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
          ]),
        ]),
        @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "2", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(true, "1", "1"), [2, 0]),
              (elimination_rat(true, "2", "1"), [1, 1]),
              (elimination_rat(true, "1", "1"), [0, 2]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, []),
            elimination_poly(2, [
              (elimination_rat(true, "1", "1"), [1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, []),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, []),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "1", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, []),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "2", "1"), [0, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(true, "4", "1"), [2, 0]),
              (elimination_rat(true, "4", "1"), [1, 1]),
              (elimination_rat(true, "4", "1"), [1, 0]),
              (elimination_rat(true, "1", "1"), [0, 2]),
              (elimination_rat(true, "2", "1"), [0, 1]),
              (elimination_rat(true, "1", "1"), [0, 0]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 1, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          right: elimination_poly(3, [
            (elimination_rat(true, "2", "1"), [1, 0, 0]),
            (elimination_rat(true, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 11" {
  one_step_fixture(@oracle.nat(4), @oracle.chain([]), ProjectionCertificate::{
    arity: @oracle.nat(4),
    atoms: @oracle.chain([]),
    coefficients: @oracle.chain([]),
    reducta: @oracle.chain([]),
    principal: @oracle.chain([]),
  })
}

///|
test "arbitrary arity independent full Collins 12" {
  one_step_fixture(
    @oracle.nat(4),
    @oracle.chain([
      elimination_poly(4, [
        (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
        (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 0, 2]),
      ]),
      elimination_poly(4, [
        (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(4),
      atoms: @oracle.chain([
        elimination_poly(4, [
          (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
          (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 0, 2]),
        ]),
        elimination_poly(4, [
          (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [1, 0, 0])]),
        elimination_poly(3, [
          (elimination_rat(false, "1", "1"), [0, 1, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 1]),
        ]),
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
        elimination_poly(3, [(elimination_rat(true, "1", "1"), [0, 0, 1])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 2]),
          ]),
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
        ]),
        @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          elimination_poly(4, [(elimination_rat(true, "1", "1"), [0, 0, 1, 0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 2]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "2", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(true, "1", "1"), [2, 0, 0]),
              (elimination_rat(false, "4", "1"), [0, 1, 0]),
              (elimination_rat(false, "4", "1"), [0, 0, 1]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, []),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 2]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [1, 0, 1]),
              (elimination_rat(false, "1", "1"), [0, 1, 0]),
              (elimination_rat(false, "1", "1"), [0, 0, 2]),
              (elimination_rat(false, "1", "1"), [0, 0, 1]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 2]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(true, "1", "1"), [1, 0, 1]),
              (elimination_rat(true, "1", "1"), [0, 1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0, 1]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, []),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 13" {
  one_step_fixture(
    @oracle.nat(4),
    @oracle.chain([
      elimination_poly(4, [
        (elimination_rat(false, "1", "1"), [1, 0, 0, 2]),
        (elimination_rat(true, "1", "1"), [0, 1, 0, 2]),
        (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
        (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
      ]),
      elimination_poly(4, [
        (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(4),
      atoms: @oracle.chain([
        elimination_poly(4, [
          (elimination_rat(false, "1", "1"), [1, 0, 0, 2]),
          (elimination_rat(true, "1", "1"), [0, 1, 0, 2]),
          (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
          (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
        ]),
        elimination_poly(4, [
          (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(3, [
          (elimination_rat(false, "1", "1"), [1, 0, 0]),
          (elimination_rat(true, "1", "1"), [0, 1, 0]),
        ]),
        elimination_poly(3, [
          (elimination_rat(false, "1", "1"), [0, 1, 0]),
          (elimination_rat(true, "1", "1"), [0, 0, 1]),
        ]),
        elimination_poly(3, []),
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 1])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0, 2]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
        ]),
        @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          elimination_poly(4, [(elimination_rat(false, "1", "1"), [0, 0, 1, 0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0, 2]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "2", "1"), [1, 0, 0, 1]),
            (elimination_rat(true, "2", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(true, "1", "1"), [1, 2, 0]),
              (elimination_rat(false, "2", "1"), [1, 1, 1]),
              (elimination_rat(true, "1", "1"), [1, 0, 2]),
              (elimination_rat(false, "1", "1"), [0, 3, 0]),
              (elimination_rat(true, "2", "1"), [0, 2, 1]),
              (elimination_rat(false, "1", "1"), [0, 1, 2]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0, 2]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [1, 0, 2]),
              (elimination_rat(true, "1", "1"), [0, 1, 2]),
              (elimination_rat(true, "1", "1"), [0, 1, 1]),
              (elimination_rat(false, "1", "1"), [0, 0, 2]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1, 0, 2]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [0, 1, 1]),
              (elimination_rat(true, "1", "1"), [0, 0, 2]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0, 1, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, []),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "arbitrary arity independent full Collins 14" {
  one_step_fixture(
    @oracle.nat(4),
    @oracle.chain([
      elimination_poly(4, [
        (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
        (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
        (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
        (elimination_rat(false, "2", "5"), [0, 0, 0, 3]),
      ]),
      elimination_poly(4, [
        (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
      ]),
    ]),
    ProjectionCertificate::{
      arity: @oracle.nat(4),
      atoms: @oracle.chain([
        elimination_poly(4, [
          (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
          (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
          (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          (elimination_rat(false, "2", "5"), [0, 0, 0, 3]),
        ]),
        elimination_poly(4, [
          (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
          (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
        ]),
      ]),
      coefficients: @oracle.chain([
        elimination_poly(3, [(elimination_rat(false, "2", "5"), [0, 0, 0])]),
        elimination_poly(3, []),
        elimination_poly(3, [
          (elimination_rat(false, "1", "1"), [1, 0, 0]),
          (elimination_rat(false, "1", "1"), [0, 1, 0]),
        ]),
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 1])]),
        elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
        elimination_poly(3, [(elimination_rat(true, "1", "1"), [1, 0, 0])]),
      ]),
      reducta: @oracle.chain([
        @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "2", "5"), [0, 0, 0, 3]),
          ]),
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          elimination_poly(4, [(elimination_rat(false, "1", "1"), [0, 0, 1, 0])]),
        ]),
        @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          elimination_poly(4, [(elimination_rat(true, "1", "1"), [1, 0, 0, 0])]),
        ]),
      ]),
      principal: @oracle.chain([
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "2", "5"), [0, 0, 0, 3]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "6", "5"), [0, 0, 0, 2]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(false, "10", "19"), [3, 0, 0]),
              (elimination_rat(false, "30", "19"), [2, 1, 0]),
              (elimination_rat(false, "30", "19"), [1, 2, 0]),
              (elimination_rat(false, "10", "19"), [0, 3, 0]),
              (elimination_rat(false, "d8", "7d"), [0, 0, 2]),
            ]),
            elimination_poly(3, [
              (elimination_rat(false, "18", "19"), [1, 0, 0]),
              (elimination_rat(false, "18", "19"), [0, 1, 0]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, []),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "2", "5"), [0, 0, 0, 3]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(true, "2", "5"), [3, 0, 0]),
              (elimination_rat(true, "1", "1"), [2, 0, 0]),
              (elimination_rat(true, "1", "1"), [1, 1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0, 1]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "2", "5"), [0, 0, 0, 3]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(true, "1", "1"), [2, 0, 0]),
              (elimination_rat(true, "1", "1"), [1, 1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0, 1]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
          right: elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [0, 0, 0, 0]),
          ]),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
        PrincipalRow::{
          left: elimination_poly(4, [
            (elimination_rat(true, "1", "1"), [1, 0, 0, 0]),
          ]),
          right: elimination_poly(4, []),
          values: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
          ]),
        },
      ]),
    },
  )
}

///|
test "independent derivative hierarchy 0" {
  hierarchy_fixture(
    @oracle.nat(0),
    @oracle.chain([
      elimination_poly(0, []),
      elimination_poly(0, [(elimination_rat(true, "2", "3"), [])]),
      elimination_poly(0, [(elimination_rat(false, "7", "1"), [])]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([
          elimination_poly(0, []),
          elimination_poly(0, [(elimination_rat(true, "2", "3"), [])]),
          elimination_poly(0, [(elimination_rat(false, "7", "1"), [])]),
        ]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([
          Constant(@core.Equal),
          Constant(@core.Less),
          Constant(@core.Greater),
        ]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 1" {
  hierarchy_fixture(
    @oracle.nat(1),
    @oracle.chain([]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([]),
          coefficients: @oracle.chain([]),
          reducta: @oracle.chain([]),
          principal: @oracle.chain([]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 2" {
  hierarchy_fixture(
    @oracle.nat(1),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [3]),
        (elimination_rat(true, "1", "1"), [1]),
      ]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [3]),
            (elimination_rat(true, "1", "1"), [1]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [3]),
            (elimination_rat(true, "1", "1"), [1]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "3", "1"), [2]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
          elimination_poly(1, [(elimination_rat(false, "6", "1"), [1])]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([
          Member(@oracle.nat(1)),
          Member(@oracle.nat(2)),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(false, "1", "1"), [3]),
              (elimination_rat(true, "1", "1"), [1]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "3", "1"), [2]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "6", "1"), [1])]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, []),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, []),
            elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
            elimination_poly(0, []),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
            elimination_poly(0, []),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [3]),
                (elimination_rat(true, "1", "1"), [1]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [2]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [(elimination_rat(false, "6", "1"), [1])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [3]),
                (elimination_rat(true, "1", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [2]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [3]),
                (elimination_rat(true, "1", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [2]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [3]),
                (elimination_rat(true, "1", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [2]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [3]),
                (elimination_rat(true, "1", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "6", "1"), [1]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "6", "1"), [1]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [2]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "6", "1"), [1]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "24", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [2]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "6", "1"), [1]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "24", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "6", "1"), [1]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "6", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "6", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
          ]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 3" {
  hierarchy_fixture(
    @oracle.nat(1),
    @oracle.chain([
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(true, "2", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [1]),
        (elimination_rat(true, "1", "1"), [0]),
      ]),
      elimination_poly(1, []),
      elimination_poly(1, [
        (elimination_rat(false, "1", "1"), [2]),
        (elimination_rat(true, "2", "1"), [1]),
        (elimination_rat(false, "1", "1"), [0]),
      ]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [2]),
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(false, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
          elimination_poly(1, []),
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [2]),
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(false, "1", "1"), [0]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [2]),
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(false, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "2", "1"), [1]),
            (elimination_rat(true, "2", "1"), [0]),
          ]),
        ]),
        bindings: @oracle.chain([
          Member(@oracle.nat(0)),
          Member(@oracle.nat(1)),
          Constant(@core.Equal),
          Member(@oracle.nat(0)),
        ]),
        derivatives: @oracle.chain([
          Member(@oracle.nat(2)),
          Constant(@core.Greater),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(false, "1", "1"), [2]),
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(false, "1", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "1", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "2", "1"), [1]),
              (elimination_rat(true, "2", "1"), [0]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
          ]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 4" {
  hierarchy_fixture(
    @oracle.nat(2),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 0]),
        (elimination_rat(false, "1", "1"), [0, 2]),
      ]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([
          elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
          elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
        ]),
        family: @oracle.chain([
          elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
          elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0)), Member(@oracle.nat(1))]),
        derivatives: @oracle.chain([Constant(@core.Less), Constant(@core.Less)]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([
            elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
            elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, []),
            elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
            elimination_poly(0, []),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [1]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(2),
        source: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 2]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 2]),
          ]),
          elimination_poly(2, [(elimination_rat(false, "2", "1"), [0, 1])]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([
          Member(@oracle.nat(1)),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(2),
          atoms: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(true, "1", "1"), [1, 0]),
              (elimination_rat(false, "1", "1"), [0, 2]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "2", "1"), [0, 1])]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(true, "1", "1"), [1])]),
            elimination_poly(1, [(elimination_rat(false, "2", "1"), [0])]),
            elimination_poly(1, []),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 2]),
              ]),
              elimination_poly(2, [(elimination_rat(true, "1", "1"), [1, 0])]),
            ]),
            @oracle.chain([
              elimination_poly(2, [(elimination_rat(false, "2", "1"), [0, 1])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 2]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "2", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
              ]),
              right: elimination_poly(2, []),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 2]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "2", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(true, "4", "1"), [1])]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "2", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "2", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "2", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
          ]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 5" {
  hierarchy_fixture(
    @oracle.nat(2),
    @oracle.chain([
      elimination_poly(2, [
        (elimination_rat(true, "1", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
        (elimination_rat(true, "1", "1"), [0, 1]),
      ]),
      elimination_poly(2, [
        (elimination_rat(true, "2", "1"), [1, 1]),
        (elimination_rat(false, "1", "1"), [0, 2]),
        (elimination_rat(true, "3", "1"), [0, 1]),
      ]),
      elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(true, "1", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(true, "3", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "1", "1"), [2]),
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "1", "1"), [1]),
            (elimination_rat(true, "2", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [2]),
            (elimination_rat(false, "2", "1"), [1]),
            (elimination_rat(false, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "2", "1"), [1]),
            (elimination_rat(false, "3", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "2", "1"), [2]),
            (elimination_rat(false, "5", "1"), [1]),
            (elimination_rat(false, "3", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "4", "1"), [2]),
            (elimination_rat(true, "c", "1"), [1]),
            (elimination_rat(true, "9", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "3", "1"), [2]),
            (elimination_rat(true, "8", "1"), [1]),
            (elimination_rat(true, "5", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "4", "1"), [2]),
            (elimination_rat(false, "c", "1"), [1]),
            (elimination_rat(false, "9", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(true, "4", "1"), [0]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(true, "1", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(true, "3", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "1", "1"), [2]),
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "1", "1"), [1]),
            (elimination_rat(true, "2", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [2]),
            (elimination_rat(false, "2", "1"), [1]),
            (elimination_rat(false, "1", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "2", "1"), [1]),
            (elimination_rat(false, "3", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "2", "1"), [2]),
            (elimination_rat(false, "5", "1"), [1]),
            (elimination_rat(false, "3", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "4", "1"), [2]),
            (elimination_rat(true, "c", "1"), [1]),
            (elimination_rat(true, "9", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "3", "1"), [2]),
            (elimination_rat(true, "8", "1"), [1]),
            (elimination_rat(true, "5", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "4", "1"), [2]),
            (elimination_rat(false, "c", "1"), [1]),
            (elimination_rat(false, "9", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(true, "4", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "2", "1"), [1]),
            (elimination_rat(true, "2", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "2", "1"), [1]),
            (elimination_rat(false, "2", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "4", "1"), [1]),
            (elimination_rat(false, "5", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "8", "1"), [1]),
            (elimination_rat(true, "c", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(true, "6", "1"), [1]),
            (elimination_rat(true, "8", "1"), [0]),
          ]),
          elimination_poly(1, [
            (elimination_rat(false, "8", "1"), [1]),
            (elimination_rat(false, "c", "1"), [0]),
          ]),
        ]),
        bindings: @oracle.chain([
          Member(@oracle.nat(0)),
          Member(@oracle.nat(1)),
          Member(@oracle.nat(2)),
          Member(@oracle.nat(3)),
          Member(@oracle.nat(4)),
          Member(@oracle.nat(5)),
          Member(@oracle.nat(6)),
          Member(@oracle.nat(7)),
          Member(@oracle.nat(8)),
          Member(@oracle.nat(9)),
          Member(@oracle.nat(10)),
        ]),
        derivatives: @oracle.chain([
          Constant(@core.Less),
          Constant(@core.Less),
          Member(@oracle.nat(11)),
          Constant(@core.Less),
          Member(@oracle.nat(12)),
          Constant(@core.Greater),
          Member(@oracle.nat(13)),
          Member(@oracle.nat(14)),
          Member(@oracle.nat(15)),
          Member(@oracle.nat(16)),
          Constant(@core.Less),
          Constant(@core.Less),
          Constant(@core.Greater),
          Constant(@core.Greater),
          Constant(@core.Less),
          Constant(@core.Less),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(true, "3", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [2]),
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [1]),
              (elimination_rat(true, "2", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "1", "1"), [2]),
              (elimination_rat(false, "2", "1"), [1]),
              (elimination_rat(false, "1", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "2", "1"), [1]),
              (elimination_rat(false, "3", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "2", "1"), [2]),
              (elimination_rat(false, "5", "1"), [1]),
              (elimination_rat(false, "3", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "4", "1"), [2]),
              (elimination_rat(true, "c", "1"), [1]),
              (elimination_rat(true, "9", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "3", "1"), [2]),
              (elimination_rat(true, "8", "1"), [1]),
              (elimination_rat(true, "5", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "4", "1"), [2]),
              (elimination_rat(false, "c", "1"), [1]),
              (elimination_rat(false, "9", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(true, "4", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(true, "2", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "2", "1"), [1]),
              (elimination_rat(false, "2", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "4", "1"), [1]),
              (elimination_rat(false, "5", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "8", "1"), [1]),
              (elimination_rat(true, "c", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(true, "6", "1"), [1]),
              (elimination_rat(true, "8", "1"), [0]),
            ]),
            elimination_poly(1, [
              (elimination_rat(false, "8", "1"), [1]),
              (elimination_rat(false, "c", "1"), [0]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "3", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "5", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "c", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "9", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "3", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "5", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "c", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "9", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "5", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "c", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "8", "1"), [])]),
            elimination_poly(0, [(elimination_rat(false, "c", "1"), [])]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "3", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "3", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "9", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "2", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "5", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "c", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "8", "1"), [0])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(false, "c", "1"), [0])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "3", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "3", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "12", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "e", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "12", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "3", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "7", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "a", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [2]),
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "7", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "f", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "b", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "f", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "3", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "1", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "7", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "a", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [2]),
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "12", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "e", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "12", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "36", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "51", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2a", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "20", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "36", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "51", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "9", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "e", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "d", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "24", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "16", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [2]),
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "24", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [1]),
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "3", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "c4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "63", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "c", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "144", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "144", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1e", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "18", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "48", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2a", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [2]),
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "48", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [1]),
                (elimination_rat(true, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "9", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "c", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "63", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "c4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "c", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "16", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "5", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "14", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "38", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "c", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "22", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "10", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "3", "1"), [2]),
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "38", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "5", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "1e", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "18", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "48", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2a", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [2]),
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "48", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [1]),
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "9", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "6", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "4", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "4", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "2", "1"), [1]),
                (elimination_rat(true, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "2", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "4", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [1]),
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "2", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "2", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "5", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "c", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "c", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "c", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "8", "1"), [1]),
                (elimination_rat(true, "c", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "c", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "c", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "8", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(true, "8", "1"), [])]),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(true, "6", "1"), [1]),
                (elimination_rat(true, "8", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "8", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "8", "1"), [0])]),
              right: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [1]),
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "8", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "c", "1"), [0]),
              ]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(2),
        source: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
        ]),
        family: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "1", "1"), [0, 1]),
          ]),
          elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 1]),
            (elimination_rat(false, "1", "1"), [0, 2]),
            (elimination_rat(true, "3", "1"), [0, 1]),
          ]),
          elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
          elimination_poly(2, [
            (elimination_rat(true, "1", "1"), [1, 0]),
            (elimination_rat(false, "2", "1"), [0, 1]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          elimination_poly(2, [
            (elimination_rat(true, "2", "1"), [1, 0]),
            (elimination_rat(false, "2", "1"), [0, 1]),
            (elimination_rat(true, "3", "1"), [0, 0]),
          ]),
        ]),
        bindings: @oracle.chain([
          Member(@oracle.nat(0)),
          Member(@oracle.nat(1)),
          Member(@oracle.nat(2)),
        ]),
        derivatives: @oracle.chain([
          Member(@oracle.nat(3)),
          Member(@oracle.nat(4)),
          Constant(@core.Greater),
          Constant(@core.Greater),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(2),
          atoms: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(true, "1", "1"), [1, 1]),
              (elimination_rat(false, "1", "1"), [0, 2]),
              (elimination_rat(true, "1", "1"), [0, 1]),
            ]),
            elimination_poly(2, [
              (elimination_rat(true, "2", "1"), [1, 1]),
              (elimination_rat(false, "1", "1"), [0, 2]),
              (elimination_rat(true, "3", "1"), [0, 1]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
            elimination_poly(2, [
              (elimination_rat(true, "1", "1"), [1, 0]),
              (elimination_rat(false, "2", "1"), [0, 1]),
              (elimination_rat(true, "1", "1"), [0, 0]),
            ]),
            elimination_poly(2, [
              (elimination_rat(true, "2", "1"), [1, 0]),
              (elimination_rat(false, "2", "1"), [0, 1]),
              (elimination_rat(true, "3", "1"), [0, 0]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            elimination_poly(1, [
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(true, "3", "1"), [0]),
            ]),
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            elimination_poly(1, []),
            elimination_poly(1, [(elimination_rat(false, "2", "1"), [0])]),
            elimination_poly(1, [
              (elimination_rat(true, "1", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "2", "1"), [0])]),
            elimination_poly(1, [
              (elimination_rat(true, "2", "1"), [1]),
              (elimination_rat(true, "3", "1"), [0]),
            ]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
            ]),
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
            ]),
            @oracle.chain([
              elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
            ]),
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
            ]),
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "1", "1"), [2]),
                  (elimination_rat(true, "2", "1"), [1]),
                  (elimination_rat(true, "1", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [
                  (elimination_rat(true, "1", "1"), [1]),
                  (elimination_rat(true, "2", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "1", "1"), [2]),
                  (elimination_rat(true, "2", "1"), [1]),
                  (elimination_rat(true, "1", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(false, "1", "1"), [2]),
                  (elimination_rat(false, "2", "1"), [1]),
                  (elimination_rat(false, "1", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(false, "2", "1"), [1]),
                  (elimination_rat(false, "3", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(false, "2", "1"), [2]),
                  (elimination_rat(false, "5", "1"), [1]),
                  (elimination_rat(false, "3", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 1]),
                (elimination_rat(true, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "4", "1"), [2]),
                  (elimination_rat(true, "c", "1"), [1]),
                  (elimination_rat(true, "9", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "3", "1"), [2]),
                  (elimination_rat(true, "8", "1"), [1]),
                  (elimination_rat(true, "5", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(false, "2", "1"), [2]),
                  (elimination_rat(false, "5", "1"), [1]),
                  (elimination_rat(false, "3", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "4", "1"), [2]),
                  (elimination_rat(true, "c", "1"), [1]),
                  (elimination_rat(true, "9", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(false, "1", "1"), [0, 2]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(false, "4", "1"), [2]),
                  (elimination_rat(false, "c", "1"), [1]),
                  (elimination_rat(false, "9", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 1]),
                (elimination_rat(true, "3", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "1", "1"), [1]),
                  (elimination_rat(true, "1", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "2", "1"), [1]),
                  (elimination_rat(true, "3", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "2", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, []),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [
                  (elimination_rat(true, "2", "1"), [1]),
                  (elimination_rat(true, "4", "1"), [0]),
                ]),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(false, "2", "1"), [0, 1]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "2", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(true, "2", "1"), [1, 0]),
                (elimination_rat(true, "3", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, []),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
          ]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 6" {
  hierarchy_fixture(
    @oracle.nat(3),
    @oracle.chain([
      elimination_poly(3, [
        (elimination_rat(false, "1", "1"), [1, 0, 0]),
        (elimination_rat(false, "1", "1"), [0, 1, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 2]),
      ]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([
          elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
          elimination_poly(1, [(elimination_rat(false, "4", "1"), [1])]),
        ]),
        family: @oracle.chain([
          elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
          elimination_poly(1, [(elimination_rat(false, "4", "1"), [1])]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0)), Member(@oracle.nat(1))]),
        derivatives: @oracle.chain([
          Constant(@core.Greater),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
            elimination_poly(1, [(elimination_rat(false, "4", "1"), [1])]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, []),
            elimination_poly(0, [(elimination_rat(false, "4", "1"), [])]),
            elimination_poly(0, []),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
            ]),
            @oracle.chain([
              elimination_poly(1, [(elimination_rat(false, "4", "1"), [1])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, []),
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "4", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(2),
        source: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          elimination_poly(2, [
            (elimination_rat(false, "4", "1"), [1, 0]),
            (elimination_rat(false, "4", "1"), [0, 1]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
          elimination_poly(2, [
            (elimination_rat(false, "4", "1"), [1, 0]),
            (elimination_rat(false, "4", "1"), [0, 1]),
          ]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0)), Member(@oracle.nat(1))]),
        derivatives: @oracle.chain([
          Constant(@core.Greater),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(2),
          atoms: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 0]),
              (elimination_rat(false, "1", "1"), [0, 1]),
            ]),
            elimination_poly(2, [
              (elimination_rat(false, "4", "1"), [1, 0]),
              (elimination_rat(false, "4", "1"), [0, 1]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
            elimination_poly(1, [(elimination_rat(false, "4", "1"), [0])]),
            elimination_poly(1, [(elimination_rat(false, "4", "1"), [1])]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
            ]),
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [1, 0]),
                (elimination_rat(false, "4", "1"), [0, 1]),
              ]),
              elimination_poly(2, [(elimination_rat(false, "4", "1"), [1, 0])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
              ]),
              right: elimination_poly(2, []),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [1, 0]),
                (elimination_rat(false, "4", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, []),
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [1, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [1, 0]),
                (elimination_rat(false, "4", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [1, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [1, 0]),
                (elimination_rat(false, "4", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "4", "1"), [1, 0]),
              ]),
              right: elimination_poly(2, []),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(3),
        source: @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 2]),
          ]),
          elimination_poly(3, [(elimination_rat(false, "2", "1"), [0, 0, 1])]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([
          Member(@oracle.nat(1)),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(3),
          atoms: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [1, 0, 0]),
              (elimination_rat(false, "1", "1"), [0, 1, 0]),
              (elimination_rat(false, "1", "1"), [0, 0, 2]),
            ]),
            elimination_poly(3, [(elimination_rat(false, "2", "1"), [0, 0, 1])]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
            elimination_poly(2, []),
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 0]),
              (elimination_rat(false, "1", "1"), [0, 1]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "2", "1"), [0, 0])]),
            elimination_poly(2, []),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 2]),
              ]),
              elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
            ]),
            @oracle.chain([
              elimination_poly(3, [
                (elimination_rat(false, "2", "1"), [0, 0, 1]),
              ]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 2]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "2", "1"), [0, 0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [
                  (elimination_rat(false, "4", "1"), [1, 0]),
                  (elimination_rat(false, "4", "1"), [0, 1]),
                ]),
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
              right: elimination_poly(3, []),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 2]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "2", "1"), [0, 0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [
                  (elimination_rat(false, "4", "1"), [1, 0]),
                  (elimination_rat(false, "4", "1"), [0, 1]),
                ]),
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "2", "1"), [0, 0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "2", "1"), [0, 0, 1]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "2", "1"), [0, 0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
          ]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 7" {
  hierarchy_fixture(
    @oracle.nat(3),
    @oracle.chain([
      elimination_poly(3, [
        (elimination_rat(false, "1", "1"), [1, 0, 1]),
        (elimination_rat(false, "1", "1"), [0, 1, 0]),
        (elimination_rat(true, "1", "1"), [0, 0, 1]),
      ]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(1, [
            (elimination_rat(false, "1", "1"), [1]),
            (elimination_rat(true, "1", "1"), [0]),
          ]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([Constant(@core.Greater)]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(false, "1", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, [(elimination_rat(true, "1", "1"), [])]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
                (elimination_rat(true, "1", "1"), [0]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(1, [(elimination_rat(true, "1", "1"), [0])]),
              right: elimination_poly(1, []),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(2),
        source: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
        ]),
        family: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0]),
          ]),
          elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0)), Member(@oracle.nat(1))]),
        derivatives: @oracle.chain([
          Constant(@core.Equal),
          Constant(@core.Greater),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(2),
          atoms: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(1, [
              (elimination_rat(false, "1", "1"), [1]),
              (elimination_rat(true, "1", "1"), [0]),
            ]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            elimination_poly(1, []),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
            ]),
            @oracle.chain([
              elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, []),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(3),
        source: @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 1]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 1]),
          ]),
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
            (elimination_rat(true, "1", "1"), [0, 0, 0]),
          ]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([
          Member(@oracle.nat(1)),
          Constant(@core.Equal),
        ]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(3),
          atoms: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [1, 0, 1]),
              (elimination_rat(false, "1", "1"), [0, 1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0, 1]),
            ]),
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [1, 0, 0]),
              (elimination_rat(true, "1", "1"), [0, 0, 0]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0]),
            ]),
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 1])]),
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 0]),
              (elimination_rat(true, "1", "1"), [0, 0]),
            ]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 1]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 1]),
              ]),
              elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
            ]),
            @oracle.chain([
              elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 0]),
              ]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 1]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 1]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
              right: elimination_poly(3, []),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 1]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 1]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(true, "1", "1"), [0, 0, 0]),
              ]),
              right: elimination_poly(3, []),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
          ]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 8" {
  hierarchy_fixture(
    @oracle.nat(4),
    @oracle.chain([
      elimination_poly(4, [
        (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
        (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
        (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
      ]),
    ]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([
          elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
        ]),
        family: @oracle.chain([
          elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([Constant(@core.Greater)]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
            elimination_poly(0, []),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [1]),
              ]),
              right: elimination_poly(1, [
                (elimination_rat(false, "1", "1"), [0]),
              ]),
              values: @oracle.chain([
                elimination_poly(0, [(elimination_rat(false, "1", "1"), [])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(2),
        source: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(2, [
            (elimination_rat(false, "1", "1"), [1, 0]),
            (elimination_rat(false, "1", "1"), [0, 1]),
          ]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([Constant(@core.Greater)]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(2),
          atoms: @oracle.chain([
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 0]),
              (elimination_rat(false, "1", "1"), [0, 1]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
            elimination_poly(1, [(elimination_rat(false, "1", "1"), [1])]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              elimination_poly(2, [(elimination_rat(false, "1", "1"), [1, 0])]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
                (elimination_rat(false, "1", "1"), [0, 1]),
              ]),
              right: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(2, [
                (elimination_rat(false, "1", "1"), [1, 0]),
              ]),
              right: elimination_poly(2, []),
              values: @oracle.chain([
                elimination_poly(1, [(elimination_rat(false, "1", "1"), [0])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(3),
        source: @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(3, [
            (elimination_rat(false, "1", "1"), [1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1]),
          ]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([Constant(@core.Greater)]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(3),
          atoms: @oracle.chain([
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [1, 0, 0]),
              (elimination_rat(false, "1", "1"), [0, 1, 0]),
              (elimination_rat(false, "1", "1"), [0, 0, 1]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
            elimination_poly(2, [
              (elimination_rat(false, "1", "1"), [1, 0]),
              (elimination_rat(false, "1", "1"), [0, 1]),
            ]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 1]),
              ]),
              elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 1]),
              ]),
              right: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [0, 0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(3, [
                (elimination_rat(false, "1", "1"), [1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0]),
              ]),
              right: elimination_poly(3, []),
              values: @oracle.chain([
                elimination_poly(2, [(elimination_rat(false, "1", "1"), [0, 0])]),
              ]),
            },
          ]),
        }),
      },
      Level::{
        arity: @oracle.nat(4),
        source: @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
        ]),
        family: @oracle.chain([
          elimination_poly(4, [
            (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
            (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
          ]),
        ]),
        bindings: @oracle.chain([Member(@oracle.nat(0))]),
        derivatives: @oracle.chain([Constant(@core.Greater)]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(4),
          atoms: @oracle.chain([
            elimination_poly(4, [
              (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
              (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
              (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
              (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
            ]),
          ]),
          coefficients: @oracle.chain([
            elimination_poly(3, [(elimination_rat(false, "1", "1"), [0, 0, 0])]),
            elimination_poly(3, [
              (elimination_rat(false, "1", "1"), [1, 0, 0]),
              (elimination_rat(false, "1", "1"), [0, 1, 0]),
              (elimination_rat(false, "1", "1"), [0, 0, 1]),
            ]),
          ]),
          reducta: @oracle.chain([
            @oracle.chain([
              elimination_poly(4, [
                (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
              ]),
              elimination_poly(4, [
                (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
              ]),
            ]),
          ]),
          principal: @oracle.chain([
            PrincipalRow::{
              left: elimination_poly(4, [
                (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 0, 1]),
              ]),
              right: elimination_poly(4, [
                (elimination_rat(false, "1", "1"), [0, 0, 0, 0]),
              ]),
              values: @oracle.chain([
                elimination_poly(3, [
                  (elimination_rat(false, "1", "1"), [0, 0, 0]),
                ]),
              ]),
            },
            PrincipalRow::{
              left: elimination_poly(4, [
                (elimination_rat(false, "1", "1"), [1, 0, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 1, 0, 0]),
                (elimination_rat(false, "1", "1"), [0, 0, 1, 0]),
              ]),
              right: elimination_poly(4, []),
              values: @oracle.chain([
                elimination_poly(3, [
                  (elimination_rat(false, "1", "1"), [0, 0, 0]),
                ]),
              ]),
            },
          ]),
        }),
      },
    ]),
  )
}

///|
test "independent derivative hierarchy 9" {
  hierarchy_fixture(
    @oracle.nat(4),
    @oracle.chain([]),
    @oracle.chain([
      Level::{
        arity: @oracle.nat(0),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: None,
      },
      Level::{
        arity: @oracle.nat(1),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(1),
          atoms: @oracle.chain([]),
          coefficients: @oracle.chain([]),
          reducta: @oracle.chain([]),
          principal: @oracle.chain([]),
        }),
      },
      Level::{
        arity: @oracle.nat(2),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(2),
          atoms: @oracle.chain([]),
          coefficients: @oracle.chain([]),
          reducta: @oracle.chain([]),
          principal: @oracle.chain([]),
        }),
      },
      Level::{
        arity: @oracle.nat(3),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(3),
          atoms: @oracle.chain([]),
          coefficients: @oracle.chain([]),
          reducta: @oracle.chain([]),
          principal: @oracle.chain([]),
        }),
      },
      Level::{
        arity: @oracle.nat(4),
        source: @oracle.chain([]),
        family: @oracle.chain([]),
        bindings: @oracle.chain([]),
        derivatives: @oracle.chain([]),
        projection: Some(ProjectionCertificate::{
          arity: @oracle.nat(4),
          atoms: @oracle.chain([]),
          coefficients: @oracle.chain([]),
          reducta: @oracle.chain([]),
          principal: @oracle.chain([]),
        }),
      },
    ]),
  )
}
