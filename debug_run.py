from pathlib import Path
import pandas as pd
p = Path('src/profile_dataset.py')
print('SCRIPT', p.resolve())
print('EXISTS', p.exists())
print('LEN', len(p.read_text()))
print('---SCRIPT START---')
print(p.read_text()[:400])
print('---SCRIPT END---')
RAW_DIR = Path('data/raw')
print('RAW_EXISTS', RAW_DIR.exists())
print('CSV_COUNT', len(list(RAW_DIR.glob('*.csv'))))
csv_files = sorted(RAW_DIR.glob('*.csv'))
print('FIRST', csv_files[0] if csv_files else None)
profile_lines = ['# header\n', 'line\n']
out = Path('docs/test_write_debug.txt')
out.write_text(''.join(profile_lines), encoding='utf-8')
print('WRITE_OK', out.exists(), out.stat().st_size)
