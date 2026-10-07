"""Synchronize marked README blocks with verbatim Stata output.

Run Stata's test/readme_output.do first and save its console output as
 test/readme_output.txt. This script never constructs statistical tables.
"""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    source = (ROOT / 'test/readme_output.txt').read_text(encoding='utf-8-sig')
    assert '\nREADME_OUTPUT_COMPLETED\n' in source, 'Incomplete Stata output'
    blocks = {}
    for start in re.finditer(r'^BEGIN_README_(\w+)\n', source, re.M):
        key = start[1]
        end = source.index(f'. dis "END_README_{key}"', start.end())
        # Only blank separator lines outside the command/output are excluded.
        blocks[key] = source[start.end():end].strip('\n')
    pattern = re.compile(
        r'(<!-- stata-output:(\w+) -->\n)```text\n.*?```\n(<!-- /stata-output:\2 -->)',
        re.S,
    )
    for name in ('README.md', 'README_CN.md'):
        path = ROOT / name
        original = path.read_text(encoding='utf-8')
        updated, count = pattern.subn(
            lambda m: m[1] + '```text\n' + blocks[m[2]] + '\n```\n' + m[3], original
        )
        assert count == 14, (name, 'Unexpected number of output blocks', count)
        if args.check:
            assert original == updated, f'{name}: output differs from source'
        else:
            path.write_text(updated, encoding='utf-8', newline='\n')
        print(f'{name}: {count} verbatim output blocks verified')


if __name__ == '__main__':
    main()
