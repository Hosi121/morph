///|
#derive(Eq, Debug)
pub(all) struct Pattern {
  label : @core.Nat
  word : @core.Chain[Bool]
}

///|
pub extend Pattern with Eq::{equal, not_equal}

///|
pub extend Pattern with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct Output {
  label : @core.Nat
  width : @core.Nat
}

///|
pub extend Output with Eq::{equal, not_equal}

///|
pub extend Output with Debug::{to_repr}

///|
#derive(Eq, Debug)
struct Node {
  failure : @core.Chain[Bool]
  outputs : @core.Chain[Output]
}

///|
pub extend Node with Eq::{equal, not_equal}

///|
pub extend Node with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Plan {
  nodes : @trie.Trie[Node]
}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
fn node(nodes : @trie.Trie[Node], word : @core.Chain[Bool]) -> Node {
  match @trie.lookup(nodes, word) {
    Some(node) => node
    None => { failure: Nil, outputs: Nil, }
  }
}

///|
fn child(prefix : @core.Chain[Bool], bit : Bool) -> @core.Chain[Bool] {
  @core.append(prefix, Cons(bit, Nil))
}

///|
/// Failure edges strictly shorten a nonempty state's prefix.
fn transition(
  nodes : @trie.Trie[Node],
  prefix : @core.Chain[Bool],
  bit : Bool,
) -> @core.Chain[Bool] {
  let next = child(prefix, bit)
  match @trie.lookup(nodes, next) {
    Some(_) => next
    None =>
      match prefix {
        Nil => Nil
        Cons(_, _) => transition(nodes, node(nodes, prefix).failure, bit)
      }
  }
}

///|
/// All prefixes are explicit trie values. Duplicate words may have distinct labels.
/// Empty patterns match every boundary, including the initial position.
pub fn plan(patterns : @core.Chain[Pattern]) -> Plan? {
  fn labels_unique(patterns : @core.Chain[Pattern]) -> Bool {
    match patterns {
      Nil => true
      Cons(pattern, rest) =>
        !@core.any(rest, fn(other) {
          match @core.compare(pattern.label, other.label) {
            Equal => true
            _ => false
          }
        }) &&
        labels_unique(rest)
    }
  }
  fn register(
    nodes : @trie.Trie[Node],
    prefix : @core.Chain[Bool],
    remaining : @core.Chain[Bool],
    output : Output,
  ) -> @trie.Trie[Node] {
    let current = node(nodes, prefix)
    let nodes = @trie.put(nodes, prefix, current)
    match remaining {
      Nil =>
        @trie.put(nodes, prefix, {
          ..current,
          outputs: @core.append(current.outputs, Cons(output, Nil)),
        })
      Cons(bit, rest) => register(nodes, child(prefix, bit), rest, output)
    }
  }
  fn prepare_children(
    nodes : @trie.Trie[Node],
    prefix : @core.Chain[Bool],
    queue : @core.Queue[@core.Chain[Bool]],
  ) -> (@trie.Trie[Node], @core.Queue[@core.Chain[Bool]]) {
    @core.fold_left(Cons(false, Cons(true, Nil)), (nodes, queue), fn(
      state,
      bit,
    ) {
      let (nodes, queue) = state
      let next = child(prefix, bit)
      match @trie.lookup(nodes, next) {
        None => state
        Some(own) => {
          let failure : @core.Chain[Bool] = match prefix {
            Nil => Nil
            Cons(_, _) => transition(nodes, node(nodes, prefix).failure, bit)
          }
          let inherited = node(nodes, failure).outputs
          let updated = {
            failure,
            outputs: @core.append(own.outputs, inherited),
          }
          (@trie.put(nodes, next, updated), @core.enqueue(queue, next))
        }
      }
    })
  }
  fn breadth_first(
    nodes : @trie.Trie[Node],
    queue : @core.Queue[@core.Chain[Bool]],
  ) -> Plan {
    match @core.dequeue(queue) {
      None => { nodes, }
      Some((prefix, rest)) => {
        let (nodes, queue) = prepare_children(nodes, prefix, rest)
        breadth_first(nodes, queue)
      }
    }
  }
  match labels_unique(patterns) {
    false => None
    true => {
      let root = @trie.put(@trie.empty(), Nil, Node::{
        failure: Nil,
        outputs: Nil,
      })
      let nodes = @core.fold_left(patterns, root, fn(nodes, pattern) {
        register(nodes, Nil, pattern.word, {
          label: pattern.label,
          width: @core.length(pattern.word),
        })
      })
      let (nodes, queue) = prepare_children(nodes, Nil, @core.queue())
      Some(breadth_first(nodes, queue))
    }
  }
}

///|
#derive(Eq, Debug)
pub(all) struct Match {
  label : @core.Nat
  start : @core.Nat
  end : @core.Nat
}

///|
pub extend Match with Eq::{equal, not_equal}

///|
pub extend Match with Debug::{to_repr}

///|
#derive(Eq, Debug)
pub struct Scanner {
  plan : Plan
  prefix : @core.Chain[Bool]
  offset : @core.Nat
  started : Bool
}

///|
pub extend Scanner with Eq::{equal, not_equal}

///|
pub extend Scanner with Debug::{to_repr}

///|
pub fn start(plan : Plan) -> Scanner {
  { plan, prefix: Nil, offset: Zero, started: false, }
}

///|
/// Matches are ordered by end position, then decreasing pattern length;
/// equal words follow their input-label order. Spans use [start,end).
/// The first feed emits initial empty matches even if its chunk is empty.
pub fn feed(
  scanner : Scanner,
  chunk : @core.Chain[Bool],
) -> (@core.Chain[Match], Scanner) {
  fn emit(
    outputs : @core.Chain[Output],
    offset : @core.Nat,
    reversed : @core.Chain[Match],
  ) -> @core.Chain[Match] {
    @core.fold_left(outputs, reversed, fn(found, output) {
      Cons(
        {
          label: output.label,
          start: @core.subtract(offset, output.width),
          end: offset,
        },
        found,
      )
    })
  }
  fn scan(
    chunk : @core.Chain[Bool],
    prefix : @core.Chain[Bool],
    offset : @core.Nat,
    reversed : @core.Chain[Match],
  ) -> (@core.Chain[Match], Scanner) {
    match chunk {
      Nil =>
        (
          @core.reverse(reversed),
          { plan: scanner.plan, prefix, offset, started: true, },
        )
      Cons(bit, rest) => {
        let prefix = transition(scanner.plan.nodes, prefix, bit)
        let offset = @core.Succ(offset)
        scan(
          rest,
          prefix,
          offset,
          emit(node(scanner.plan.nodes, prefix).outputs, offset, reversed),
        )
      }
    }
  }
  let initial : @core.Chain[Match] = match scanner.started {
    true => Nil
    false => emit(node(scanner.plan.nodes, Nil).outputs, Zero, Nil)
  }
  scan(chunk, scanner.prefix, scanner.offset, initial)
}

///|
pub fn find_all(plan : Plan, word : @core.Chain[Bool]) -> @core.Chain[Match] {
  let (matches, _) = feed(start(plan), word)
  matches
}
