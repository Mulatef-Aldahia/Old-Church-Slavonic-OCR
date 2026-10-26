"""
Character Error Rate (CER) Evaluation Module
=============================================
Provides Levenshtein distance calculation and CER metrics
for OCR output evaluation against ground-truth references.

Usage:
    from evaluation.cer import calculate_cer, format_cer_report
    
    cer, distance, breakdown = calculate_cer(reconstructed_text, reference_text)
    print(format_cer_report(reconstructed_text, reference_text))
"""

from typing import Tuple


def levenshtein_distance(s1: str, s2: str) -> int:
    """Compute Levenshtein (edit) distance between two strings."""
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)
    
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            current_row.append(min(
                previous_row[j + 1] + 1,  # insertion
                current_row[j] + 1,       # deletion
                previous_row[j] + (c1 != c2) # substitution
            ))
        previous_row = current_row
    return previous_row[-1]


def calculate_cer(reconstructed: str, reference: str) -> Tuple[float, int, dict]:
    """
    Calculate Character Error Rate (CER) with detailed breakdown.
    
    Returns:
        Tuple containing:
            - cer (float): Character Error Rate as a ratio
            - distance (int): Total Levenshtein distance
            - breakdown (dict): Detailed counts of correct, substitutions, deletions, insertions
    """
    # Normalize whitespace
    recon_norm = ' '.join(reconstructed.split())
    ref_norm = ' '.join(reference.split())
    
    distance = levenshtein_distance(recon_norm, ref_norm)
    cer = distance / max(len(ref_norm), 1)
    breakdown = _compute_edit_breakdown(recon_norm, ref_norm)
    
    return cer, distance, breakdown


def _compute_edit_breakdown(reconstructed: str, reference: str) -> dict:
    """
    Compute detailed breakdown of edits from the perspective of the OCR model.
    - Deletion: Model missed a character present in reference.
    - Insertion: Model hallucinated a character not in reference.
    """
    m, n = len(reconstructed), len(reference)
    
    # Build DP table: dp[i][j] = edits to transform reconstructed[:i] to reference[:j]
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1):
        dp[i][0] = i  # Deleting all chars from reconstructed
    for j in range(n + 1):
        dp[0][j] = j  # Inserting all chars from reference
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if reconstructed[i - 1] == reference[j - 1]:
                dp[i][j] = dp[i - 1][j - 1]
            else:
                dp[i][j] = 1 + min(
                    dp[i - 1][j],      # Deletion (skip char in reconstructed)
                    dp[i][j - 1],      # Insertion (skip char in reference)
                    dp[i - 1][j - 1]   # Substitution
                )
    
    # Backtrack to count operations
    i, j = m, n
    substitutions = deletions = insertions = correct = 0
    
    while i > 0 or j > 0:
        if i > 0 and j > 0 and reconstructed[i - 1] == reference[j - 1]:
            correct += 1
            i -= 1
            j -= 1
        elif i > 0 and j > 0 and dp[i][j] == dp[i - 1][j - 1] + 1:
            substitutions += 1
            i -= 1
            j -= 1
        elif i > 0 and dp[i][j] == dp[i - 1][j] + 1:
            # Consumed a char from reconstructed but not reference -> Model hallucinated it
            insertions += 1
            i -= 1
        elif j > 0 and dp[i][j] == dp[i][j - 1] + 1:
            # Consumed a char from reference but not reconstructed -> Model missed it
            deletions += 1
            j -= 1
            
    return {
        'substitutions': substitutions,
        'deletions': deletions,         # Model missed these
        'insertions': insertions,       # Model hallucinated these
        'correct': correct,
        'reference_length': n,
        'reconstructed_length': m
    }


def format_cer_report(reconstructed: str, reference: str) -> str:
    """Generate a human-readable CER evaluation report."""
    cer, distance, breakdown = calculate_cer(reconstructed, reference)
    
    report = [
        "=" * 70,
        " CER Evaluation Report",
        "=" * 70,
        f"   Reference length      : {breakdown['reference_length']} chars",
        f"   Reconstructed length  : {breakdown['reconstructed_length']} chars",
        f"   Correct characters    : {breakdown['correct']}",
        f"   Substitutions (S)     : {breakdown['substitutions']}",
        f"   Deletions (D)         : {breakdown['deletions']} (Model missed)",
        f"   Insertions (I)        : {breakdown['insertions']} (Model hallucinated)",
        f"   Total edit distance   : {distance}",
        f"   CER                   : {cer:.2%}",
        "=" * 70,
    ]
    
    return '\n'.join(report)


# Allow direct execution for quick testing
if __name__ == '__main__':
    ref = "абвгдежзийклмнопрстуфхцчшщъыьэюя"       # 32 chars
    recon = "абвгдежзйклмнопрстуфхцчшщъыьэюя"      # 31 chars (missing 'и')
    
    print(format_cer_report(recon, ref))