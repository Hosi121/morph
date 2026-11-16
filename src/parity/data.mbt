///|
#derive(Eq, Debug)
pub(all) enum Player {
  EvenPlayer
  OddPlayer
}

///|
pub extend Player with Eq::{equal, not_equal}

///|
pub extend Player with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Position {
  id : @core.Nat
  owner : Player
  priority : @core.Nat
  successors : @core.Chain[@core.Nat]
}

///|
pub extend Position with Eq::{equal, not_equal}

///|
pub extend Position with Debug::{to_repr}

///|
/// A finite total arena. The greatest priority seen infinitely often decides.
#derive(Eq, Debug)
pub struct Game {
  positions : @core.Chain[Position]
}

///|
pub extend Game with Eq::{equal, not_equal}

///|
pub extend Game with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Move {
  source : @core.Nat
  target : @core.Nat
}

///|
pub extend Move with Eq::{equal, not_equal}

///|
pub extend Move with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) struct Certificate {
  even_region : @core.Chain[@core.Nat]
  odd_region : @core.Chain[@core.Nat]
  even_strategy : @core.Chain[Move]
  odd_strategy : @core.Chain[Move]
}

///|
pub extend Certificate with Eq::{equal, not_equal}

///|
pub extend Certificate with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Solution {
  certificate : Certificate
}

///|
pub extend Solution with Eq::{equal, not_equal}

///|
pub extend Solution with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct Attraction {
  vertices : @core.Chain[@core.Nat]
  strategy : @core.Chain[Move]
}

///|
pub extend Attraction with Eq::{equal, not_equal}

///|
pub extend Attraction with Debug::{to_repr}

///|
#derive(Eq, Debug)
enum Frame {
  Enter(@core.Chain[@core.Nat])
  AfterFirst(@core.Chain[@core.Nat], Player, @core.Chain[@core.Nat], Attraction)
  AfterSecond(Player, Attraction, @core.Chain[Move])
}

///|
pub extend Frame with Eq::{equal, not_equal}

///|
pub extend Frame with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Machine {
  game : Game
  frames : @core.Chain[Frame]
  returned : Certificate?
}

///|
pub extend Machine with Eq::{equal, not_equal}

///|
pub extend Machine with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub(all) enum Progress {
  Complete(Solution)
  Paused(Machine)
  Fault
}

///|
pub extend Progress with Eq::{equal, not_equal}

///|
pub extend Progress with Debug::{to_repr}
