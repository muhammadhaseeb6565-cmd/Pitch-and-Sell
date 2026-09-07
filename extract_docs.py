from zipfile import ZipFile
from xml.etree import ElementTree as ET
import re, os

def extract_docx_text(filepath):
    with ZipFile(filepath) as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
    root = tree.getroot()
    paragraphs = []
    for para in root.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p'):
        texts = []
        for t in para.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t'):
            if t.text:
                texts.append(t.text)
        line = ''.join(texts).strip()
        if line:
            paragraphs.append(line)
    return '\n\n'.join(paragraphs)

files = {
    'terms': 'Pitch & Sell ( Terms of Services).docx',
    'privacy': 'Pitch & Sell Privacy Policy.docx',
    'help': 'Pitch & Sell (Help Center).docx',
}

for key, filename in files.items():
    text = extract_docx_text(filename)
    out = f'extracted_{key}.txt'
    with open(out, 'w', encoding='utf-8') as f:
        f.write(text)
    print(f'{key}: {len(text)} chars -> {out}')
