#!/usr/bin/env python3
"""Generate two pure-ADT small-difference dispatch controls and a selected kernel."""
import argparse
import re
from pathlib import Path
import shutil
import subprocess
from generate_binary_tiny_products import bits

ROOT = Path(__file__).resolve().parent.parent
WIDTH = 'Cons(_, Cons(_, Cons(_, Cons(_, Cons(_, _)))))'


def ordered():
    lines = ['///|', 'fn difference_ordered_table(a : Binary, b : Binary) -> Binary? {', '  match (a.bits, b.bits) {']
    for a in range(16):
        for b in range(a):
            lines.append(f'    ({bits(a)}, {bits(b)}) => tiny_product_value_{a-b}')
    lines += ['    _ => None', '  }', '}', '', '///|', 'fn difference_ordered_lookup(a : Binary, b : Binary) -> Binary? {', '  match a.bits {', f'    {WIDTH} => None', '    _ => difference_ordered_table(a,b)', '  }', '}']
    return '\n'.join(lines)


def full():
    lines = ['///|', 'let difference_known_underflow : Option[Binary?] = Some(None)', '']
    for value in range(16):
        lines += ['///|', f'let difference_known_{value} : Option[Binary?] = Some(tiny_product_value_{value})', '']
    lines += ['///|', 'fn difference_full_table(a : Binary, b : Binary) -> Option[Binary?] {', '  match (a.bits, b.bits) {']
    for a in range(16):
        for b in range(16):
            result = 'difference_known_underflow' if a < b else f'difference_known_{a-b}'
            lines.append(f'    ({bits(a)}, {bits(b)}) => {result}')
    lines += ['    _ => None', '  }', '}', '', '///|', 'fn difference_full_lookup(a : Binary, b : Binary) -> Option[Binary?] {', '  match a.bits {', f'    {WIDTH} => None', '    _ => match b.bits {', f'      {WIDTH} => None', '      _ => difference_full_table(a,b)', '    }', '  }', '}']
    return '\n'.join(lines)


REFERENCE = '''
///|
fn difference_reference(a : Binary, b : Binary) -> Binary? {
  match compare(a,b) {
    Less => None
    _ => Some(from_bits(subtract_bits(a.bits,b.bits,false)))
  }
}

///|
fn difference_equal_control(a : Binary, b : Binary) -> Binary? {
  match compare(a,b) {
    Less => None
    Equal => tiny_product_value_0
    Greater => Some(from_bits(subtract_bits(a.bits,b.bits,false)))
  }
}
'''

ORDERED_CONTROL = '''
///|
fn difference_ordered_control(a : Binary, b : Binary) -> Binary? {
  match (a.bits,b.bits) {
    (_,Nil) => return Some(a)
    (Nil,_) => return None
    _ => ()
  }
  match compare(a,b) {
    Less => None
    Equal => tiny_product_value_0
    Greater => {
      let known = difference_ordered_lookup(a,b)
      match known {
        Some(_) => known
        None => Some(from_bits(subtract_bits(a.bits,b.bits,false)))
      }
    }
  }
}
'''

FULL_CONTROL = '''
///|
fn difference_full_control(a : Binary, b : Binary) -> Binary? {
  match (a.bits,b.bits) {
    (_,Nil) => return Some(a)
    (Nil,_) => return None
    _ => ()
  }
  match difference_full_lookup(a,b) {
    Some(result) => result
    None => match compare(a,b) {
      Less => None
      Equal => tiny_product_value_0
      Greater => Some(from_bits(subtract_bits(a.bits,b.bits,false)))
    }
  }
}
'''

TESTS = '''
///|
test "difference dispatches and partial maps match independent byte differences" {
  for a in 0..<256 {
    for b in 0..<256 {
      let x=@oracle.binary(a)
      let y=@oracle.binary(b)
      let expected = if a < b {None} else {Some(@oracle.binary(a-b))}
      assert_eq(difference_ordered_control(x,y),expected)
      assert_eq(difference_full_control(x,y),expected)
      let ordered = if a < 16 && b < 16 && a > b {expected} else {None}
      let full = if a < 16 && b < 16 {Some(expected)} else {None}
      assert_eq(difference_ordered_lookup(x,y),ordered)
      assert_eq(difference_full_lookup(x,y),full)
    }
  }
}

///|
test "same ELF difference order controls for nonzero small words" (b : @bench.T) {
  let pairs=[]
  for a in 1..<16 {for c in 1..<16 {pairs.push((@oracle.binary(a),@oracle.binary(c)))}}
  b.bench(name="original small225",fn(){for pair in pairs {b.keep(difference_reference(pair.0,pair.1))}})
  b.bench(name="equal fast small225",fn(){for pair in pairs {b.keep(difference_equal_control(pair.0,pair.1))}})
  b.bench(name="compare first small225",fn(){for pair in pairs {b.keep(difference_ordered_control(pair.0,pair.1))}})
  b.bench(name="lookup first small225",fn(){for pair in pairs {b.keep(difference_full_control(pair.0,pair.1))}})
}

///|
test "same ELF difference byte fallback controls" (b : @bench.T) {
  let pairs=[]
  for index in 0..<128 {pairs.push((@oracle.binary((index*73+19)%256),@oracle.binary((index*137+43)%256)))}
  b.bench(name="original byte128",fn(){for pair in pairs {b.keep(difference_reference(pair.0,pair.1))}})
  b.bench(name="compare first byte128",fn(){for pair in pairs {b.keep(difference_ordered_control(pair.0,pair.1))}})
  b.bench(name="lookup first byte128",fn(){for pair in pairs {b.keep(difference_full_control(pair.0,pair.1))}})
}

///|
test "same ELF difference wide and identity controls" (b : @bench.T) {
  let a=@oracle.binary_from_hex("d59b8c50c9174c3a71293ab167cd89ef")
  let c=@oracle.binary_from_hex("21234567a789cf1323456789abcdef01")
  let small=@oracle.binary(11)
  let pairs=[(a,c),(c,a),(a,small),(small,a),(a,a),(zero(),a),(a,zero())]
  b.bench(name="original wide7",fn(){for pair in pairs {b.keep(difference_reference(pair.0,pair.1))}})
  b.bench(name="compare first wide7",fn(){for pair in pairs {b.keep(difference_ordered_control(pair.0,pair.1))}})
  b.bench(name="lookup first wide7",fn(){for pair in pairs {b.keep(difference_full_control(pair.0,pair.1))}})
}
'''


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--winner',choices=['ordered','lookup'])
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    formatter=ROOT/'.tools/moon/bin/moonfmt'
    if not formatter.is_file():formatter=shutil.which('moonfmt')
    if formatter is None:raise SystemExit('MoonBit formatter is missing; run tools/bootstrap.')
    def formatted(text):
        return subprocess.run([str(formatter),'-'],input=text,text=True,capture_output=True,check=True).stdout
    prototype='// Generated by tools/generate_binary_tiny_differences.py; benchmark controls.\n\n'+ordered()+'\n\n'+full()+REFERENCE+ORDERED_CONTROL+FULL_CONTROL+TESTS
    prototype=formatted(re.sub(r'(?<![\w])difference_', 'candidate_difference_', prototype))
    outputs={ROOT/'src/binary/difference_candidates_wbtest.mbt':prototype}
    if args.winner:
        selected=ordered()+ORDERED_CONTROL if args.winner=='ordered' else full()+FULL_CONTROL
        selected=selected.replace('fn difference_'+('ordered' if args.winner=='ordered' else 'full')+'_control(', 'fn subtract_adaptively(')
        outputs[ROOT/'src/binary/tiny_differences.mbt']=formatted('// Generated by tools/generate_binary_tiny_differences.py --winner '+args.winner+'; immutable lookup results.\n\n'+selected)
    for path,text in outputs.items():
        if args.check:
            if path.read_text()!=text:raise SystemExit(f'Generated difference control drift: {path.name}')
        else:path.write_text(text)
    print('Difference controls checked; production='+str(args.winner))


if __name__=='__main__':main()
