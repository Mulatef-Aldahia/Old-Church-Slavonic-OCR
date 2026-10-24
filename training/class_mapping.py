"""
Class Mapping for OCS Character Detection
=========================================
Issue #2: Maps Old Church Slavonic characters to class indices (0-36).
Used by synthetic_generator.py and the training pipeline.

This is the FINAL mapping. All 37 classes are unique valid OCS characters.
"""

# ============================================================
# OCS Character List (37 unique learnable classes, indices 0-36)
# Fixed: Replaced empty strings with actual OCS characters (ѡ, ѯ)
# ============================================================
OCS_CLASS_LIST = [
    'а',  # 0
    'б',  # 1
    'в',  # 2
    'г',  # 3
    'д',  # 4
    'е',  # 5
    'ж',  # 6
    'з',  # 7
    'и',  # 8
    'і',  # 9
    'к',  # 10
    'л',  # 11
    'м',  # 12
    'н',  # 13
    'о',  # 14
    'п',  # 15
    'р',  # 16
    'с',  # 17
    'т',  # 18
    'у',  # 19
    'ф',  # 20
    'х',  # 21
    'ѡ',  # 22 (Omega - تم إصلاح الفراغ)
    'ц',  # 23
    'ч',  # 24
    'ш',  # 25
    'щ',  # 26
    'ъ',  # 27
    'ы',  # 28
    'ь',  # 29
    'ѣ',  # 30
    'ю',  # 31
    'ѧ',  # 32
    'ѯ',  # 33 (Ksi - تم إصلاح الفراغ)
    'ѱ',  # 34
    'ѳ',  # 35
    'ѵ',  # 36
]

# ============================================================
# Lookup dictionaries for fast access
# ============================================================
# التحقق من أن جميع العناصر فريدة قبل بناء القاموس
assert len(set(OCS_CLASS_LIST)) == len(OCS_CLASS_LIST), "Error: Duplicate characters in OCS_CLASS_LIST!"

CHAR_TO_ID = {char: idx for idx, char in enumerate(OCS_CLASS_LIST)}
ID_TO_CHAR = {idx: char for idx, char in enumerate(OCS_CLASS_LIST)}
NUM_CLASSES = len(OCS_CLASS_LIST)  # 37


def get_class_id(char: str) -> int:
    """Returns the class ID for a given character, or -1 if unknown."""
    return CHAR_TO_ID.get(char, -1)


def get_char(class_id: int) -> str:
    """Returns the character for a given class ID."""
    return ID_TO_CHAR.get(class_id, '?')


def validate_mapping():
    """يتحقق من أن الخريطة كاملة ومتسقة."""
    assert len(OCS_CLASS_LIST) == NUM_CLASSES
    assert len(CHAR_TO_ID) == NUM_CLASSES
    assert len(ID_TO_CHAR) == NUM_CLASSES
    
    for idx, char in enumerate(OCS_CLASS_LIST):
        assert CHAR_TO_ID[char] == idx
        assert ID_TO_CHAR[idx] == char
    
    print(f"✅ Class mapping validated: {NUM_CLASSES} unique classes (0-{NUM_CLASSES-1})")
    return True


if __name__ == '__main__':
    validate_mapping()
    print("\nFinal Class Mapping:")
    for idx, char in enumerate(OCS_CLASS_LIST):
        print(f"  {idx:2d}: '{char}'")