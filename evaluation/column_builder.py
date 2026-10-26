"""
Column-Aware Line/Word Builder (SRS-Compliant)
===============================================
Issue #7: Reconstructs reading order from character detections.
"""

import argparse
import json
import statistics
from pathlib import Path
from typing import List, Dict, Tuple, Optional

# استيراد وحدة CER المنفصلة
try:
    from evaluation.cer import calculate_cer
except ImportError:
    from cer import calculate_cer  # Fallback for direct execution

# ============================================================
# SRS Constants
# ============================================================
COLUMN_GAP_RATIO = 0.08          # 8% of page width
WORD_GAP_RATIO = 0.5             # 50% of median glyph width
LINE_GROUPING_FACTOR = 0.6       # 60% of median line height

# ============================================================
# Data Loading
# ============================================================
def load_detections(path: str) -> List[Dict]:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if isinstance(data, list) and len(data) > 0 and isinstance(data[0], str):
        raise ValueError(f"⚠️ File {path} contains strings, not detection dictionaries.")
    
    if isinstance(data, dict):
        for key in ['detections', 'boxes', 'results']:
            if key in data and isinstance(data[key], list):
                data = data[key]
                break
        else:
            data = list(data.values())
    return data

# ============================================================
# 1. Column Splitting
# ============================================================
def compute_page_width(boxes: List[Dict]) -> float:
    if not boxes: return 0.0
    return max(b['x2'] for b in boxes) - min(b['x1'] for b in boxes)

def split_into_columns(boxes: List[Dict]) -> List[List[Dict]]:
    if not boxes: return []
    page_width = compute_page_width(boxes)
    if page_width == 0: return [boxes]
    
    x_coords = sorted([b['x1'] for b in boxes] + [b['x2'] for b in boxes])
    gaps = [(x_coords[i+1] - x_coords[i], (x_coords[i] + x_coords[i+1])/2) for i in range(len(x_coords)-1)]
    
    min_x, max_x = min(b['x1'] for b in boxes), max(b['x2'] for b in boxes)
    page_center = (min_x + max_x) / 2
    search_range = page_width * 0.25
    
    valid_gaps = [(gap, center) for gap, center in gaps if gap > page_width * COLUMN_GAP_RATIO and abs(center - page_center) < search_range]
    
    if not valid_gaps:
        return [sorted(boxes, key=lambda b: (b['y1'], b['x1']))]
    
    split_x = max(valid_gaps, key=lambda x: x[0])[1]
    left_col = sorted([b for b in boxes if (b['x1'] + b['x2']) / 2 < split_x], key=lambda b: (b['y1'], b['x1']))
    right_col = sorted([b for b in boxes if (b['x1'] + b['x2']) / 2 >= split_x], key=lambda b: (b['y1'], b['x1']))
    
    return [left_col, right_col]

# ============================================================
# 2. Line Grouping
# ============================================================
def compute_median_line_height(boxes: List[Dict]) -> float:
    if not boxes: return 0.0
    return statistics.median([b['y2'] - b['y1'] for b in boxes])

def group_into_lines(boxes: List[Dict]) -> List[List[Dict]]:
    if not boxes: return []
    sorted_boxes = sorted(boxes, key=lambda b: (b['y1'] + b['y2']) / 2)
    median_height = compute_median_line_height(sorted_boxes)
    line_threshold = median_height * LINE_GROUPING_FACTOR if median_height > 0 else 20.0
    
    lines, current_line = [], [sorted_boxes[0]]
    current_y_center = (sorted_boxes[0]['y1'] + sorted_boxes[0]['y2']) / 2
    
    for box in sorted_boxes[1:]:
        box_y_center = (box['y1'] + box['y2']) / 2
        if abs(box_y_center - current_y_center) <= line_threshold:
            current_line.append(box)
            current_y_center = sum((b['y1'] + b['y2']) / 2 for b in current_line) / len(current_line)
        else:
            lines.append(sorted(current_line, key=lambda b: b['x1']))
            current_line, current_y_center = [box], box_y_center
            
    if current_line:
        lines.append(sorted(current_line, key=lambda b: b['x1']))
    return lines

# ============================================================
# 3. Word Building
# ============================================================
def compute_median_glyph_width(line_boxes: List[Dict]) -> float:
    if not line_boxes: return 0.0
    return statistics.median([b['x2'] - b['x1'] for b in line_boxes])

def build_words_from_line(line_boxes: List[Dict]) -> List[List[Dict]]:
    if not line_boxes: return []
    median_width = compute_median_glyph_width(line_boxes)
    word_gap_threshold = median_width * WORD_GAP_RATIO if median_width > 0 else 10.0
    
    words, current_word = [], [line_boxes[0]]
    for i in range(1, len(line_boxes)):
        if line_boxes[i]['x1'] - line_boxes[i-1]['x2'] > word_gap_threshold:
            words.append(current_word)
            current_word = [line_boxes[i]]
        else:
            current_word.append(line_boxes[i])
    if current_word:
        words.append(current_word)
    return words

# ============================================================
# 4. Text Reconstruction
# ============================================================
def reconstruct_text(boxes: List[Dict]) -> Tuple[str, Dict]:
    if not boxes: return "", {}
    columns = split_into_columns(boxes)
    column_structures = []
    
    for col_idx, col_boxes in enumerate(columns):
        lines = group_into_lines(col_boxes)
        line_structures = []
        for line_idx, line_boxes in enumerate(lines):
            words = build_words_from_line(line_boxes)
            word_texts = [''.join(b['char'] for b in word) for word in words]
            line_structures.append({
                'line_num': line_idx + 1, 'num_words': len(words),
                'num_chars': len(line_boxes), 'text': ' '.join(word_texts), 'words': word_texts
            })
        column_structures.append({
            'column_num': col_idx + 1, 'num_lines': len(lines),
            'text': '\n'.join([ls['text'] for ls in line_structures]), 'lines': line_structures
        })
        
    return '\n\n'.join([c['text'] for c in column_structures]), {'num_columns': len(columns), 'columns': column_structures}

# ============================================================
# Main Pipeline Function
# ============================================================
def run_column_builder(detections_path: str, output_path: str, reference_path: Optional[str] = None, save_json: bool = True) -> None:
    print("=" * 70)
    print(" Column-Aware Line/Word Builder (SRS-Compliant, Issue #7)")
    print("=" * 70)
    
    detections = load_detections(detections_path)
    print(f"✅ Loaded {len(detections)} detections")
    
    page_width = compute_page_width(detections)
    print(f" Page width: {page_width:.0f} px | Column gap threshold: {page_width * COLUMN_GAP_RATIO:.0f} px (8%)")
    
    text, structure = reconstruct_text(detections)
    
    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text, encoding='utf-8')
    print(f"✅ Saved reconstructed text to {output_path}")
    
    if save_json:
        json_path = output.with_suffix('.json')
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(structure, f, ensure_ascii=False, indent=2)
        print(f"✅ Saved detailed structure to {json_path}")
        
    print("\n" + "=" * 70)
    print("📊 Reconstruction Summary")
    print("=" * 70)
    print(f"   Columns detected: {structure['num_columns']}")
    for col in structure['columns']:
        print(f"   Column {col['column_num']}: {col['num_lines']} lines")
    print(f"   Total characters: {len(text.replace(' ', '').replace('\\n', ''))}")
    print("=" * 70)
    
    if reference_path:
        ref = Path(reference_path)
        if ref.exists():
            reference_text = ref.read_text(encoding='utf-8')
            cer, distance, breakdown = calculate_cer(text, reference_text)
            
            print("\n" + "=" * 70)
            print(" CER Evaluation")
            print("=" * 70)
            print(f"   Reference length      : {breakdown['reference_length']} chars")
            print(f"   Reconstructed length  : {breakdown['reconstructed_length']} chars")
            print(f"   Correct characters    : {breakdown['correct']}")
            print(f"   Substitutions (S)     : {breakdown['substitutions']}")
            print(f"   Deletions (D)         : {breakdown['deletions']} (Model missed)")
            print(f"   Insertions (I)        : {breakdown['insertions']} (Model hallucinated)")
            print(f"   Total edit distance   : {distance}")
            print(f"   CER                   : {cer:.2%}")
            print("=" * 70)
            
            cer_path = output.parent / 'cer_results.json'
            with open(cer_path, 'w', encoding='utf-8') as f:
                json.dump({'cer': cer, 'distance': distance, 'breakdown': breakdown}, f, indent=2, ensure_ascii=False)
            print(f"✅ Saved CER results to {cer_path}")
        else:
            print(f"⚠️ Reference file not found: {reference_path}")

def main():
    parser = argparse.ArgumentParser(description="Column-Aware Line/Word Builder")
    parser.add_argument('--detections', type=str, required=True)
    parser.add_argument('--output', type=str, required=True)
    parser.add_argument('--reference', type=str, default=None)
    parser.add_argument('--no-json', action='store_true')
    args = parser.parse_args()
    run_column_builder(args.detections, args.output, args.reference, save_json=not args.no_json)

if __name__ == '__main__':
    main()